//
//  ChatMessageDBManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  ChatMessage 表的所有数据库操作,统一在此层收敛。
//

import Foundation
import GRDB

final nonisolated class ChatMessageDBManager: @unchecked Sendable {
    static let shared = ChatMessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    // MARK: - 读

    /// 修复 bug: 按 chat 列(而非 message 列)过滤
    nonisolated func count(inGroup groupID: String) async -> Int {
        do {
            return try await DB.dbQueue.read { db in
                try ChatMessage
                    .filter(ChatMessage.Columns.chat == groupID)
                    .fetchCount(db)
            }
        } catch {
            logger.error("count(inGroup:) 失败: \(error)")
            return 0
        }
    }

    /// SwiftUI 行内计算属性使用的同步版本
    nonisolated func countSync(inGroup groupID: String) -> Int {
        (try? DB.dbQueue.read { db in
            try ChatMessage
                .filter(ChatMessage.Columns.chat == groupID)
                .fetchCount(db)
        }) ?? 0
    }

    nonisolated func fetch(
        inGroup groupID: String,
        ascending: Bool = true,
        limit: Int
    ) async -> [ChatMessage] {
        do {
            return try await DB.dbQueue.read { db in
                let base = ChatMessage.filter(ChatMessage.Columns.chat == groupID)
                let ordered = ascending
                    ? base.order(ChatMessage.Columns.timestamp)
                    : base.order(ChatMessage.Columns.timestamp.desc)
                return try ordered.limit(limit).fetchAll(db)
            }
        } catch {
            logger.error("fetch(inGroup:) 失败: \(error)")
            return []
        }
    }

    nonisolated func fetchHistory(
        groupID: String,
        after point: Date?,
        limit: Int
    ) async -> [ChatMessage] {
        do {
            return try await DB.dbQueue.read { db in
                var request = ChatMessage
                    .filter(ChatMessage.Columns.chat == groupID)
                if let point = point {
                    request = request.filter(ChatMessage.Columns.timestamp > point)
                }
                return try request
                    .order(ChatMessage.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            logger.error("fetchHistory 失败: \(error)")
            return []
        }
    }

    nonisolated func fetchHistorySync(
        groupID: String,
        after point: Date?,
        limit: Int
    ) -> [ChatMessage] {
        (try? DB.dbQueue.read { db in
            var request = ChatMessage
                .filter(ChatMessage.Columns.chat == groupID)
            if let point = point {
                request = request.filter(ChatMessage.Columns.timestamp > point)
            }
            return try request
                .order(ChatMessage.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }) ?? []
    }

    // MARK: - 写

    nonisolated func insert(_ message: ChatMessage) async throws {
        try await DB.dbQueue.write { db in
            try message.insert(db)
        }
    }

    nonisolated func deleteByGroup(_ groupID: String) async {
        do {
            _ = try await DB.dbQueue.write { db in
                try ChatMessage
                    .filter(ChatMessage.Columns.chat == groupID)
                    .deleteAll(db)
            }
        } catch {
            logger.error("deleteByGroup 失败: \(error)")
        }
    }

    nonisolated func deleteAll() async {
        do {
            _ = try await DB.dbQueue.write { db in
                try ChatMessage.deleteAll(db)
            }
        } catch {
            logger.error("ChatMessage deleteAll 失败: \(error)")
        }
    }

    // MARK: - Observation

    /// 观察指定 group 内 ChatMessage 数量。
    /// 传 nil 时不追加 group 过滤。
    nonisolated func observeCount(inGroup groupID: String?) -> AsyncStream<Int> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> Int in
                if let groupID = groupID {
                    return try ChatMessage
                        .filter(ChatMessage.Columns.chat == groupID)
                        .fetchCount(db)
                }
                return try ChatMessage.fetchCount(db)
            }

            let cancellable = observation.start(
                in: DB.dbQueue,
                scheduling: .async(onQueue: .global()),
                onError: { error in
                    logger.error("observeCount(inGroup:) 失败: \(error)")
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
