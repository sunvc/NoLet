//
//  PTTManager.swift
//  NoLet
//
//  Created by lynn on 2025/8/24.
//

import AVFoundation
import Combine
import Foundation
import GRDB
import MapKit
import Opus
import os
import PushToTalk
import SwiftUI
import UIKit

@MainActor
final class PTTManager: NSObject, ObservableObject {
    static let shared = PTTManager()

    @Published var powerState: Bool = false
    @Published var serverStatus: ServerState = .offline
    @Published var micLevel: Double = .zero
    @Published var elapsedTime: TimeInterval = 0
    @Published private(set) var state: State = .idle
    @Published var hasMicrophonePermission: Bool = false

    @Published var lastFile: AudioMessage? = nil
    @Published var waitPlayList: [AudioMessage] = []
    @Published var messages: [AudioMessage] = []

    @Published var currentPlayFile: AudioMessage? = nil

    @Published var currentPlayTime: Double = 0
    @Published var totalPlayTime: Double = 0

    // MARK: - Remote realtime stream (WebSocket receive side)

    /// True while `PTTStreamingReceiver` is playing (or has just paused for a
    /// local recording) audio from a remote speaker. UI uses this to show the
    /// "listening" affordance.
    @Published var remoteStreamActive: Bool = false

    /// Normalised RMS level (0…1) of the last decoded PCM buffer from the
    /// active remote session. Rolls back to zero when the session ends.
    @Published var remoteStreamLevel: Double = 0

    /// Seconds elapsed since the current remote broadcast started, i.e.
    /// `now - session.startedAt` on the client side. Zero when idle.
    @Published var remoteStreamElapsed: TimeInterval = 0

