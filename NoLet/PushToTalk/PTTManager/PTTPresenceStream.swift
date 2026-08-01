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
    func presenceStream(_ stream: PTTPresenceStream, didReceive event: PresenceEvent)
    func presenceStream(_ stream: PTTPresenceStream, didChangeConnected connected: Bool, attempt: Int)
}

nonisolated final class PTTPresenceStream: NSObject, @unchecked Sendable {
    weak var delegate: PTTPresenceStreamDelegate?

    private struct State {
        var currentTask: Task<Void, Never>?
        var currentChannel: PTTChannel?
        var isStopped = true
    }
    private let state = OSAllocatedUnfairLock<State>(initialState: State())

    private let backoffTiers: [(count: Int, interval: UInt64)] = [
        (10, 3),
        (10, 5),
    ]
    private let maxRetryInterval: UInt64 = 10

    func start(channel: PTTChannel) {
        let alreadyRunning = state.withLock { s in
            if let current = s.currentChannel, current == channel, s.currentTask != nil {
                return true
            }
            s.isStopped = false
            s.currentChannel = channel
            return false
        }
        if alreadyRunning { return }
        stop()
        state.withLock {
            $0.isStopped = false
            $0.currentChannel = channel
        }
        let task = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.loop(channel: channel)
        }
        state.withLock { $0.currentTask = task }
    }

    func stop() {
        state.withLock { s in
            s.isStopped = true
            s.currentTask?.cancel()
            s.currentTask = nil
            s.currentChannel = nil
        }
    }

    // MARK: - Private

    private func loop(channel: PTTChannel) async {
        var attempt = 0
        while !state.withLock({ $0.isStopped }) {
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

            if state.withLock({ $0.isStopped }) { return }
            attempt += 1
            self.delegate?.presenceStream(self, didChangeConnected: false, attempt: attempt)
            var remaining = attempt
            var seconds = maxRetryInterval
            for tier in backoffTiers {
                if remaining <= tier.count {
                    seconds = tier.interval
                    break
                }
                remaining -= tier.count
            }
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
        request.timeoutInterval = 30

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.waitsForConnectivity = false
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
        self.delegate?.presenceStream(self, didChangeConnected: true, attempt: 0)

        let lastReceived = OSAllocatedUnfairLock(initialState: Date())
        let idleLimit: TimeInterval = 45

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                var eventName = ""
                var dataBuffer = ""

                func dispatch() {
                    guard !dataBuffer.isEmpty else { return }
                    if let event = self.parse(eventName: eventName, data: dataBuffer) {
                        self.delegate?.presenceStream(self, didReceive: event)
                    }
                    eventName = ""
                    dataBuffer = ""
                }

                for try await line in bytes.lines {
                    if Task.isCancelled || self.state.withLock({ $0.isStopped }) { return }
                    lastReceived.withLock { $0 = Date() }
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty {
                        dispatch()
                        continue
                    }
                    if trimmed.hasPrefix(":") {
                        dispatch()
                        continue
                    }
                    if let colonIndex = trimmed.firstIndex(of: ":") {
                        let field = String(trimmed[trimmed.startIndex..<colonIndex])
                        var value = trimmed[trimmed.index(after: colonIndex)...]
                        if value.first == " " { value = value.dropFirst() }
                        switch field {
                        case "event":
                            if !dataBuffer.isEmpty { dispatch() }
                            eventName = String(value)
                        case "data":
                            if !dataBuffer.isEmpty { dataBuffer += "\n" }
                            dataBuffer += String(value)
                            if !eventName.isEmpty { dispatch() }
                        default: break
                        }
                    }
                }
            }
            group.addTask {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(5))
                    let elapsed = lastReceived.withLock { -$0.timeIntervalSinceNow }
                    if elapsed > idleLimit {
                        throw URLError(.timedOut)
                    }
                }
            }
            do {
                try await group.next()
            } catch {
                group.cancelAll()
                throw error
            }
            group.cancelAll()
        }
    }

    private func parse(eventName: String, data: String) -> PresenceEvent? {
        guard let raw = data.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(PresenceEvent.self, from: raw)
        } catch {
            logger.debug("SSE decode error: \(error)")
            return nil
        }
    }
}

