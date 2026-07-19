//
//  PTTStreamingReceiver.swift
//  NoLet
//
//  Incoming realtime PTT pipeline. Network input and audible playback are
//  deliberately separate: every session stores Opus packets while queued or
//  paused, and only the unified audio FSM may activate/pause/release playback.
//

import Accelerate
import AVFoundation
import Defaults
import Foundation
import Opus
import os

@MainActor
final class PTTStreamingReceiver {
    static let shared = PTTStreamingReceiver()

    private let log = Logger(subsystem: "app.wzs.logger", category: "PTTStreamingReceiver")

    // MARK: - Types

    private enum PlaybackMode: Equatable {
        case queued
        case active
        case paused
        case draining
        case finished
    }

    private final class ReceiveSession {
        let id: String
        let channel: String
        let from: String
        let fromName: String
        let startedAt: Int64
        let sampleRate: Int
        let frameMs: Int
        let decoder: OpusRealtimeDecoder
        let jitter: PTTJitterBuffer
        let outputFormat: AVAudioFormat

        var mode: PlaybackMode = .queued
        var isReplaying = false
        var awaitingLivePacket = false
        var liveStartSeq: UInt32?
        var endReceived = false
        var inputEndReported = false
        var drainReported = false
        var consecutivePLC = 0
        var scheduledBufferCount = 0
        var renderedPackets: UInt64 = 0
        var sequenceStarted = false
        var initialAudioFrames: [PTTFrame] = []
        /// Wall time of the last AUDIO frame ingested for this session.
        /// Used to detect silent disconnect / dropped END.
        var lastAudioAt: TimeInterval = 0

        init(
            id: String,
            channel: String,
            from: String,
            fromName: String,
            startedAt: Int64,
            sampleRate: Int,
            frameMs: Int,
            decoder: OpusRealtimeDecoder,
            jitter: PTTJitterBuffer,
            outputFormat: AVAudioFormat
        ) {
            self.id = id
            self.channel = channel
            self.from = from
            self.fromName = fromName
            self.startedAt = startedAt
            self.sampleRate = sampleRate
            self.frameMs = frameMs
            self.decoder = decoder
            self.jitter = jitter
            self.outputFormat = outputFormat
        }

        var context: PTTRemotePlaybackContext {
            PTTRemotePlaybackContext(
                sessionID: id,
                channel: channel,
                speakerID: from,
                speakerName: fromName
            )
        }
    }

    private struct StartBroadcast: Decodable {
        let session_id: String
        let channel: String
        let from: String
        let from_name: String
        let started_at: Int64
        let codec: String
        let sample_rate: Int
        let frame_ms: Int
    }

    private struct EndBroadcast: Decodable {
        let session_id: String
        let channel: String
        let from: String
        let duration_ms: Int
        let total_packets: Int
    }

    // MARK: - Constants

    /// 60 seconds at 20 ms per Opus frame. This bounds compressed backlog
    /// while recording without retaining decoded PCM or unbounded node buffers.
    private static let maxBacklogPackets = 3_000
    private static let prerollDepth = 3
    private static let maxScheduledBuffers = 8       // ~160 ms at 20 ms/frame
    private static let plcGiveUpLimit = 25           // ~500 ms
    private static let drainIntervalMs = 20
    /// If no new audio frame arrives for this long while the session is active
    /// and the jitter is empty, treat it as an implicit end-of-stream (sender
    /// crashed, WS disconnected, etc.) so the FSM can transition back to idle.
    private static let silenceGraceSeconds: Double = 3

    // MARK: - State

    var isPlaying: Bool { engineConfigured && playerNode.isPlaying }

    /// HACK: return speaker name for the currently active session directly,
    /// so callers don't have to wait for the FSM round-trip.
    var activeSpeakerName: String? {
        guard let id = activeSessionID, let s = sessions[id] else { return nil }
        return s.fromName.isEmpty ? nil : s.fromName
    }

    private struct BufferedAudioFrame {
        let frame: PTTFrame
        let receivedAt: TimeInterval
    }