    /// Human-readable name of the remote speaker, from START_BROADCAST /
    /// REPLAY_BEGIN payload.
    @Published var remoteSpeakerName: String? = nil
    @Published var hasPermission: Bool = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 31.2397,
            longitude: 121.4998
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.05,
            longitudeDelta: 0.05
        )
    )

    @Published var onlineUsers: [ChannelUser] = []

    private let recorder = PTTRecorderManager()
    private let player = PTTPlayerManager()
    private let database = DatabaseManager.shared
    private nonisolated let network = NetworkManager()
    private var observationCancellable: AnyDatabaseCancellable?
    private var presenceReportTask: Task<Void, Never>?

    // MARK: - Unified audio state machine

    private var audioMachine = PTTAudioMachine()
    private var audioEventQueue: [PTTAudioEvent] = []
    private var processingAudioEvents = false
    private var recordingStopCancelled: [UUID: Bool] = [:]

    var audioState: PTTAudioState { audioMachine.state }

    /// Timestamp of the last PRESENCE update we sent, so `didUpdateLocations`
    /// bursts don't flood the socket. Guarded by MainActor isolation.
    private var lastPresenceReportAt: Date = .distantPast

    private override init() {
        super.init()
        try? AudioMessage.createInit(dbQueue: DatabaseManager.shared.dbQueue)

        Task { @MainActor in
            await self.player.setDelegate(self)
            self.recorder.delegate = self
            PTTStreamingReceiver.shared.setEventHandler { [weak self] event in
                self?.sendAudio(event)
            }
        }

        startObservingUnreadCount()
        self.startPresenceReporter()
        self.setupNotifications()
    }

    deinit {
        observationCancellable?.cancel()
        presenceReportTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationUpdated),
            name: .locationUpdated,
            object: nil
        )
    }

    @objc private func handleLocationUpdated() {
        // Location bursts (start of a new fix cycle) can fire several times in
        // a few seconds. Throttle to at most one presence broadcast every 5s
        // regardless of the source (timer or delegate callback).
        Task { @MainActor in
            self.reportOwnLocation(minInterval: 5)
        }
    }

    /// Sends a PRESENCE `update` frame with the device's current location to
    /// the server. Called from the 20 s periodic loop AND from
    /// `handleLocationUpdated`. Respects `minInterval` (seconds) to coalesce
    /// bursty callers.
    @MainActor
    func reportOwnLocation(minInterval: TimeInterval = 0) {
        let channel = Defaults[.pttChannel]
        guard powerState, channel.serverOK else { return }
        if minInterval > 0,
           Date().timeIntervalSince(lastPresenceReportAt) < minInterval {
            return
        }
        let coord = LocManager.shared.location.coordinate
        // Zero coordinates are the default seed; publishing them would clobber
        // any better location peers already have. Skip until a real fix.
        guard coord.latitude != 0 || coord.longitude != 0 else { return }

        let payload = PTTPresencePayload(
            kind: "update",
            channel: channel.hex(),
            user: PTTUserResp(
                id: Defaults[.id],
                name: Defaults[.pttNickname].isEmpty
                    ? String(localized: "本机")
                    : Defaults[.pttNickname],
                latitude: coord.latitude,
                longitude: coord.longitude,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000)
            ),
            users: nil,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        PTTStreamingSender.shared.sendPresence(payload, for: channel)
        lastPresenceReportAt = Date()
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            Task { @MainActor in
                self.sendAudio(.interruptionBegan)
            }

        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let shouldResume = options.contains(.shouldResume)
            Task { @MainActor in
                self.sendAudio(.interruptionEnded(shouldResume: shouldResume))
            }

        @unknown default:
            break
        }
    }

    /// Periodic PRESENCE update broadcaster. Replaces the old 10 s REST
    /// heartbeat — everything the server used to learn from `/ptt/connect`
    /// (my lat/lng, my token freshness) now flows through PRESENCE frames
    /// on the open WebSocket. Fires every 20 s while `powerState` is on.
    private func startPresenceReporter() {
        presenceReportTask?.cancel()
        presenceReportTask = Task.detached(priority: .utility) { [weak self] in
            logger.info("🚀 PRESENCE reporter started")
            while !Task.isCancelled {
                guard let self = self else { break }
                do {
                    let on = await self.powerState
                    if on {
                        await MainActor.run {
                            self.reportOwnLocation(minInterval: 0)
                        }
                    }
                    try await Task.sleep(for: .seconds(20))
                } catch {
                    break
                }
            }
            logger.info("🛑 PRESENCE reporter stopped")
        }
    }

    func deleteAll() {
        _ = try? DatabaseManager.shared.dbQueue.write { db in
            try AudioMessage.deleteAll(db)
            if let path = NCONFIG.getDir(.ptt) {
                try FileManager.default.removeItem(at: path)
            }
        }
    }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (
            [AudioMessage],
            [AudioMessage]
        ) in
            let messages = try AudioMessage
                .order(AudioMessage.Columns.timestamp.desc)
                .limit(50)
                .fetchAll(db)
            let unreadMessages = try AudioMessage
                .order(AudioMessage.Columns.timestamp.desc)
                .filter { !$0.read }
                .fetchAll(db)
            return (messages, unreadMessages)
        }

        observationCancellable = observation.start(
            in: database.dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                logger.error("Failed to observe unread count: \(error)")
            },
            onChange: { [weak self] newMessages, unReadMessages in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.messages = newMessages
                    self.waitPlayList = unReadMessages
                }
            }
        )
    }

    /// Compatibility adapter for the existing UI while call sites migrate to
    /// PTTAudioEvent. It performs no audio side effect itself.
    func send(_ event: Event, remote: Bool = false) async {
        switch event {
        case .startPlay(let message):
            if let message {
                sendAudio(.localPlayRequested(message))
            } else {
                sendAudio(.playNextRequested)
            }
        case .stopPlay:
            sendAudio(.stopPlaybackRequested)
        case .startRecord(let activity):
            sendAudio(.recordRequested(
                origin: .user,
                activity: activity,
                saveLocalCopy: true
            ))
        case .stopRecord(let cancelled):
            sendAudio(.recordStopRequested(cancelled: cancelled))
        case .interruptionBegan:
            sendAudio(.interruptionBegan)
        case .interruptionEnded(let shouldResume):
            sendAudio(.interruptionEnded(shouldResume: shouldResume))
        case .resume:
            sendAudio(.explicitResume)
        case .playStarted, .playFinished, .recordStarted:
            // Hardware lifecycle is now reported by tokenized delegates.
            break
        }
        _ = remote
    }

    /// Serialized mailbox for all audio transitions. Reducer state is committed
    /// before effects execute, so synchronous callbacks observe the new phase.
    func sendAudio(_ event: PTTAudioEvent) {
        audioEventQueue.append(event)
        guard !processingAudioEvents else { return }
        processingAudioEvents = true

        while !audioEventQueue.isEmpty {
            let next = audioEventQueue.removeFirst()
            let transition = PTTAudioReducer.reduce(audioMachine, event: next)
            audioMachine = transition.machine
            syncPublishedAudioState(event: next)
            for effect in transition.effects {
                runAudioEffect(effect)
            }
        }
        processingAudioEvents = false
    }

    private func runAudioEffect(_ effect: PTTAudioEffect) {
        switch effect {
        case .prepareLocal(let local):
            let s = AVAudioSession.sharedInstance()
            if s.category != .playAndRecord {
                try? s.setCategory(.playAndRecord, mode: .default,
                                  options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
            }
            try? s.setActive(true, options: .notifyOthersOnDeactivation)
            currentPlayFile = local.message
            currentPlayFile = local.message
            setStatus(message: local.message, read: true)
            setMapUserStatus(message: local.message)
            guard let url = local.message.filePath() else {
                sendAudio(.localPlaybackFailed(
                    id: local.id,
                    generation: local.generation,
                    reason: "missing local file"
                ))
                return
            }
            Task {
                await player.playAudio(url, id: local.id, generation: local.generation)
            }

        case .pauseLocal(let id):
            Task { await player.pause(id: id) }

        case .resumeLocal(let id):
            Task { await player.resume(id: id) }

        case .stopLocal(let id):
            Task { await player.stop(id: id) }
            currentPlayFile = nil
            setMapUserStatusForAllStopped()

        case .queueRemote:
            break // Receiver already owns the compressed session.

        case .activateRemote(let sessionID):
            // PushToTalk framework activates audio only for the ~1 s ring
            // window. By the time WS+SUBSCRIBE+REPLAY round-trips complete
            // the session has already been deactivated. Re-activate it now
            // so the receiver engine can actually start and produce audio.
            let s = AVAudioSession.sharedInstance()
            if s.category != .playAndRecord {
                try? s.setCategory(.playAndRecord, mode: .default,
                                  options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
            }
            try? s.setActive(true, options: .notifyOthersOnDeactivation)
            PTTStreamingReceiver.shared.activate(sessionID: sessionID)
            sendAudio(.remoteActivated(sessionID: sessionID))

        case .pauseRemote(let sessionID):
            PTTStreamingReceiver.shared.pause(sessionID: sessionID)

        case .resumeRemote(let sessionID):
            let s = AVAudioSession.sharedInstance()
            if s.category != .playAndRecord {
                try? s.setCategory(.playAndRecord, mode: .default,
                                  options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
            }
            try? s.setActive(true, options: .notifyOthersOnDeactivation)
            PTTStreamingReceiver.shared.resume(sessionID: sessionID)

        case .releaseRemote(let sessionID):
            PTTStreamingReceiver.shared.release(sessionID: sessionID)

        case .warmSender:
            PTTStreamingSender.shared.warmup(channel: Defaults[.pttChannel])

        case .startSender:
            _ = PTTStreamingSender.shared.startSession(channel: Defaults[.pttChannel])

        case .endSender(let cancelled):
            PTTStreamingSender.shared.endSession(cancelled: cancelled)

        case .startRecording(let recording):
            PTTChannelManager.shared.setActiveRemoteParticipant()
            recorder.startRecording(
                id: recording.id,
                recording.activity,
                pttMusicPlay: Defaults[.pttMusicPlay]
            )

        case .stopRecording(let recording, let cancelled):
            recordingStopCancelled[recording.id] = cancelled
            _ = recorder.stopRecording(id: recording.id)

        case .configureAudioSessionForPlayback:
            // Only needed when PushToTalk deactivates the audio session and we
            // are still playing remotely. Re-acquire the session ourselves and
            // restart the receiver engine. The FSM will see audioSessionActive
            // go false; we reconcile it with an audioSessionActivated event.
            let s = AVAudioSession.sharedInstance()
            if s.category != .playAndRecord {
                try? s.setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
                )
            }
            try? s.setActive(true, options: .notifyOthersOnDeactivation)
            PTTStreamingReceiver.shared.recoverAfterSessionLoss()
            sendAudio(.audioSessionActivated)

        case .wakeRemote(let metadata):
            PTTStreamingReceiver.shared.wakeup(
                host: metadata.host,
                channel: metadata.channel,
                sessionID: metadata.sessionID,
                from: metadata.speakerID,
                fromName: metadata.speakerName ?? ""
            )

        case .sendLeaveAndTeardown:
            PTTStreamingSender.shared.sendLeave()
            PTTStreamingSender.shared.teardownAll()
            PTTStreamingReceiver.shared.stopAll()

        case .setActiveRemoteParticipant(let enable):
            if enable {
                PTTChannelManager.shared.setActiveRemoteParticipant(name: PTTStreamingReceiver.shared.activeSpeakerName ?? remoteSpeakerName)
            } else {
                PTTChannelManager.shared.setActiveRemoteParticipant(name: nil, avatar: nil)
            }

        case .resetTelemetry:
            currentPlayTime = 0
            totalPlayTime = 0
            micLevel = 0
            elapsedTime = 0
            remoteStreamActive = false
            remoteStreamLevel = 0
            remoteStreamElapsed = 0
            remoteSpeakerName = nil
        }
    }

    private func syncPublishedAudioState(event: PTTAudioEvent) {
        switch audioMachine.state {
        case .idle:
            state = .idle
        case .preparingPlayback(let playback):
            switch playback {
            case .local(let local): state = .preparingPlay(local.message)
            case .remote: state = .idle
            }
        case .playing(let playback):
            switch playback {
            case .local(let local):
                state = .playing(local.message)
                remoteStreamActive = false
            case .remote(let remote):
                state = .idle
                remoteStreamActive = true
                remoteSpeakerName = remote.speakerName
            }
        case .preparingRecording, .recording, .finishingRecording:
            state = .recording
        case .suspended(let context):
            if case .local(let local)? = context.playback {
                state = .interrupted(local.message)
            } else {
                state = .idle
            }
        }

        switch event {
        case .localPlaybackProgress(_, _, let elapsed, let duration):
            currentPlayTime = elapsed
            totalPlayTime = duration
        case .remoteProgress(_, let elapsed, let level):
            remoteStreamElapsed = elapsed
            remoteStreamLevel = level
        case .remotePlaybackDrained, .remoteFailed:
            if audioMachine.state.remoteSessionID == nil {
                remoteStreamActive = false
                remoteStreamElapsed = 0
                remoteStreamLevel = 0
                remoteSpeakerName = nil
            }
        default:
            break
        }
    }

    private func setMapUserStatusForAllStopped() {
        for index in onlineUsers.indices { onlineUsers[index].active = false }
    }

    func joinConnect() async throws {
        // 1. 状态前置
        self.powerState = true
        self.serverStatus = .connecting

        PTTChannelManager.shared.setServerStatus(.connecting)
        // 2. ✨ 音频权限与初始化（注意：确保你的音频初始化有正确的容错）
        if !hasPermission {
            recorder.requestAudioPermission()
        }
        recorder.setupAudio()

        // 3. Bookmark the channel in the history list. Because we now enforce
        //    single-channel semantics, the history list is a plain LRU of
        //    channels the user has visited — `active` is a UI hint only.
        Defaults[.pttHisChannel].set(Defaults[.pttChannel], active: true)

        // 4. Open the WebSocket. HELLO_ACK arriving over the wire will drive
        //    the user list / server status via `applyHelloAck`; PRESENCE
        //    frames keep it in sync from there on. No REST call needed.
        PTTStreamingSender.shared.warmup(channel: Defaults[.pttChannel])

        PTTChannelManager.shared.setTransmissionMode()
        // Server status is provisional here; applyHelloAck will flip it to
        // .online / .failed once the ack arrives.
        PTTChannelManager.shared.setServerStatus(.ready)
    }

    func levelConnect() async {
        powerState = false
        serverStatus = .offline
        sendAudio(.powerOffRequested)

        var currentChannel = Defaults[.pttChannel]
        currentChannel.users = []
        Defaults[.pttChannel] = currentChannel
        onlineUsers = []

        var history = Defaults[.pttHisChannel]
        for i in history.indices { history[i].active = false }
        Defaults[.pttHisChannel] = history
    }

    /// Switches the active channel. Tears down the (possibly-warm) WebSocket
    /// for the old channel and warms up a fresh one for `channel`. Called
    /// from HistoryChannelListView when the user picks a bookmark.
    func switchChannel(to channel: PTTChannel) async {
        guard channel != Defaults[.pttChannel] else { return }

        // Reset presence bookkeeping tied to the outgoing channel.
        var outgoing = Defaults[.pttChannel]
        outgoing.users = []
        Defaults[.pttChannel] = outgoing
        self.onlineUsers = []

        // Stop every audio pipeline and explicitly leave the old channel
        // through the unified effect runner before selecting the new channel.
        sendAudio(.powerOffRequested)

        // Persist the new selection.
        Defaults[.pttChannel] = channel
        Defaults[.pttHisChannel].set(channel, active: true)

        // Only re-open if the user is powered on. Otherwise we just remember
        // the choice for the next joinConnect().
        if self.powerState {
            PTTStreamingSender.shared.warmup(channel: channel)
        }
    }

    /// Fold a HELLO_ACK's per-channel snapshot into the app's user model.
    /// Kept small compared to the old REST-driven `applyJoinResults` because
    /// PRESENCE frames now carry the ongoing deltas — this only bootstraps.
    private func applyJoinResults(_ results: [JoinResponse]) {
        var currentChannel = Defaults[.pttChannel]
        let currentKey = "\(currentChannel.server.url)_\(currentChannel.hex())"

        let resultMap = Dictionary(uniqueKeysWithValues: results.map {
            ("\($0.host)_\($0.channel)", $0)
        })

        if let matched = resultMap[currentKey] {
            var users = matched.users
            self.insertSelfIfNeeded(&users)
            currentChannel.timestamp = .now
            currentChannel.users = users
            Defaults[.pttChannel] = currentChannel

            // Mirror to the history entry so the list shows a fresh count.
            var history = Defaults[.pttHisChannel]
            if let idx = history.firstIndex(of: currentChannel) {
                history[idx].users = users
                history[idx].timestamp = .now
                Defaults[.pttHisChannel] = history
            }

            self.onlineUsers = users
            self.serverStatus = .online
        } else {
            self.serverStatus = .failed
        }

        self.zoomToFitAllUsers()
    }

    /// Called from PTTStreamingSenderBridge when a HELLO_ACK arrives. Turns
    /// the ack's per-channel snapshot into the shape `applyJoinResults`
    /// expects and drives the same UI updates that REST /ptt/connect used to.
    @MainActor
    func applyHelloAck(_ ack: PTTHelloAckPayload) {
        let results = ack.channels.map { snapshot -> JoinResponse in
            let users = snapshot.users.map { u -> ChannelUser in
                ChannelUser(
                    id: u.id,
                    name: u.name,
                    coordinate: CLLocationCoordinate2D(latitude: u.latitude, longitude: u.longitude),
                    active: false
                )
            }
            return JoinResponse(host: ack.host, channel: snapshot.channel, users: users)
        }
        self.applyJoinResults(results)
    }

    /// Server → client PRESENCE frame consumer. Routed here from
    /// `PTTStreamingSenderBridge.webSocketManager(_:didReceiveFrame:)`. Only
    /// the currently active `pttChannel` is updated in the UI; frames for
    /// other channels (which would only arrive if the server ever sends them
    /// while we're subscribed to more than one) are dropped silently to keep
    /// the single-channel invariant.
    @MainActor
    func applyPresence(_ p: PTTPresencePayload) {
        let currentChannel = Defaults[.pttChannel]
        guard currentChannel.serverOK, currentChannel.hex() == p.channel else {
            return
        }

        switch p.kind {
        case "snapshot":
            let users = (p.users ?? []).map(Self.toChannelUser)
            self.replaceOnlineUsers(with: users)

        case "join":
            guard let u = p.user else { return }
            self.upsertUser(Self.toChannelUser(u))

        case "update":
            guard let u = p.user else { return }
            self.upsertUser(Self.toChannelUser(u))

        case "leave":
            guard let u = p.user else { return }
            self.removeUser(id: u.id)

        default:
            break
        }
    }

    // MARK: - Presence helpers

    private static func toChannelUser(_ u: PTTUserResp) -> ChannelUser {
        ChannelUser(
            id: u.id,
            name: u.name,
            coordinate: CLLocationCoordinate2D(latitude: u.latitude, longitude: u.longitude),
            active: false
        )
    }

    /// Replaces the presence set with `newUsers`, then ensures "本机" (self)
    /// stays pinned at index 0 with its own live coordinate. Preserves the
    /// active-speaker flag if the same user is still in the new list.
    private func replaceOnlineUsers(with newUsers: [ChannelUser]) {
        let activeUserID = self.onlineUsers.first(where: { $0.active })?.id
        var users = newUsers
        if let idx = users.firstIndex(where: { $0.id == activeUserID }) {
            users[idx].active = true
        }
        self.insertSelfIfNeeded(&users)
        self.onlineUsers = users
        self.persistToChannel(users)
        self.zoomToFitAllUsers()
    }

    private func upsertUser(_ user: ChannelUser) {
        var users = self.onlineUsers
        // Self must not be re-added by an echoed presence — the server does
        // exclude the sender, but a `snapshot` still contains everyone.
        let userId = Defaults[.id]
        if user.id == userId {
            return
        }
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            // Preserve active-speaker flag when position updates.
            var merged = user
            merged.active = users[idx].active
            users[idx] = merged
        } else {
            users.append(user)
        }
        self.onlineUsers = users
        self.persistToChannel(users)
    }

    private func removeUser(id: String) {
        let userId = Defaults[.id]
        if id == userId { return }
        self.onlineUsers.removeAll(where: { $0.id == id })
        self.persistToChannel(self.onlineUsers)
    }

    /// Adds (or refreshes) the "本机" self-marker at index 0 of `users`.
    private func insertSelfIfNeeded(_ users: inout [ChannelUser]) {
        let userId = Defaults[.id]
        let selfName = String(localized: "本机")
        let coordinate = LocManager.shared.location.coordinate
        if let idx = users.firstIndex(where: { $0.id == userId }) {
            users[idx] = ChannelUser(
                id: userId,
                name: users[idx].name.isEmpty ? selfName : users[idx].name,
                coordinate: users[idx].coordinate,
                active: users[idx].active
            )
        } else {
            users.insert(
                ChannelUser(id: userId, name: selfName, coordinate: coordinate, active: false),
                at: 0
            )
        }
    }

    /// Writes `users` back to Defaults[.pttChannel] and the matching entry in
    /// Defaults[.pttHisChannel]. Kept small — PRESENCE fires often.
    private func persistToChannel(_ users: [ChannelUser]) {
        var current = Defaults[.pttChannel]
        current.users = users
        current.timestamp = .now
        Defaults[.pttChannel] = current

        var history = Defaults[.pttHisChannel]
        if let idx = history.firstIndex(of: current) {
            history[idx].users = users
            history[idx].timestamp = .now
            Defaults[.pttHisChannel] = history
        }
    }

    @discardableResult
    func setStatus(
        message: AudioMessage,
        read: Bool? = false,
        status: AudioMessage.Status? = nil
    ) -> Bool {
        guard read != nil || status != nil else { return false }
        return (try? DatabaseManager.shared.dbQueue.write { db in
            do {
                if var message = try AudioMessage.fetchOne(db, id: message.id) {
                    message.read = true
                    if let status {
                        message.status = status
                    }
                    try message.save(db)
                }
                return true
            } catch {
                return false
            }

        }) ?? false
    }

    func playWaitList(_ next: Bool = false) async {
        if next {
            sendAudio(.playNextRequested)
            return
        }
        guard let message = waitPlayList.last else {
            sendAudio(.stopPlaybackRequested)
            PTTChannelManager.shared.setActiveRemoteParticipant()
            return
        }
        sendAudio(.localPlayRequested(message))
    }

    // 设置谁在说话
    func setMapUserStatus(message: AudioMessage, stop: Bool = false) {
        var users = onlineUsers

        for index in users.indices {
            if stop {
                users[index].active = false
            } else {
                users[index].active = (users[index].id == message.from)
            }
            debugPrint(users[index].active)
        }

        self.onlineUsers = users
    }

    private func internalStopPlay() async {
        logger.info("Stop Play")
        await self.player.stopPlay()

        if case .interrupted = state {
            PTTChannelManager.shared.setActiveRemoteParticipant()
        }

        if self.waitPlayList.isEmpty {
            PTTChannelManager.shared.setActiveRemoteParticipant()
        }
    }

    func saveVoice(data: Data) -> AudioMessage? {
        let id = Defaults[.id]
        let channel = Defaults[.pttChannel]
        guard let filePath = channel.filePath(userID: id) else { return nil }

        do {
            try data.write(to: filePath)
            let voice = try self.database.dbQueue.write { db in
                let voice = AudioMessage(
                    channel: channel.hex(),
                    from: id,
                    file: filePath.lastPathComponent,
                    read: true
                )
                try voice.save(db)
                return voice
            }
            return voice
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }

    func setDB(_ value: Float) async {
        await self.player.setVolume(value)
    }

    func changeEQ() async {
        await self.player.changeEQ(
            bands: Defaults[.eqBands],
            globalGain: Float(Defaults[.globalGain])
        )
    }

    // MARK: - OTHER

    nonisolated func playTips(
        _ fileName: TipsSound,
        fileExtension: String = "aac",
        complete: (() -> Void)? = nil
    ) {
        guard let url = Bundle.main
            .url(forResource: fileName.rawValue, withExtension: fileExtension) else { return }

        var soundID: SystemSoundID = 0

        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    private func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }

        let channelDataValue = channelData.pointee
        // 4
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        )
        .map { channelDataValue[$0] }

        // 5
        let rms = sqrt(channelDataValueArray.map {
            $0 * $0
        }
        .reduce(0, +) / Float(buffer.frameLength))

        // 6
        let avgPower = 20 * log10(rms)
        // 7
        let meterLevel = scaledPower(power: avgPower)

        return Double(meterLevel)
    }

    private func scaledPower(power: Float) -> Float {
        // 1. 避免 NaN 或 Inf
        guard power.isFinite else {
            return 0.0
        }

        // 参考的最小分贝值（静音阈值）
        let minDb: Float = -80.0

        // 2. 小于阈值直接当作静音
        if power < minDb {
            return 0.0
        }

        // 3. 如果超过 1.0（非常大声），直接归一化到 1.0
        if power >= 1.0 {
            return 1.0
        }

        // 4. 按比例线性映射到 0~1
        return (abs(minDb) - abs(power)) / abs(minDb)
    }
}

