//
//  AudioMessageDBManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  AudioMessage 表的所有数据库操作,统一在此层收敛。
//  PTT 文件系统清理仍留在 PTTManager 里。
//

import Foundation
import GRDB

final class AudioMessageDBManager: @unchecked Sendable {
    static let shared = AudioMessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    // MARK: - 读

    func recentMessages(limit: Int = 50) async -> [AudioMessage] {
        do {
            return try await DB.dbQueue.read { db in
                try AudioMessage
                    .order(AudioMessage.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            logger.error("recentMessages 失败: \(error)")
            return []
        }
    }

    func unread() async -> [AudioMessage] {
        do {
            return try await DB.dbQueue.read { db in
                try AudioMessage
                    .order(AudioMessage.Columns.timestamp.desc)
                    .filter { !$0.read }
                    .fetchAll(db)
            }
        } catch {
            logger.error("unread 失败: \(error)")
            return []
        }
    }

    func fetchOne(id: String) async -> AudioMessage? {
        do {
            return try await DB.dbQueue.read { db in
                try AudioMessage.fetchOne(db, id: id)
            }
        } catch {
            logger.error("fetchOne(id:) 失败: \(error)")
            return nil
        }
    }

    // MARK: - 写

    func save(_ message: AudioMessage) async throws {
        try await DB.dbQueue.write { db in
            try message.save(db)
        }
    }

    /// 更新 read / status 字段;两个参数都为 nil 时不做任何事,返回 false。
    func setStatus(
        id: String,
        read: Bool? = nil,
        status: AudioMessage.Status? = nil
    ) async -> Bool {
        guard read != nil || status != nil else { return false }
        return (try? await DB.dbQueue.write { db in
            guard var message = try AudioMessage.fetchOne(db, id: id) else { return false }
            if let read = read {
                message.read = read
            }
            if let status = status {
                message.status = status
            }
            try message.save(db)
            return true
        }) ?? false
    }

    func deleteAll() async throws {
        _ = try await DB.dbQueue.write { db in
            try AudioMessage.deleteAll(db)
        }
    }

    // MARK: - Observation

    /// 观察最新 50 条 + 全部未读。
    func observeMessages() -> AsyncStream<[AudioMessage]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> [AudioMessage] in
                return try AudioMessage
                    .order(AudioMessage.Columns.timestamp.desc)
                    .limit(20)
                    .fetchAll(db)
            }

            let cancellable = observation.start(
                in: DB.dbQueue,
                scheduling: .async(onQueue: .global()),
                onError: { error in
                    logger.error("observeMessages 失败: \(error)")
                    continuation.finish()
                },
                onChange: { value in
                    continuation.yield(value)
                }
            )

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