    /// AUDIO carries no session id. During APNs wake-up it can arrive before
    /// START_BROADCAST / REPLAY_BEGIN has created the receive session. Keep a
    /// small ordered backlog and attach recent packets to the next session.
    private static let maxOrphanAudioPackets = 250
    private static let orphanAudioMaxAge: TimeInterval = 2
    private var orphanAudioFrames: [BufferedAudioFrame] = []

    private var sessions: [String: ReceiveSession] = [:]
    private var sessionOrder: [String] = []
    private var activeSessionID: String?

    /// All receiver lifecycle/progress changes go through this handler. It is
    /// installed by PTTManager and feeds the unified audio mailbox.
    private var eventHandler: (@MainActor (PTTAudioEvent) -> Void)?

    /// Push restoration can deliver START_BROADCAST before PTTManager's init
    /// has installed its handler. Keep lifecycle events until the coordinator
    /// is ready instead of silently losing remoteStreamBegan and leaving the
    /// session stuck in `.queued` forever.
    private var pendingEvents: [PTTAudioEvent] = []

    private var pendingSubscribes: [ObjectIdentifier: (manager: PTTWebSocketManager, sessionID: String)] = [:]

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var engineFormat: AVAudioFormat?
    private var engineConfigured = false
    private var pcmConverter: AVAudioConverter?
    private var pcmConverterSourceFormat: AVAudioFormat?
    private var drainTimer: DispatchSourceTimer?

    private init() {}

    func setEventHandler(_ handler: @escaping @MainActor (PTTAudioEvent) -> Void) {
        eventHandler = handler
        let buffered = pendingEvents
        pendingEvents.removeAll(keepingCapacity: true)
        for event in buffered {
            handler(event)
        }
    }

    private func emit(_ event: PTTAudioEvent) {
        if let eventHandler {
            eventHandler(event)
        } else {
            pendingEvents.append(event)
        }
    }

    // MARK: - Wake-up path

    func wakeup(host: String, channel: String, sessionID: String, from: String, fromName: String) {
        guard !sessionID.isEmpty, !channel.isEmpty, let hostURL = URL(string: host) else {
            log.error("wakeup: bad args host=\(host, privacy: .public) ch=\(channel, privacy: .public)")
            return
        }
        let manager = PTTStreamingSender.shared.wakeupSocket(host: hostURL, channel: channel)
        let key = ObjectIdentifier(manager)
        pendingSubscribes[key] = (manager, sessionID)
        if manager.stateSnapshot == .authenticated {
            flushPendingSubscribe(for: manager)
        }
    }

    func socket(_ manager: PTTWebSocketManager, didChangeState state: PTTWebSocketState) {
        guard state == .authenticated else { return }
        flushPendingSubscribe(for: manager)
    }

    private func flushPendingSubscribe(for manager: PTTWebSocketManager) {
        let key = ObjectIdentifier(manager)
        guard let pending = pendingSubscribes.removeValue(forKey: key) else { return }
        struct SubscribePayload: Encodable { let session_id: String }
        guard let body = try? JSONEncoder().encode(SubscribePayload(session_id: pending.sessionID)) else {
            return
        }
        manager.send(frame: PTTFrame(type: .subscribe, seq: 0, timestampMs: 0, payload: body))
    }

    // MARK: - Network input

    func ingest(frame: PTTFrame) {
        switch frame.type {
        case .startBroadcast: handleStartBroadcast(frame)
        case .audio:          handleAudioFrame(frame)
        case .endBroadcast:   handleEndBroadcast(frame)
        case .replayBegin:    handleReplayBegin(frame)
        case .replayEnd:      handleReplayEnd(frame)
        default:              break
        }
    }