extension PTTManager: CLLocationManagerDelegate {
    func zoomToFitAllUsers() {
        // 获取所有用户（包括当前用户自己）
        var usersToShow = Defaults[.pttChannel].users

        // 获取当前用户信息
        let userId = Defaults[.id]
        let userName = Defaults[.pttNickname]
            .isEmpty ? String(localized: "本机") : Defaults[.pttNickname]

        // 如果没有用户或列表中不包含自己，添加自己
        let hasSelf = usersToShow.contains { $0.id == userId }
        if !hasSelf {
            let userCoordinate = LocManager.shared.location.coordinate
            let selfUser = ChannelUser(
                id: userId,
                name: userName,
                coordinate: userCoordinate,
                active: false
            )
            usersToShow.insert(selfUser, at: 0)
        }

        // 过滤掉无效坐标 (0,0)
        let validUsers = usersToShow.filter { user in
            user.latitude != 0.0 && user.longitude != 0.0
        }

        guard !validUsers.isEmpty else {
            // 如果所有用户都无效，至少显示当前用户自己的位置
            let userCoordinate = LocManager.shared.location.coordinate
            withAnimation(.easeInOut(duration: 0.5)) {
                region = MKCoordinateRegion(
                    center: userCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            }
            return
        }

        let latitudes = validUsers.map(\.latitude)
        let longitudes = validUsers.map(\.longitude)

        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLng = longitudes.min(),
            let maxLng = longitudes.max()
        else {
            return
        }

        let latDelta = maxLat - minLat
        let lngDelta = maxLng - minLng

        var finalLatDelta: CLLocationDegrees
        var finalLngDelta: CLLocationDegrees

        if latDelta < 0.0005, lngDelta < 0.0005 {
            finalLatDelta = 0.0015
            finalLngDelta = 0.0015
        } else {
            finalLatDelta = max(latDelta * 1.5, 0.002)
            finalLngDelta = max(lngDelta * 1.5, 0.002)
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (minLat + maxLat) / 2,
                    longitude: (minLng + maxLng) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: finalLatDelta,
                    longitudeDelta: finalLngDelta
                )
            )
        }
    }
}

