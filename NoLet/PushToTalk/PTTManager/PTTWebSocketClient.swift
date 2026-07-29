//
//  SWIFT: 6.0
//  NoLet - PTTWebSocketClient.swift
//
//  基于 URLSessionWebSocketTask 的 PTT 长连接客户端,取代 PTTPresenceStream 的 SSE 传输。
//  打开连接后先发 hello 文本帧,再进入递归 receive 循环:文本帧解析为 PresenceEvent,
//  二进制帧按 [4字节大端长度][meta JSON][audio] 拆包回调。断线自动指数退避重连,
//  主动 stop 后不再重连。
//
//  History:
//    Created by Neo on 2026/7/28.

import CoreLocation
import Defaults
import Foundation
import os

/// 服务器推来的一条事件(由 PTTPresenceStream.swift 迁移至此,Task 7 删除该文件后此处为唯一定义)
nonisolated struct PresenceEvent: Decodable, Sendable {
    enum Kind: String, Decodable, Sendable {
        case snapshot
        case join
        case leave
        case update
        case ping
    }
    struct User: Decodable, Sendable {
        var id: String
        var latitude: Double
        var longitude: Double
        var timestamp: Int64?
    }
    var event: Kind
    var channel: String
    var user: User?
    var users: [User]?
    var ts: Int64?
}

/// 语音二进制帧的元信息,与 Go 服务端 VoiceFrameMeta 对齐。
/// Codable:发送时 Encode,接收时 Decode。
nonisolated struct PTTVoiceMeta: Codable, Sendable {
    let channel: String
    let file: String
    let sign: Bool
    let sender: String
}

nonisolated protocol PTTWebSocketClientDelegate: AnyObject, Sendable {
    /// 收到 presence 事件回调,在任意线程被调用,实现方自行切主线程
    func webSocket(_ client: PTTWebSocketClient, didReceive event: PresenceEvent)
    /// 收到语音二进制帧回调
    func webSocket(_ client: PTTWebSocketClient, didReceiveVoice meta: PTTVoiceMeta, audio: Data)
    /// 长连接建立/断开(仅用于日志/状态展示)
    func webSocket(_ client: PTTWebSocketClient, didChangeConnected connected: Bool)
}