    private func handleStartBroadcast(_ frame: PTTFrame) {
        guard let payload = try? JSONDecoder().decode(StartBroadcast.self, from: frame.payload) else {
            log.error("bad START_BROADCAST payload")
            return
        }
        guard payload.from != Defaults[.id], sessions[payload.session_id] == nil else { return }

        do {
            let decoder = try OpusRealtimeDecoder(sampleRate: payload.sample_rate)
            let jitter = PTTJitterBuffer(maxDepth: Self.maxBacklogPackets)
            let session = ReceiveSession(
                id: payload.session_id,
                channel: payload.channel,
                from: payload.from,
                fromName: payload.from_name,
                startedAt: payload.started_at,
                sampleRate: payload.sample_rate,
                frameMs: max(payload.frame_ms, 20),
                decoder: decoder,
                jitter: jitter,
                outputFormat: decoder.outputFormat
            )
            sessions[session.id] = session
            sessionOrder.append(session.id)
            log.debug("session begin id=\(payload.session_id, privacy: .public) from=\(payload.from, privacy: .public)")
            drainOrphanAudio(into: session)
            emit(.remoteStreamBegan(session.context))
        } catch {
            emit(.remoteFailed(sessionID: payload.session_id, reason: error.localizedDescription))
        }
    }

    private func handleAudioFrame(_ frame: PTTFrame) {
        // Server guarantees one active talker per channel. AUDIO has no
        // session id, so bind it to the latest non-ended session. During
        // APNs wake-up AUDIO may race ahead of START_BROADCAST; preserve it
        // until the control frame creates the session.
        guard let session = latestInputSession() else {
            let now = Date().timeIntervalSince1970
            orphanAudioFrames.removeAll { now - $0.receivedAt > Self.orphanAudioMaxAge }
            orphanAudioFrames.append(.init(frame: frame, receivedAt: now))
            if orphanAudioFrames.count > Self.maxOrphanAudioPackets {
                orphanAudioFrames.removeFirst(orphanAudioFrames.count - Self.maxOrphanAudioPackets)
            }
            log.debug("buffered AUDIO seq=\(frame.seq) — waiting for input session")
            return
        }
        ingestAudioFrame(frame, into: session)
    }

    private func ingestAudioFrame(_ frame: PTTFrame, into session: ReceiveSession) {
        session.lastAudioAt = Date().timeIntervalSince1970
        if !session.sequenceStarted {
            session.initialAudioFrames.append(frame)
            if session.initialAudioFrames.count > Self.maxOrphanAudioPackets {
                session.initialAudioFrames.removeFirst(
                    session.initialAudioFrames.count - Self.maxOrphanAudioPackets
                )
            }
            // Wait for a few frames before choosing the initial cursor. During
            // APNs replay, a live high-seq packet can arrive before the replay
            // head; selecting the first arrival would make those replay packets
            // look expired. The minimum of this small batch is the safe start.
            guard session.initialAudioFrames.count >= Self.prerollDepth || session.endReceived else {
                return
            }
            startSequenceIfNeeded(session)
            return
        }
        insertAudioFrame(frame, into: session)
    }

    private func startSequenceIfNeeded(_ session: ReceiveSession) {
        guard !session.sequenceStarted, !session.initialAudioFrames.isEmpty else { return }
        let buffered = session.initialAudioFrames.sorted { lhs, rhs in
            if lhs.seq == rhs.seq { return lhs.timestampMs < rhs.timestampMs }
            return lhs.seq < rhs.seq
        }
        session.initialAudioFrames.removeAll(keepingCapacity: true)
        session.jitter.reset(startingSeq: buffered[0].seq)
        session.sequenceStarted = true
        log.debug("session id=\(session.id, privacy: .public) starts at seq=\(buffered[0].seq)")
        for frame in buffered {
            insertAudioFrame(frame, into: session)
        }
    }

    private func insertAudioFrame(_ frame: PTTFrame, into session: ReceiveSession) {
        if session.awaitingLivePacket {
            session.awaitingLivePacket = false
            session.liveStartSeq = frame.seq
            log.debug("session id=\(session.id, privacy: .public) live stream starts at seq=\(frame.seq)")
        }
        let accepted = session.jitter.insert(seq: frame.seq, payload: frame.payload)
        if !accepted {
            log.debug("dropped duplicate/expired AUDIO seq=\(frame.seq)")
        }
        if session.mode == .active || session.mode == .draining {
            fillScheduledLead(session)
        }
    }