extension PTTManager {
    /// Shape mirrored by the REST `/ptt/connect` response, and reused as the
    /// intermediate form applyHelloAck folds a WebSocket ack into. Kept
    /// nested here (rather than promoted to a top-level type) because
    /// nothing outside PTTManager consumes it.
    nonisolated struct JoinResponse: Codable, Sendable {
        var host: String
        var channel: String
        var users: [ChannelUser]
    }

    func sendVoice(message: AudioMessage) async {
        // 重发机制,先重置一下状态
        self.setStatus(message: message, status: .send)

        let channel = Defaults[.pttChannel]

        guard channel.serverOK, let filePath = message.filePath() else {
            self.setStatus(message: message, status: .failed)
            return
        }

        do {
            var data = try Data(contentsOf: filePath)
            /// 加密
            let pttSignature = Defaults[.pttSignature]
            if pttSignature {
                guard let encryptedData = CryptoModelConfig.data.encrypt(inputData: data) else {
                    throw "encrypt error"
                }
                data = encryptedData
            }

            let signHeaders = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )
            let fileHeaders = [
                "X-PFA": "\(pttSignature ? "1" : "0")-\(message.file)",
            ]

            let response = try await self.network.uploadFile(
                data: data,
                url: channel.server.url,
                path: "/ptt/voice",
                headers: fileHeaders.merging(signHeaders) { current, _ in current }
            )

            let result = try JSONDecoder().decode(baseResponse<Int64>.self, from: response)

            self.setStatus(message: message, status: result.code == 200 ? .success : .failed)
        } catch {
            logger.error("\(error.localizedDescription)")
            Toast.error(title: "发送语音失败")
            self.setStatus(message: message, status: .failed)
        }
    }

}

