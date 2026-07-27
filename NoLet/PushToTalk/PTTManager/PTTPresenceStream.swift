//
//  SWIFT: 6.0
//  NoLet - PTTPresenceStream.swift
//
//  订阅服务器的 SSE 事件流,替换 10s POST 轮询。收到 snapshot/join/leave/update 事件后
//  实时更新 PTTManager.onlineUsers。断线自动指数退避重连。
//
//  History:
//    Created by Neo on 2026/7/26.

import CoreLocation
import Defaults
import Foundation
import os

/// 服务器推来的一条事件
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

nonisolated protocol PTTPresenceStreamDelegate: AnyObject, Sendable {
    /// 收到事件回调,在任意线程被调用,实现方自行切主线程
    func presenceStream(_ stream: PTTPresenceStream, didReceive event: PresenceEvent)
    /// 长连接建立/断开(仅用于日志/状态展示)
    func presenceStream(_ stream: PTTPresenceStream, didChangeConnected connected: Bool)
}

nonisolated final class PTTPresenceStream: NSObject, @unchecked Sendable {
    weak var delegate: PTTPresenceStreamDelegate?

    private var currentTask: Task<Void, Never>?
    private var currentChannel: PTTChannel?
    private var isStopped = true

    private let backoffSchedule: [UInt64] = [1, 3, 5, 10, 30]

    /// 启动订阅。若已在同一个 (server,channel) 上,noop。切换 channel 会 teardown 旧连接。
    func start(channel: PTTChannel) {
        if let current = currentChannel, current == channel, currentTask != nil {
            return
        }
        stop()
        isStopped = false
        currentChannel = channel

        currentTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.loop(channel: channel)
        }
    }

    func stop() {
        isStopped = true
        currentTask?.cancel()
        currentTask = nil
        currentChannel = nil
    }

    // MARK: - Private

    private func loop(channel: PTTChannel) async {
        var attempt = 0
        while !isStopped {
            let startedAt = Date()
            do {
                try await self.connect(channel: channel)
                logger.info("SSE stream ended normally after \(Int(-startedAt.timeIntervalSinceNow))s")
                attempt = 0
            } catch is CancellationError {
                return
            } catch {
                logger.error("SSE loop error after \(Int(-startedAt.timeIntervalSinceNow))s: \(error)")
            }
            self.delegate?.presenceStream(self, didChangeConnected: false)

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
        url.appendPathComponent("subscribe")

        struct Body: Encodable {
            var id: String
            var channels: [String]
            var latitude: Double
            var longitude: Double
            var token: String
            var host: String
        }

        let (body, headers): (Body, [String: String]) = await MainActor.run {
            let b = Body(
                id: Defaults[.member].id,
                channels: [channel.hex()],
                latitude: LocManager.shared.location.coordinate.latitude,
                longitude: LocManager.shared.location.coordinate.longitude,
                token: Defaults[.member].talk,
                host: channel.server.url
            )
            let h = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )
            return (b, h)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 3600

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            var head = Data()
            do {
                for try await byte in bytes {
                    head.append(byte)
                    if head.count > 256 { break }
                }
            } catch {  }
            let snippet = String(data: head, encoding: .utf8) ?? ""
            logger.error("SSE HTTP \(http.statusCode) body=\(snippet)")
            throw URLError(.badServerResponse)
        }
        self.delegate?.presenceStream(self, didChangeConnected: true)

        var eventName = ""
        var dataBuffer = ""

        for try await line in bytes.lines {
            if Task.isCancelled || isStopped { return }

            if line.isEmpty {
                if !dataBuffer.isEmpty {
                    if let event = self.parse(eventName: eventName, data: dataBuffer) {
                        self.delegate?.presenceStream(self, didReceive: event)
                    }
                }
                eventName = ""
                dataBuffer = ""
                continue
            }
            if line.hasPrefix(":") {
                continue
            }
            if let colonIndex = line.firstIndex(of: ":") {
                let field = String(line[line.startIndex..<colonIndex])
                var value = line[line.index(after: colonIndex)...]
                if value.first == " " { value = value.dropFirst() }
                switch field {
                case "event": eventName = String(value)
                case "data":
                    if !dataBuffer.isEmpty { dataBuffer += "\n" }
                    dataBuffer += String(value)
                default: break
                }
            }
        }
    }

    private func parse(eventName: String, data: String) -> PresenceEvent? {
        guard let raw = data.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(PresenceEvent.self, from: raw)
        } catch {
            logger.debug("SSE decode error: \(error) data=\(data)")
            return nil
        }
    }
}
