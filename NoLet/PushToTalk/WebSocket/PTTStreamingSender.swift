//
//  PTTStreamingSender.swift
//  NoLet
//
//  Owns the outgoing real-time audio pipeline:
//   1. Maintains one PTTWebSocketManager per active PTT server.
//   2. Turns each PCM buffer coming out of PTTRecorderManager into a
//      sequence of 20 ms Opus packets via Opus 1.0.6's OpusRealtimeEncoder.
//   3. Wraps each packet in a PTT binary frame (see PTTFrameCodec) and
//      writes it to the socket. Packets produced before the socket becomes
//      `.authenticated` are stashed in PTTLocalPacketBuffer (~2 s) and
//      flushed the moment the handshake completes.
//
//  History-message compatibility is preserved elsewhere: PTTManager keeps
//  running its existing OpusManager (Ogg) path in parallel so the on-device
//  history list, waveform, and playback continue to work unchanged.

import AVFoundation
import Defaults
import Foundation
import Opus
import os

/// Marker for one active talk session on the sender side.
private struct SenderSession {
    let id: String
    let channel: PTTChannel
    let startedAt: TimeInterval

    /// Packet counter — must match the wire seq on every AUDIO frame.
    var seq: UInt32 = 0

    /// Encoder is owned by the session; created on start, released on end.
    let encoder: OpusRealtimeEncoder

    /// Local 2 s buffer used while the socket is still handshaking.
    let localBuffer = PTTLocalPacketBuffer()
}

@MainActor
final class PTTStreamingSender {

    static let shared = PTTStreamingSender()

    // MARK: - Constants

    /// Fixed codec parameters — Opus in .voip mode at 48 kHz / 24 kbps / 20 ms.
    /// These values are echoed inside every START payload so the receiver
    /// spins up a matching decoder without needing extra negotiation.
    static let sampleRate = 48_000
    static let bitrate = 24_000
    static let frameMs = 20

    // MARK: - State

    private let log = Logger(subsystem: "app.wzs.logger", category: "PTTStreamingSender")

    /// One WS manager per server URL. Servers are addressed by the raw string
    /// so keys stay stable across `PushServerModel` re-encodings.
    private var wsByServer: [String: PTTWebSocketManager] = [:]

    /// The currently active outgoing session, or nil when the user isn't
    /// speaking. Only one at a time — matches Apple's half-duplex UX.
    private var activeSession: SenderSession?

    private init() {}

    // MARK: - Warmup

    /// Called by PTTManager after `joinConnect` succeeds so the WS can be
    /// established up-front. This is the receiver's window as well — once
    /// the socket is authenticated, START_BROADCAST / AUDIO / END_BROADCAST
    /// frames start flowing into `PTTStreamingReceiver`.
    ///
    /// Safe to call repeatedly; the underlying manager is idempotent.
    func warmup(channel: PTTChannel) {
        guard channel.serverOK, let hostURL = URL(string: channel.server.url) else {
            return
        }
        let manager = webSocket(for: hostURL)
        manager.connect(hello: buildHello(channel: channel))
    }

    /// Called when the user powers off the PTT switch.
    func teardownAll() {
        endSession(cancelled: true)
        for manager in wsByServer.values {
            manager.disconnect()
        }
    }

    /// Sends a LEAVE frame on every authenticated WS. This tells the server
    /// to remove the user from Channels and GlobalUsers (explicit "off the
    /// air" signal, distinct from a transient background disconnect). Should
    /// be called before teardownAll() — the frame is queued in the WS send
    /// buffer and will be delivered before the close handshake.
    func sendLeave() {
        let frame = PTTFrame(type: .leave, seq: 0, timestampMs: 0, payload: Data())
        for manager in wsByServer.values {
            guard manager.stateSnapshot == .authenticated else { continue }
            manager.send(frame: frame)
        }
    }

    /// Wake-up entry point for the receiver side. Ensures a WS to `host` is
    /// up (idempotent — reuses an authenticated socket if one already exists)
    /// with a HELLO that lists just the channel we were pushed for. Returns
    /// the manager so the caller can hang follow-up frames (e.g. SUBSCRIBE)
    /// off its state changes.
    func wakeupSocket(host: URL, channel: String) -> PTTWebSocketManager {
        let manager = webSocket(for: host)
        manager.connect(hello: buildMinimalHello(host: host, channels: [channel]))
        return manager
    }

    /// Fast check used by PTTManager's REST heartbeat loop to skip a redundant
    /// `/ptt/connect` when the WebSocket is already authenticated. Returns
    /// false for hosts we've never opened a socket to.
    func isAuthenticated(host: URL) -> Bool {
        guard let manager = wsByServer[host.absoluteString] else { return false }
        return manager.stateSnapshot == .authenticated
    }