extension PTTManager {
    // MARK: - State

    enum ServerState {
        case offline
        case connecting
        case online
        case failed
    }

    enum State: Equatable {
        case idle

        case preparingPlay(AudioMessage)
        case playing(AudioMessage)

        case recording

        case interrupted(AudioMessage)
        case interruptionEnded(Bool, AudioMessage)

        var title: String {
            switch self {
            case .idle:
                return String(localized: "空闲中")
            case .preparingPlay:
                return String(localized: "等待硬件")
            case .playing:
                return String(localized: "正在播放...")
            case .recording:
                return String(localized: "正在说话...")
            case .interrupted:
                return String(localized: "播放已打断...")
            case .interruptionEnded:
                return String(localized: "等待恢复...")
            }
        }

        var log: String {
            switch self {
            case .idle:
                return String(localized: "空闲")
            case .preparingPlay(let value):
                return String(localized: "等待播放: \(value.file)")
            case .playing(let value):
                return String(localized: "正在播放: \(value.file)")
            case .recording:
                return String(localized: "正在录音")
            case .interrupted(let value):
                return String(localized: "播放被打断挂起: \(value.file)")
            case .interruptionEnded(let resume, let value):
                return String(localized: "播放等待恢复\(String(describing: resume)): \(value.file)")
            }
        }
    }