    private func drainOrphanAudio(into session: ReceiveSession) {
        guard !orphanAudioFrames.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let buffered = orphanAudioFrames
            .filter { now - $0.receivedAt <= Self.orphanAudioMaxAge }
            .sorted { lhs, rhs in
                if lhs.frame.seq == rhs.frame.seq { return lhs.frame.timestampMs < rhs.frame.timestampMs }
                return lhs.frame.seq < rhs.frame.seq
            }
        orphanAudioFrames.removeAll(keepingCapacity: true)
        guard !buffered.isEmpty else { return }
        log.debug("attaching \(buffered.count) early AUDIO packets to id=\(session.id, privacy: .public)")
        // Do not choose the jitter cursor from orphan packets alone. A live
        // high-seq packet may have raced ahead of the replay head. Keep these
        // as initial candidates; the first post-session AUDIO frame completes
        // the batch and startSequenceIfNeeded chooses the minimum seq.
        session.lastAudioAt = now
        session.initialAudioFrames.append(contentsOf: buffered.map(\.frame))
        if session.initialAudioFrames.count > Self.maxOrphanAudioPackets {
            session.initialAudioFrames.removeFirst(
                session.initialAudioFrames.count - Self.maxOrphanAudioPackets
            )
        }
    }

    private func handleEndBroadcast(_ frame: PTTFrame) {
        guard let payload = try? JSONDecoder().decode(EndBroadcast.self, from: frame.payload),
              let session = sessions[payload.session_id] else { return }
        session.endReceived = true
        // A very short transmission can end before the initial pre-roll reaches
        // three packets. Commit whatever was received before marking EOS so it
        // can still play and drain normally.
        startSequenceIfNeeded(session)
        session.jitter.markEndOfStream()
        if !session.inputEndReported {
            session.inputEndReported = true
            emit(.remoteInputEnded(sessionID: session.id))
        }
        if session.mode == .active {
            session.mode = .draining
            fillScheduledLead(session)
        }
        reportDrainedIfReady(session)
    }

    private func handleReplayBegin(_ frame: PTTFrame) {
        guard let payload = try? JSONDecoder().decode(StartBroadcast.self, from: frame.payload) else { return }
        if sessions[payload.session_id] == nil {
            handleStartBroadcast(frame)
        }
        sessions[payload.session_id]?.isReplaying = true
    }

    private func handleReplayEnd(_ frame: PTTFrame) {
        struct ReplayEndPayload: Decodable { let session_id: String }
        guard let payload = try? JSONDecoder().decode(ReplayEndPayload.self, from: frame.payload) else { return }
        guard let session = sessions[payload.session_id] else { return }
        session.isReplaying = false
        // The next AUDIO is the live stream head. If live packets already
        // raced ahead of REPLAY_END, fillScheduledLead derives the head from
        // the lowest buffered sequence once the replay tail is consumed.
        session.awaitingLivePacket = true
    }

    // MARK: - FSM-controlled playback effects