    /// Sends a PRESENCE `update` frame on the socket for `channel.server`.
    /// No-ops silently when the socket isn't authenticated — the next HELLO
    /// after reconnect will resupply lat/lng anyway.
    func sendPresence(_ payload: PTTPresencePayload, for channel: PTTChannel) {
        guard channel.serverOK,
              let hostURL = URL(string: channel.server.url),
              let manager = wsByServer[hostURL.absoluteString],
              manager.stateSnapshot == .authenticated,
              let body = try? JSONEncoder().encode(payload)
        else { return }
        manager.send(frame: PTTFrame(type: .presence, seq: 0, timestampMs: 0, payload: body))
    }

    /// Minimal HELLO used by the wake-up path. Location is best-effort — if
    /// the location manager hasn't ranged yet, zeros are fine (the server
    /// only uses lat/lng for the join user list, not for auth).
    private func buildMinimalHello(host: URL, channels: [String]) -> PTTHelloPayload {
        let nickname = Defaults[.pttNickname].isEmpty
            ? String(localized: "本机")
            : Defaults[.pttNickname]
        return PTTHelloPayload(
            id: Defaults[.id],
            name: nickname,
            token: Defaults[.token].talk,
            host: host.absoluteString,
            latitude: LocManager.shared.location.coordinate.latitude,
            longitude: LocManager.shared.location.coordinate.longitude,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            channels: channels,
            proto: 1
        )
    }

    // MARK: - Session lifecycle

    /// Called by PTTManager the moment the user presses the PTT button. This
    /// establishes (or reuses) the WS connection, sends START, and returns
    /// so the recorder can start pumping PCM buffers.
    ///
    /// Returns the assigned session id; the caller stores it if needed. If
    /// the server URL is invalid or the channel is unknown, returns nil and
    /// the caller should fall back to the legacy REST upload path.
    @discardableResult
    func startSession(channel: PTTChannel) -> String? {
        guard channel.serverOK, let hostURL = URL(string: channel.server.url) else {
            log.error("cannot start session: bad server URL")
            return nil
        }

        // End any prior session that was left hanging (crash between start &
        // end, rapid double-press, …).
        if activeSession != nil {
            endSession(cancelled: true)
        }

        let encoder: OpusRealtimeEncoder
        do {
            encoder = try OpusRealtimeEncoder(
                sampleRate: Self.sampleRate,
                bitrate: Self.bitrate,
                application: .voip
            )
        } catch {
            log.error("failed to build Opus encoder: \(String(describing: error), privacy: .public)")
            return nil
        }

        let sessionID = UUID().uuidString
        activeSession = SenderSession(
            id: sessionID,
            channel: channel,
            startedAt: Date().timeIntervalSince1970,
            encoder: encoder
        )

        // Bring the WS up (idempotent) and send START immediately. If the
        // socket is still handshaking, `sendFrame` queues the frame at the
        // Starscream layer — Starscream itself does not persist writes
        // across a disconnect, so we also buffer AUDIO frames on the sender
        // side (see enqueueAudio).
        let manager = webSocket(for: hostURL)
        manager.connect(hello: buildHello(channel: channel))
        sendStartFrame(sessionID: sessionID, channel: channel, via: manager)

        log.debug("session start id=\(sessionID, privacy: .public) ch=\(channel.hex(), privacy: .public)")
        return sessionID
    }

    /// Pushes a PCM buffer through the Opus encoder and forwards each
    /// resulting packet as an AUDIO frame. Call this from the recorder's
    /// tap callback. Safe to invoke while the WS is still connecting —
    /// packets buffered locally will be replayed on `.authenticated`.
    func ingestPCM(_ buffer: AVAudioPCMBuffer) {
        guard var session = activeSession else { return }

        let packets: [Data]
        do {
            packets = try session.encoder.encode(buffer: buffer)
        } catch {
            log.error("opus encode failed: \(String(describing: error), privacy: .public)")
            return
        }
        guard !packets.isEmpty else { return }

        let manager = webSocket(for: session.channel)
        let ready = manager?.stateSnapshot == .authenticated

        for packet in packets {
            let seq = session.seq
            session.seq &+= 1
            // Timestamp is the packet's position within the session. Every
            // Opus packet emitted by OpusRealtimeEncoder covers exactly
            // `frameMs`, so seq * frameMs is the monotonic ms offset.
            let ts = UInt32(truncatingIfNeeded: UInt64(seq) * UInt64(Self.frameMs))
            let frame = PTTFrame(type: .audio, seq: seq, timestampMs: ts, payload: packet)

            if ready, let manager {
                manager.send(frame: frame)
            } else {
                session.localBuffer.append(PTTBufferedPacket(
                    seq: seq,
                    timestampMs: ts,
                    payload: packet,
                    enqueuedAt: Date().timeIntervalSince1970
                ))
            }
        }

        activeSession = session
    }