    // MARK: - Event

    enum Event {
        case startPlay(AudioMessage?)
        case stopPlay

        case startRecord(Bool)
        case stopRecord(Bool)

        case playStarted
        case playFinished

        case recordStarted

        // 👈 新增：打断事件
        case interruptionBegan
        case interruptionEnded(shouldResume: Bool)
        case resume

        var log: String {
            switch self {
            case .startPlay(let message):
                return String(localized: "请求播放 - 消息ID: \(message?.file ?? "nil")")

            case .stopPlay:
                return String(localized: "请求停止播放")

            case .startRecord(let isActivity):
                return String(localized: "请求开始录音: 内部-\(String(describing: isActivity))")

            case .stopRecord(let isSave):
                return String(localized: "请求停止录音 (是否保存/发送: \(String(describing: isSave)))")

            case .playStarted:
                return String(localized: "底层硬件: 播放已实际开始")

            case .playFinished:
                return String(localized: "底层硬件: 播放已正常结束")

            case .recordStarted:
                return String(localized: "底层硬件: 录音已实际开始")

            case .interruptionBegan:
                return String(localized: "底层硬件: 收到音频打断开始信号")

            case .interruptionEnded(let shouldResume):
                return String(
                    localized: "底层硬件: 收到音频打断结束信号 (建议恢复: \(String(describing: shouldResume)))"
                )

            case .resume:
                return String(localized: "恢复播放")
            }
        }
    }
}