nonisolated final class PTTWebSocketClient: NSObject, @unchecked Sendable {
    weak var delegate: PTTWebSocketClientDelegate?

    private var currentTask: Task<Void, Never>?
    private var currentChannel: PTTChannel?
    private var isStopped = true

    /// 同一次 `start()` 生命周期内是否已经成功打过一次 hello。
    /// 首次连接发 hello 走服务端 SyncChannels diff;之后所有重连发 rejoin 让服务端
    /// 无条件广播 join,通知别人"我回来了"。
    private var hasJoinedOnce = false

    private var session: URLSession?
    private var socket: URLSessionWebSocketTask?

    /// 断线重连节奏 —— 前 5 次 1s 追瞬断秒回,之后 3/5/10 递增,尾巴稳定 10s。
    /// 永不放弃,直到显式 stop()。
    private let backoffSchedule: [UInt64] = [1, 1, 1, 1, 1, 3, 5, 10]

    // MARK: - Public

    /// 启动长连接。若已在同一个 (server,channel) 上,noop。切换 channel 会 teardown 旧连接。
    func start(channel: PTTChannel) {
        if let current = currentChannel, current == channel, currentTask != nil {
            return
        }
        stop()
        isStopped = false
        currentChannel = channel
        hasJoinedOnce = false

        currentTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.loop(channel: channel)
        }
    }

    /// 主动断开(切后台/关频道),不再重连。
    func stop() {
        isStopped = true
        currentTask?.cancel()
        currentTask = nil
        currentChannel = nil
        teardownTransport()
    }

    /// 回前台踢一脚: App 被挂起时 socket 已被 iOS 冻结,receive 可能还卡着没抛错。
    /// 保留 currentChannel/isStopped=false,只把 socket 撤掉 → 现有 loop 内的 receive
    /// 立刻抛错 → 走 backoff 重连。比等 timeout 快。
    func kick() {
        guard !isStopped, currentChannel != nil else { return }
        teardownTransport()
    }

    /// 关闭底层 socket/session。
    private func teardownTransport() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        session?.finishTasksAndInvalidate()
        session = nil
    }

    /// 发送 presence 文本帧。
    func sendPresence(latitude: Double, longitude: Double) {
        let msg = PresenceMsg(latitude: latitude, longitude: longitude)
        guard let data = try? JSONEncoder().encode(msg),
            let json = String(data: data, encoding: .utf8)
        else { return }
        socket?.send(.string(json)) { error in
            if let error {
                logger.error("WS sendPresence error: \(error)")
            }
        }
    }

    /// 发送语音二进制帧,返回是否成功派发写入。
    func sendVoice(meta: PTTVoiceMeta, audio: Data) -> Bool {
        guard let socket, let frame = encodeVoiceFrame(meta: meta, audio: audio) else {
            return false
        }
        socket.send(.data(frame)) { error in
            if let error {
                logger.error("WS sendVoice error: \(error)")
            }
        }
        return true
    }

    // MARK: - Private

    private func loop(channel: PTTChannel) async {
        var attempt = 0
        while !isStopped {
            let startedAt = Date()
            do {
                try await self.connect(channel: channel)
                logger.info("WS stream ended normally after \(Int(-startedAt.timeIntervalSinceNow))s")
                attempt = 0
            } catch is CancellationError {
                return
            } catch {
                logger.error("WS loop error after \(Int(-startedAt.timeIntervalSinceNow))s: \(error)")
            }
            self.delegate?.webSocket(self, didChangeConnected: false)

            if isStopped { return }
            let seconds = self.backoffSchedule[
                min(attempt, self.backoffSchedule.count - 1)
            ]
            attempt += 1
            try? await Task.sleep(for: .seconds(Double(seconds)))
        }
    }

    private func connect(channel: PTTChannel) async throws {
        guard channel.serverOK else { throw URLError(.badURL) }
        guard let base = URL(string: channel.server.url) else {
            throw URLError(.badURL)
        }
        var url = base
        url.appendPathComponent("ptt")
        url.appendPathComponent("ws")

        let (hello, headers): (Hello, [String: String]) = await MainActor.run {
            let h = Hello(
                id: Defaults[.member].id,
                channels: [channel.hex()],
                latitude: LocManager.shared.location.coordinate.latitude,
                longitude: LocManager.shared.location.coordinate.longitude,
                token: Defaults[.member].talk,
                host: channel.server.url
            )
            let hd = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )
            return (h, hd)
        }

        var request = URLRequest(url: url)
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        // Upgrade 阶段 10s 拿不到 101 就 fail,让 loop 进 catch 走 backoff 重试。
        request.timeoutInterval = 10

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 3600
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        // ❌ 不能开 waitsForConnectivity:server 挂后 iOS 会把新 connect 请求排队"永久等待",
        // 既不抛错也不返回,loop 永远卡在这里,永远不会重连。
        config.waitsForConnectivity = false
        let session = URLSession(configuration: config)
        self.session = session
        defer {
            session.finishTasksAndInvalidate()
            if self.session === session { self.session = nil }
        }

        let socket = session.webSocketTask(with: request)
        self.socket = socket
        socket.resume()

        // 首次连接发 hello 走服务端 diff;重连发 rejoin 让服务端无条件广播 join。
        // 只要 send 成功不抛,就置 hasJoinedOnce = true —— 断线后下一轮 loop 会走 rejoin。
        let isRejoin = self.hasJoinedOnce
        let handshakeJSON: String?
        if isRejoin {
            let r = Rejoin(
                id: hello.id,
                channels: hello.channels,
                latitude: hello.latitude,
                longitude: hello.longitude,
                token: hello.token,
                host: hello.host
            )
            handshakeJSON = (try? JSONEncoder().encode(r))
                .flatMap { String(data: $0, encoding: .utf8) }
        } else {
            handshakeJSON = (try? JSONEncoder().encode(hello))
                .flatMap { String(data: $0, encoding: .utf8) }
        }
        if let json = handshakeJSON {
            try await socket.send(.string(json))
            self.hasJoinedOnce = true
        }

        self.delegate?.webSocket(self, didChangeConnected: true)

        // 递归 receive 循环
        while !isStopped && !Task.isCancelled {
            let message = try await socket.receive()
            if isStopped || Task.isCancelled { return }
            switch message {
            case .string(let text):
                if let event = self.parse(text: text) {
                    self.delegate?.webSocket(self, didReceive: event)
                }
            case .data(let data):
                if let (meta, audio) = self.decodeVoiceFrame(data) {
                    self.delegate?.webSocket(self, didReceiveVoice: meta, audio: audio)
                }
            @unknown default:
                break
            }
        }
    }

    private func parse(text: String) -> PresenceEvent? {
        guard let raw = text.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(PresenceEvent.self, from: raw)
        } catch {
            logger.debug("WS decode error: \(error) data=\(text)")
            return nil
        }
    }

    private func encodeVoiceFrame(meta: PTTVoiceMeta, audio: Data) -> Data? {
        guard let metaData = try? JSONEncoder().encode(meta) else { return nil }
        var out = Data()
        var len = UInt32(metaData.count).bigEndian
        withUnsafeBytes(of: &len) { out.append(contentsOf: $0) }
        out.append(metaData)
        out.append(audio)
        return out
    }

    private func decodeVoiceFrame(_ data: Data) -> (PTTVoiceMeta, Data)? {
        guard data.count >= 4 else { return nil }
        let n = Int(data.subdata(in: 0..<4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
        guard n >= 0, 4 + n <= data.count else { return nil }
        let metaData = data.subdata(in: 4..<(4 + n))
        let audio = data.subdata(in: (4 + n)..<data.count)
        guard let meta = try? JSONDecoder().decode(PTTVoiceMeta.self, from: metaData) else {
            return nil
        }
        return (meta, audio)
    }
}

// MARK: - Frame Models

extension PTTWebSocketClient {
    nonisolated struct Hello: Encodable {
        let type = "hello"
        let id: String
        let channels: [String]
        let latitude: Double
        let longitude: Double
        let token: String
        let host: String
    }
    /// 断线重连的握手帧: 结构与 Hello 一致, type 不同。服务端收到 rejoin 后
    /// 无条件广播 join, 让别人知道"这个人回来了", 不走 SyncChannels 的 diff。
    nonisolated struct Rejoin: Encodable {
        let type = "rejoin"
        let id: String
        let channels: [String]
        let latitude: Double
        let longitude: Double
        let token: String
        let host: String
    }
    nonisolated struct PresenceMsg: Encodable {
        let type = "presence"
        let latitude: Double
        let longitude: Double
    }
}