    /// Called when the user releases the PTT button (or the recorder cuts
    /// off). Sends END, flushes the encoder, and tears down the session.
    /// If `cancelled` is true the END frame is still sent so the server can
    /// clean up its bucket — the caller decides whether to persist a
    /// history record independently.
    func endSession(cancelled: Bool = false) {
        guard var session = activeSession else { return }
        activeSession = nil

        // Drain the encoder tail before sending END so downstream listeners
        // never lose the last ~10 ms.
        if let manager = webSocket(for: session.channel) {
            if let tail = try? session.encoder.finish() {
                for packet in tail {
                    let seq = session.seq
                    session.seq &+= 1
                    let ts = UInt32(truncatingIfNeeded: UInt64(seq) * UInt64(Self.frameMs))
                    let frame = PTTFrame(type: .audio, seq: seq, timestampMs: ts, payload: packet)
                    if manager.stateSnapshot == .authenticated {
                        manager.send(frame: frame)
                    } else {
                        session.localBuffer.append(PTTBufferedPacket(
                            seq: seq, timestampMs: ts, payload: packet,
                            enqueuedAt: Date().timeIntervalSince1970
                        ))
                    }
                }
            }
            sendEndFrame(sessionID: session.id,
                         durationMs: Int(session.seq) * Self.frameMs,
                         totalPackets: Int(session.seq),
                         via: manager)
        }

        // If the socket never came up before END arrives, drop whatever's in
        // the local buffer. Ring-buffer replay on the server side isn't
        // possible for a session that never had any frames delivered.
        session.localBuffer.clear()

        log.debug("session end id=\(session.id, privacy: .public) cancelled=\(cancelled) seq=\(session.seq)")
    }

    // MARK: - WebSocket lifecycle bridging

    /// Looks up (or creates) the WS manager for a given channel's server.
    private func webSocket(for channel: PTTChannel) -> PTTWebSocketManager? {
        guard let url = URL(string: channel.server.url) else { return nil }
        return webSocket(for: url)
    }

    /// Look up / create by host URL. Handshake state is remembered per host
    /// so back-to-back PTT presses reuse a warm socket.
    private func webSocket(for host: URL) -> PTTWebSocketManager {
        let key = host.absoluteString
        if let existing = wsByServer[key] { return existing }
        let manager = PTTWebSocketManager(host: host)
        manager.delegate = PTTStreamingSenderBridge.shared
        PTTStreamingSenderBridge.shared.register(manager: manager, owner: self)
        wsByServer[key] = manager
        return manager
    }

    fileprivate func onStateChanged(_ state: PTTWebSocketState, from manager: PTTWebSocketManager) {
        if state == .authenticated {
            flushLocalBufferIfAny(to: manager)
        }
    }

    private func flushLocalBufferIfAny(to manager: PTTWebSocketManager) {
        guard let session = activeSession else { return }
        let pending = session.localBuffer.drain()
        for p in pending {
            let frame = PTTFrame(type: .audio,
                                 seq: p.seq,
                                 timestampMs: p.timestampMs,
                                 payload: p.payload)
            manager.send(frame: frame)
        }
        activeSession = session
        if !pending.isEmpty {
            log.debug("flushed \(pending.count) buffered packets on socket ready")
        }
    }

    // MARK: - Frame builders

    private func buildHello(channel: PTTChannel) -> PTTHelloPayload {
        let nickname = Defaults[.pttNickname].isEmpty
            ? String(localized: "本机")
            : Defaults[.pttNickname]

        // Single-channel semantics: HELLO always advertises exactly one
        // channel — the one we're actively joining.
        return PTTHelloPayload(
            id: Defaults[.id],
            name: nickname,
            token: Defaults[.token].talk,
            host: channel.server.url,
            latitude: LocManager.shared.location.coordinate.latitude,
            longitude: LocManager.shared.location.coordinate.longitude,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            channels: [channel.hex()],
            proto: 1
        )
    }