extension PTTManager {
    // MARK: - Remote realtime stream telemetry
    // Called from PTTStreamingReceiver as it drives incoming audio. Kept on
    // the manager (not the receiver) so SwiftUI views can @ObservedObject
    // the single source of truth for both local and remote playback state.

    @MainActor
    func remoteStreamBegan(speakerName: String?) {
        self.remoteStreamActive = true
        self.remoteSpeakerName = speakerName?.isEmpty == false ? speakerName : nil
        self.remoteStreamElapsed = 0
        self.remoteStreamLevel = 0
    }

    @MainActor
    func remoteStreamProgress(elapsed: TimeInterval, level: Double) {
        // Only forward while a stream is live — a late frame after
        // remoteStreamEnded shouldn't re-flip the flag.
        guard self.remoteStreamActive else { return }
        self.remoteStreamElapsed = elapsed
        self.remoteStreamLevel = level
    }

    @MainActor
    func remoteStreamEnded() {
        self.remoteStreamActive = false
        self.remoteStreamLevel = 0
        self.remoteStreamElapsed = 0
        self.remoteSpeakerName = nil
    }
}

extension PTTManager: PTTPlayerDelegate {
    nonisolated func playerManager(
        _ manager: PTTPlayerManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    ) {
        Task { @MainActor in
            guard let identity = self.audioMachine.state.localIdentity else { return }
            self.sendAudio(.localPlaybackProgress(
                id: identity.0,
                generation: identity.1,
                elapsed: currentTime,
                duration: duration
            ))
        }
    }

