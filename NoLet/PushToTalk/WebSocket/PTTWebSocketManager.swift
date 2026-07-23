//
//  PTTWebSocketManager.swift
//  NoLet
//
//  Starscream-based WebSocket client for the real-time PTT channel.
//  Handles connection lifecycle, HELLO handshake, keepalive, and reconnection.
//  The frame protocol lives in `PTTFrameCodec.swift`.
//
//  Concurrency model:
//   * The class is `@unchecked Sendable` (not actor-isolated).
//   * All mutable state is serialised through `workQueue`; callers can invoke
//     the public API from any thread and it is bounced onto that queue.
//   * The delegate protocol is `@MainActor` — delegate methods are always
//     called on the main actor via `Task { @MainActor in ... }`.

@preconcurrency import Starscream
import Foundation
import os

/// High-level connection state exposed to the rest of the app.
nonisolated enum PTTWebSocketState: Equatable, Sendable {
    case idle           // not connecting
    case connecting     // TCP + TLS + WS upgrade in progress
    case connected      // WS open, HELLO not yet acknowledged
    case authenticated  // HELLO_ACK received; ready for START/AUDIO/END
    case closing        // graceful teardown initiated
    case failed(String) // last error message
}

/// Delegate for sender / receiver layers. All methods are called on the main
/// actor so UI-adjacent consumers don't need to hop threads themselves.
@MainActor
protocol PTTWebSocketManagerDelegate: AnyObject {
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didChangeState state: PTTWebSocketState)
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveFrame frame: PTTFrame)
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveAck ack: PTTHelloAckPayload)
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveError error: PTTErrorPayload)
}

extension PTTWebSocketManagerDelegate {
    // Sensible defaults so consumers can opt into subsets.
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveAck ack: PTTHelloAckPayload) {}
    func webSocketManager(_ manager: PTTWebSocketManager,
                          didReceiveError error: PTTErrorPayload) {}
}