    private func sendStartFrame(sessionID: String, channel: PTTChannel, via manager: PTTWebSocketManager) {
        struct StartPayload: Codable {
            let session_id: String
            let channel: String
            let codec: String
            let sample_rate: Int
            let frame_ms: Int
            let bitrate: Int
        }
        let payload = StartPayload(
            session_id: sessionID,
            channel: channel.hex(),
            codec: "opus",
            sample_rate: Self.sampleRate,
            frame_ms: Self.frameMs,
            bitrate: Self.bitrate
        )
        guard let body = try? JSONEncoder().encode(payload) else { return }
        manager.send(frame: PTTFrame(type: .start, seq: 0, timestampMs: 0, payload: body))
    }

    private func sendEndFrame(sessionID: String, durationMs: Int, totalPackets: Int, via manager: PTTWebSocketManager) {
        struct EndPayload: Codable {
            let session_id: String
            let duration_ms: Int
            let total_packets: Int
        }
        let payload = EndPayload(session_id: sessionID, duration_ms: durationMs, total_packets: totalPackets)
        guard let body = try? JSONEncoder().encode(payload) else { return }
        manager.send(frame: PTTFrame(type: .end, seq: 0, timestampMs: 0, payload: body))
    }
}

// MARK: - State snapshot for PTTWebSocketManager

extension PTTWebSocketManager {
    /// Read-only snapshot of the connection state, exposed for the sender's
    /// fast-path decision (send-now vs local-buffer). The `state` stored
    /// property is workQueue-only; callers of this accessor may see stale
    /// data by up to a few tens of microseconds — acceptable because a false
    /// negative just detours the packet through the local buffer for one hop.
    var stateSnapshot: PTTWebSocketState {
        // Bounce through the delegate: PTTStreamingSenderBridge keeps a
        // main-actor mirror of every state change, so reading from there is
        // trivially safe from this actor context.
        PTTStreamingSenderBridge.shared.snapshot(for: self)
    }
}

// MARK: - Bridge from PTTWebSocketManager delegate → sender

/// The sender is `@MainActor`-isolated and cannot itself be the WS delegate
/// because delegates are stored weakly. This tiny bridge holds a strong
/// reference from the WS manager side and forwards to the sender.
///
/// It also mirrors the receiver: incoming AUDIO / START_BROADCAST /
/// END_BROADCAST / REPLAY_* frames are dispatched to
/// `PTTStreamingReceiver.shared.ingest(frame:)`. That's the entry point on
/// the receive side of the pipeline.
@MainActor
final class PTTStreamingSenderBridge: PTTWebSocketManagerDelegate {
    static let shared = PTTStreamingSenderBridge()

    private var owners: [ObjectIdentifier: PTTStreamingSender] = [:]
    private var mirroredState: [ObjectIdentifier: PTTWebSocketState] = [:]

    func register(manager: PTTWebSocketManager, owner: PTTStreamingSender) {
        owners[ObjectIdentifier(manager)] = owner
        mirroredState[ObjectIdentifier(manager)] = .idle
    }

    func snapshot(for manager: PTTWebSocketManager) -> PTTWebSocketState {
        mirroredState[ObjectIdentifier(manager)] ?? .idle
    }

    // Delegate impls
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didChangeState state: PTTWebSocketState) {
        let key = ObjectIdentifier(manager)
        mirroredState[key] = state
        owners[key]?.onStateChanged(state, from: manager)
        // Receiver is a peer consumer of state changes — it uses this to
        // flush pending SUBSCRIBE frames once the socket authenticates.
        PTTStreamingReceiver.shared.socket(manager, didChangeState: state)
    }

    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveFrame frame: PTTFrame) {
        // The dispatcher is intentionally dumb about ownership: sender-only
        // frame types (HELLO_ACK, ERROR, PONG) are already consumed inside
        // PTTWebSocketManager before this delegate ever fires, so anything
        // that lands here is a receiver-facing frame.
        switch frame.type {
        case .presence:
            // PRESENCE is UI state, not audio — route to PTTManager which
            // owns the channel/user model. Fall through to the receiver as
            // well would only cause noise since the receiver ignores it.
            if let payload = try? JSONDecoder().decode(PTTPresencePayload.self, from: frame.payload) {
                PTTManager.shared.applyPresence(payload)
            }
        default:
            PTTStreamingReceiver.shared.ingest(frame: frame)
        }
    }

    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveAck ack: PTTHelloAckPayload) {
        // HELLO_ACK carries the same channel/user snapshot the legacy REST
        // /ptt/connect endpoint used to return. Feed it into PTTManager so
        // the UI (channel list, map, presence) stays populated without any
        // additional HTTP polling.
        PTTManager.shared.applyHelloAck(ack)
    }
}