    nonisolated func playerManager(
        _ manager: PTTPlayerManager,
        didStart id: UUID,
        generation: UInt64,
        duration: TimeInterval
    ) {
        Task { @MainActor in
            self.totalPlayTime = duration
            self.sendAudio(.localPlaybackStarted(id: id, generation: generation))
        }
    }

    nonisolated func playerManager(
        _ manager: PTTPlayerManager,
        didFinish id: UUID,
        generation: UInt64
    ) {
        Task { @MainActor in
            self.setMapUserStatusForAllStopped()
            self.currentPlayFile = nil
            self.sendAudio(.localPlaybackFinished(id: id, generation: generation))
        }
    }

    nonisolated func playerManager(
        _ manager: PTTPlayerManager,
        didFail id: UUID,
        generation: UInt64,
        error: String
    ) {
        Task { @MainActor in
            self.sendAudio(.localPlaybackFailed(id: id, generation: generation, reason: error))
        }
    }
}

extension PTTManager: PTTRecorderDelegate {
    func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    ) {
        Task { @MainActor in
            self.micLevel = power
            self.elapsedTime = duration
        }
    }

    func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateMicrophonePermission hasPermission: Bool
    ) {
        Task { @MainActor in
            self.hasPermission = hasPermission
        }
    }

    func recorderManager(_ manager: PTTRecorderManager, didStartRecording id: UUID) {
        sendAudio(.recorderStarted(id: id))
    }

    func recorderManager(
        _ manager: PTTRecorderManager,
        recording id: UUID,
        didStopWith data: Data?
    ) {
        let cancelled = recordingStopCancelled.removeValue(forKey: id) ?? false
        if !cancelled, let data, let file = saveVoice(data: data) {
            lastFile = file
        }
        sendAudio(.recorderStopped(id: id, data: data))
    }

    func recorderManager(
        _ manager: PTTRecorderManager,
        recording id: UUID,
        didFail error: String
    ) {
        sendAudio(.recorderFailed(id: id, reason: error))
    }

    /// 采集回调的 PCM 帧 → PTTStreamingSender → OpusRealtimeEncoder → WS。
    /// 仅当前 FSM recording id 有效时才接受 PCM；过期 tap 回调直接丢弃。
    func recorderManager(
        _ manager: PTTRecorderManager,
        didCaptureBuffer buffer: AVAudioPCMBuffer
    ) {
        Task { @MainActor in
            guard self.audioMachine.state.recordingContext != nil else { return }
            PTTStreamingSender.shared.ingestPCM(buffer)
        }
    }
}

nonisolated extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