/// Owns a single Starscream connection to a given server host. One instance
/// per active PTT server is enough — different servers spawn different
/// managers coordinated by `PTTManager`.
///
/// Explicitly `nonisolated` — the project builds with "default actor isolation
/// = MainActor", but this class serialises its own state through `workQueue`
/// and must NOT be inferred onto the main actor. Only `delegate` opts back
/// into `@MainActor` to match the delegate protocol.
nonisolated final class PTTWebSocketManager: @unchecked Sendable {

    // MARK: - Configuration

    /// Interval between application-level pings (WS `Ping` control frames).
    static let heartbeatInterval: TimeInterval = 15

    /// Peer is considered dead if we haven't received any traffic in this window.
    static let readTimeout: TimeInterval = 60

    /// Exponential backoff schedule for reconnection attempts.
    private static let reconnectDelays: [TimeInterval] = [1, 2, 5, 10, 30]

    // MARK: - Immutable state

    private let host: URL
    private let workQueue = DispatchQueue(label: "app.wzs.ptt.ws")
    private let log = Logger(subsystem: "app.wzs.logger", category: "PTTWebSocket")

    // MARK: - Mutable state (workQueue-only unless noted)

    private var socket: WebSocket?
    private var heartbeatTimer: DispatchSourceTimer?
    private var lastActivity: TimeInterval = 0
    private var reconnectAttempt = 0
    private var pendingHello: PTTHelloPayload?
    private var manuallyDisconnected = false
    private var _state: PTTWebSocketState = .idle

    /// Delegate storage is main-actor isolated to match the protocol. Read /
    /// write must happen on the main actor; the manager hops there internally
    /// whenever it needs to invoke a delegate method.
    @MainActor weak var delegate: PTTWebSocketManagerDelegate?

    // MARK: - Init

    /// - Parameter host: the server URL, e.g. `https://api.example.com`. The
    ///   WS path `/ptt/ws` is appended automatically and the scheme upgraded
    ///   to `ws` / `wss`.
    init(host: URL) {
        self.host = host
    }

    // No custom deinit: Starscream's WebSocket + DispatchSourceTimer both
    // release cleanly when their owner disappears. Non-Sendable state cannot
    // be touched from a nonisolated deinit under Swift 6 strict concurrency,
    // so callers that need explicit teardown should call `disconnect()`.

    // MARK: - Public API

    /// Kicks off a connection attempt and remembers `hello` so it can be
    /// re-sent on every (re)connect. A subsequent call replaces the pending
    /// hello — useful for updating token / location.
    ///
    /// Idempotent: if a socket is already open (connecting/connected/
    /// authenticated), only the stored hello is updated; the existing
    /// connection is not torn down. This lets `warmup(channel:)` be called
    /// freely from higher layers without churning the socket.
    func connect(hello: PTTHelloPayload) {
        workQueue.async {
            self.manuallyDisconnected = false
            self.pendingHello = hello
            switch self._state {
            case .idle, .failed, .closing:
                self.reconnectAttempt = 0
                self.openSocket()
            case .connecting, .connected, .authenticated:
                // Socket already up; nothing else to do. Hello has been
                // stashed for the next (re)connect if that ever happens.
                break
            }
        }
    }

    /// Cancels any pending reconnect and closes the current connection.
    func disconnect() {
        workQueue.async {
            self.manuallyDisconnected = true
            self.stopHeartbeat()
            self.socket?.disconnect()
            self.socket = nil
            self.updateState(.idle)
        }
    }

    /// Sends a fully-encoded frame. Safe to call from any thread.
    func send(frame: PTTFrame) {
        let raw = PTTFrameCodec.encode(type: frame.type,
                                       seq: frame.seq,
                                       timestampMs: frame.timestampMs,
                                       payload: frame.payload)
        send(rawFrame: raw)
    }

    /// Sends a pre-encoded frame buffer. Prefer this for zero-copy paths.
    func send(rawFrame: Data) {
        workQueue.async {
            self.socket?.write(data: rawFrame)
        }
    }

    // MARK: - Socket lifecycle (workQueue only)

    private func openSocket() {
        guard let url = buildWSURL() else {
            updateState(.failed("bad host URL"))
            return
        }
        updateState(.connecting)

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let ws = WebSocket(request: request)
        ws.callbackQueue = workQueue
        ws.onEvent = { [weak self] event in
            self?.handle(event: event)
        }
        socket = ws
        ws.connect()
    }

    private func buildWSURL() -> URL? {
        var components = URLComponents(url: host, resolvingAgainstBaseURL: false)
        switch components?.scheme?.lowercased() {
        case "http":  components?.scheme = "ws"
        case "https": components?.scheme = "wss"
        default: break // already ws / wss or missing scheme
        }
        // Preserve any base path (e.g. reverse proxies), then append the PTT WS route.
        let base = components?.path ?? ""
        let joined = (base.hasSuffix("/") ? base + "ptt/ws" : base + "/ptt/ws")
        components?.path = joined
        return components?.url
    }

    private func handle(event: WebSocketEvent) {
        switch event {
        case .connected:
            log.debug("ws connected")
            updateState(.connected)
            reconnectAttempt = 0
            lastActivity = Date().timeIntervalSince1970
            sendHelloIfNeeded()
            startHeartbeat()

        case .disconnected(let reason, let code):
            log.debug("ws disconnected code=\(code) reason=\(reason, privacy: .public)")
            teardownAndMaybeReconnect(reason: "closed \(code) \(reason)")

        case .binary(let data):
            lastActivity = Date().timeIntervalSince1970
            dispatchIncomingFrame(data)

        case .text:
            // Text frames are not part of the protocol; ignore.
            break

        case .ping:
            lastActivity = Date().timeIntervalSince1970
            // Starscream auto-replies with Pong; nothing to do.

        case .pong:
            lastActivity = Date().timeIntervalSince1970

        case .viabilityChanged(let viable):
            if !viable {
                log.debug("ws viability lost")
            }

        case .reconnectSuggested:
            teardownAndMaybeReconnect(reason: "reconnect suggested by system")

        case .cancelled:
            teardownAndMaybeReconnect(reason: "cancelled")

        case .error(let error):
            let msg = error?.localizedDescription ?? "unknown"
            log.error("ws error: \(msg, privacy: .public)")
            teardownAndMaybeReconnect(reason: msg)

        case .peerClosed:
            teardownAndMaybeReconnect(reason: "peer closed")
        }
    }

    private func dispatchIncomingFrame(_ data: Data) {
        do {
            let frame = try PTTFrameCodec.decode(data)
            switch frame.type {
            case .helloAck:
                if let ack = try? JSONDecoder().decode(PTTHelloAckPayload.self, from: frame.payload) {
                    updateState(.authenticated)
                    notifyMain { manager, delegate in
                        delegate.webSocketManager(manager, didReceiveAck: ack)
                    }
                }
            case .error:
                if let err = try? JSONDecoder().decode(PTTErrorPayload.self, from: frame.payload) {
                    notifyMain { manager, delegate in
                        delegate.webSocketManager(manager, didReceiveError: err)
                    }
                }
            case .ping:
                // Application-level ping mirror; reply with pong on the same seq/ts.
                send(frame: PTTFrame(type: .pong,
                                     seq: frame.seq,
                                     timestampMs: frame.timestampMs,
                                     payload: Data()))
            case .pong:
                // Nothing to do besides updating lastActivity above.
                break
            default:
                notifyMain { manager, delegate in
                    delegate.webSocketManager(manager, didReceiveFrame: frame)
                }
            }
        } catch {
            log.error("frame decode failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func sendHelloIfNeeded() {
        guard let hello = pendingHello else { return }
        do {
            let payload = try JSONEncoder().encode(hello)
            let raw = PTTFrameCodec.encode(type: .hello, payload: payload)
            socket?.write(data: raw)
        } catch {
            log.error("hello encode failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func updateState(_ new: PTTWebSocketState) {
        guard _state != new else { return }
        _state = new
        notifyMain { manager, delegate in
            delegate.webSocketManager(manager, didChangeState: new)
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: workQueue)
        timer.schedule(deadline: .now() + Self.heartbeatInterval,
                       repeating: Self.heartbeatInterval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.socket?.write(ping: Data())
            // Bail if the peer went silent for too long.
            let idle = Date().timeIntervalSince1970 - self.lastActivity
            if idle > Self.readTimeout {
                self.log.debug("ws idle beyond readTimeout, closing")
                self.socket?.disconnect()
            }
        }
        timer.resume()
        heartbeatTimer = timer
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    // MARK: - Reconnection

    private func teardownAndMaybeReconnect(reason: String) {
        stopHeartbeat()
        socket = nil
        if manuallyDisconnected {
            updateState(.idle)
            return
        }
        updateState(.failed(reason))

        let delay = Self.reconnectDelays[min(reconnectAttempt, Self.reconnectDelays.count - 1)]
        reconnectAttempt += 1
        log.debug("scheduling reconnect in \(delay)s (attempt \(self.reconnectAttempt))")
        workQueue.asyncAfter(deadline: .now() + delay) {
            guard !self.manuallyDisconnected else { return }
            self.openSocket()
        }
    }

    // MARK: - Delegate dispatch

    /// Hops to the main actor and invokes `block` with the current delegate,
    /// if any. `self` is captured strongly for the duration of the hop; the
    /// delegate reference itself is weak.
    private func notifyMain(_ block: @escaping @MainActor @Sendable (PTTWebSocketManager, PTTWebSocketManagerDelegate) -> Void) {
        let manager = self
        Task { @MainActor in
            guard let delegate = manager.delegate else { return }
            block(manager, delegate)
        }
    }
}