    func activate(sessionID: String) {
        guard let session = sessions[sessionID], session.mode != .finished else { return }
        activeSessionID = sessionID
        activeScheduledSinceStart = false
        session.mode = session.endReceived ? .draining : .active
        configureEngineIfNeeded(with: session.outputFormat)
        if engineConfigured {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                if !engine.isRunning {
                    try engine.start()
                }
                if !playerNode.isPlaying {
                    playerNode.play()
                }
            } catch {
                log.error("activate: playback restart failed: \(String(describing: error), privacy: .public)")
            }
        }
        log.debug("activate session=\(sessionID, privacy: .public) mode=\(session.mode == .draining ? "draining" : "active", privacy: .public) engineConfigured=\(self.engineConfigured) isPlaying=\(self.playerNode.isPlaying)")
        fillScheduledLead(session)
    }

    func pause(sessionID: String) {
        guard let session = sessions[sessionID], session.mode != .finished else { return }
        session.mode = .paused
        if activeSessionID == sessionID, playerNode.isPlaying {
            playerNode.pause()
        }
    }

    func resume(sessionID: String) {
        guard let session = sessions[sessionID], session.mode == .paused else { return }
        activeSessionID = sessionID
        session.mode = session.endReceived ? .draining : .active
        configureEngineIfNeeded(with: session.outputFormat)
        if engineConfigured {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                if !engine.isRunning {
                    try engine.start()
                }
                if !playerNode.isPlaying {
                    playerNode.play()
                }
            } catch {
                log.error("resume: playback restart failed: \(String(describing: error), privacy: .public)")
            }
        }
        fillScheduledLead(session)
    }

    func release(sessionID: String) {
        guard let session = sessions.removeValue(forKey: sessionID) else { return }
        session.mode = .finished
        sessionOrder.removeAll { $0 == sessionID }
        if activeSessionID == sessionID {
            activeSessionID = nil
            // Drained sessions have zero scheduled buffers. Failure/stop paths
            // may not; stop flushes those callbacks after their identity was removed.
            playerNode.stop()
        }
        stopDrainTimerIfIdle()
    }

    /// Called after the PushToTalk framework deactivates the audio session and
    /// we re-acquire it via configureAudioSessionForPlayback. The engine / player
    /// node may still report `.isPlaying == true` even though the hardware
    /// output route was severed, so we unconditionally stop + restart to force
    /// AVFoundation to re-establish the audio pipeline. Already-scheduled buffers
    /// are lost; fillScheduledLead re-schedules fresh ones from the jitter.
    func recoverAfterSessionLoss() {
        guard let id = activeSessionID,
              let session = sessions[id],
              session.mode == .active || session.mode == .draining,
              engineConfigured else { return }
        log.debug("recover: restarting engine for id=\(id, privacy: .public)")
        playerNode.stop()
        engine.stop()
        do {
            try engine.start()
            playerNode.play()
        } catch {
            log.error("recover: engine restart failed: \(String(describing: error), privacy: .public)")
            return
        }
        // Reset the scheduling counter so the pre-roll gate won't starve us.
        activeScheduledSinceStart = true
        session.scheduledBufferCount = 0
        fillScheduledLead(session)
        startDrainTimerIfNeeded()
    }

    func stopAll() {
        sessions.removeAll()
        sessionOrder.removeAll()
        activeSessionID = nil
        drainTimer?.cancel()
        drainTimer = nil
        playerNode.stop()
        engine.stop()
        engine.reset()
        engineConfigured = false
        engineFormat = nil
        pcmConverter = nil
        pcmConverterSourceFormat = nil
    }

    // Compatibility wrappers while old call sites are removed.
    func pauseForRecording() {
        if let id = activeSessionID { pause(sessionID: id) }
    }

    func resumePlayback() {
        if let id = activeSessionID { resume(sessionID: id) }
    }

    // MARK: - Engine setup

    private func prepareAudioSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        if session.category != .playAndRecord {
            do {
                try session.setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
                )
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                log.error("session setCategory failed: \(String(describing: error), privacy: .public)")
            }
        }
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            log.error("session setActive failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func configureEngineIfNeeded(with format: AVAudioFormat) {
        guard let mixerFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: format.sampleRate,
            channels: format.channelCount,
            interleaved: false
        ) else { return }

        if engineConfigured, engineFormat == mixerFormat { return }
        prepareAudioSessionForPlayback()
        if engineConfigured {
            engine.stop()
            engine.reset()
            playerNode.reset()
            engine.detach(playerNode)
            engineConfigured = false
        }

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: mixerFormat)
        do {
            try engine.start()
            engineFormat = mixerFormat
            engineConfigured = true
            pcmConverter = nil
            pcmConverterSourceFormat = nil
        } catch {
            log.error("engine start failed: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Bounded decode/schedule loop

    /// Tracks how many buffers have been scheduled for the active session,
    /// regardless of the session's replay state. Once this crosses 1, the
    /// pre-roll gate in fillScheduledLead stays open so replay → live handoff
    /// never re-enters a waiting state.
    private var activeScheduledSinceStart = false

    private func startDrainTimerIfNeeded() {
        guard drainTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .milliseconds(Self.drainIntervalMs),
                       repeating: .milliseconds(Self.drainIntervalMs))
        timer.setEventHandler { [weak self] in
            guard let self,
                  let id = self.activeSessionID,
                  let session = self.sessions[id],
                  session.mode == .active || session.mode == .draining else { return }
            self.fillScheduledLead(session)
        }
        timer.resume()
        drainTimer = timer
    }

    private func stopDrainTimerIfIdle() {
        guard activeSessionID == nil else { return }
        drainTimer?.cancel()
        drainTimer = nil
    }

    private func fillScheduledLead(_ session: ReceiveSession) {
        guard session.id == activeSessionID,
              session.mode == .active || session.mode == .draining,
              engineConfigured else { return }

        // PushToTalk framework may pause the player node when the app
        // transitions to the background. Re-acquire the audio session before
        // restarting the engine and player node.
        if !playerNode.isPlaying || !engine.isRunning {
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                if !engine.isRunning {
                    try engine.start()
                }
                if !playerNode.isPlaying {
                    playerNode.play()
                }
            } catch {
                log.debug("fillScheduledLead: playback restart failed: \(String(describing: error), privacy: .public)")
                return
            }
        }

        // Pre-roll gate: only enforce the minimum fill before any buffer has
        // been scheduled for the active session. Once at least one batch
        // reaches the player node, the lower water-mark drops to 0 — we
        // decode whatever packets are available right now and pause only
        // when scheduledBufferCount hits the capacity ceiling. This
        // prevents the gate from re-entering the waiting state after the
        // replay range (seq 0..N) is exhausted but before live packets
        // (seq N+1..) are received.
        if !activeScheduledSinceStart,
           !session.endReceived,
           session.jitter.pendingCount < Self.prerollDepth {
            log.debug("fillScheduledLead: pre-roll waiting for \(Self.prerollDepth) packets, have \(session.jitter.pendingCount)")
            return
        }

        let before = session.scheduledBufferCount
        // If the sender has been silent for longer than the grace period and
        // we never received an END_BROADCAST (likely WS disconnect), force a
        // clean drain so the FSM can return to idle.
        if !session.endReceived,
           session.lastAudioAt > 0,
           session.jitter.pendingCount == 0,
           session.scheduledBufferCount == 0,
           Date().timeIntervalSince1970 - session.lastAudioAt > Self.silenceGraceSeconds {
            log.warning("fillScheduledLead: silence timeout for id=\(session.id, privacy: .public), forcing end")
            session.endReceived = true
            session.mode = .draining
            session.jitter.markEndOfStream()
            reportDrainedIfReady(session)
            return
        }
        while session.scheduledBufferCount < Self.maxScheduledBuffers {
            switch session.jitter.drainNext(treatAsLost: false) {
            case .packet(let packet):
                session.consecutivePLC = 0
                do {
                    let pcm = try session.decoder.decode(packet: packet)
                    guard scheduleBuffer(pcm, session: session) else { return }
                } catch {
                    emit(.remoteFailed(sessionID: session.id, reason: error.localizedDescription))
                    return
                }

            case .waitingForSeq:
                // At the replay → live handoff the jitter cursor is at the
                // end of the replay ring while live packets have seq N+1+.
                // Advance directly to the live head instead of burning 25
                // PLC frames that would fail the decoder.
                if let liveStart = session.liveStartSeq,
                   session.jitter.nextSeq <= liveStart,
                   session.jitter.minimumPendingSeq ?? liveStart >= liveStart {
                    log.debug("fill: jumping from seq=\(session.jitter.nextSeq) to live seq=\(liveStart)")
                    session.jitter.advance(to: liveStart)
                    session.liveStartSeq = nil
                    continue
                }
                if session.endReceived || session.jitter.pendingCount >= Self.prerollDepth {
                    _ = session.jitter.drainNext(treatAsLost: true)
                    session.consecutivePLC += 1
                    if session.consecutivePLC > Self.plcGiveUpLimit {
                        emit(.remoteFailed(sessionID: session.id, reason: "too many missing packets"))
                        return
                    }
                    do {
                        let pcm = try session.decoder.decodeMissingPacket(
                            frameDurationMs: session.frameMs,
                            decodeFEC: true
                        )
                        guard scheduleBuffer(pcm, session: session) else { return }
                    } catch {
                        return
                    }
                } else {
                    return
                }

            case .exhausted:
                log.debug("fill: jitter exhausted, reporting drained")
                reportDrainedIfReady(session)
                return
            case .lost:
                log.debug("fill: lost packet, continuing")
                continue
            }
        }
        if before != session.scheduledBufferCount {
            log.debug("fillScheduledLead: scheduled \(session.scheduledBufferCount - before) buffers for id=\(session.id)")
        }
    }

    @discardableResult
    private func scheduleBuffer(_ buffer: AVAudioPCMBuffer, session: ReceiveSession) -> Bool {
        guard let targetFormat = engineFormat else { return false }
        if pcmConverter == nil || pcmConverterSourceFormat != buffer.format {
            pcmConverter = AVAudioConverter(from: buffer.format, to: targetFormat)
            pcmConverterSourceFormat = buffer.format
        }
        guard let converter = pcmConverter,
              let output = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: max(buffer.frameLength, 1)
              ) else { return false }

        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        guard error == nil else { return false }

        let level = Self.calculateLevelPercentage(from: output)
        activeScheduledSinceStart = true
        session.scheduledBufferCount += 1
        log.debug("schedule seq=\(session.jitter.nextSeq > 0 ? "\(session.jitter.nextSeq-1)" : "?") id=\(session.id) count=\(session.scheduledBufferCount)")
        playerNode.scheduleBuffer(
            output,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            Task { @MainActor in
                self?.bufferDidPlay(sessionID: session.id, level: level)
            }
        }
        return true
    }

    private func bufferDidPlay(sessionID: String, level: Double) {
        guard let session = sessions[sessionID], session.mode != .finished else { return }
        session.scheduledBufferCount = max(session.scheduledBufferCount - 1, 0)
        session.renderedPackets &+= 1
        let elapsed = Double(session.renderedPackets) * Double(session.frameMs) / 1_000
        emit(.remoteProgress(sessionID: sessionID, elapsed: elapsed, level: level))
        log.debug("bufferDidPlay id=\(session.id) remaining=\(session.scheduledBufferCount) mode=\(session.mode == .draining ? "draining" : "active")")
        fillScheduledLead(session)
        if session.mode == .draining {
            reportDrainedIfReady(session)
        }
    }

    private func reportDrainedIfReady(_ session: ReceiveSession) {
        guard session.endReceived,
              session.jitter.pendingCount == 0,
              session.scheduledBufferCount == 0,
              !session.drainReported else { return }
        session.drainReported = true
        // Do not tear down the remote playback engine here — it belongs to
        // the FSM. Only fire the lifecycle event so the reducer can select
        // the next queued playback. releaseRemote drives stopDrainTimer +
        // playerNode cleanup lazily only when another remote session takes
        // over or the FSM goes to idle.
        emit(.remotePlaybackDrained(sessionID: session.id))
    }

    @inline(__always)
    private static func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Double {
        guard let samples = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(frameLength))
        guard rms > 0 else { return 0 }
        let decibels = 20 * log10f(rms)
        let minDb: Float = -80
        if decibels <= minDb { return 0 }
        let normalized = (decibels - minDb) * 0.0125
        return Double(normalized * sqrtf(normalized))
    }

    // MARK: - Helpers

    private func latestInputSession() -> ReceiveSession? {
        for id in sessionOrder.reversed() {
            if let session = sessions[id], !session.endReceived, session.mode != .finished {
                return session
            }
        }
        return nil
    }
}
