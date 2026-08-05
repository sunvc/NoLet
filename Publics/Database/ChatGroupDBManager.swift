//
//  ChatGroupDBManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  ChatGroup 表的所有数据库操作,统一在此层收敛。
//  delete 会级联清除该 group 名下的 ChatMessage。
//

import Foundation
import GRDB

final class ChatGroupDBManager: @unchecked Sendable {
    static let shared = ChatGroupDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    // MARK: - 读

    func fetchCurrent() async -> ChatGroup? {
        (try? await DB.dbQueue.read { db in
            try ChatGroup.filter { $0.current }.fetchOne(db)
        }) ?? nil
    }

    func fetchCurrentSync() -> ChatGroup? {
        (try? DB.dbQueue.read { db in
            try ChatGroup.filter { $0.current }.fetchOne(db)
        }) ?? nil
    }

    func fetchAll() async -> [ChatGroup] {
        do {
            return try await DB.dbQueue.read { db in
                try ChatGroup.order(ChatGroup.Columns.timestamp.desc).fetchAll(db)
            }
        } catch {
            logger.error("fetchAll 失败: \(error)")
            return []
        }
    }

    func fetchOne(id: String) async -> ChatGroup? {
        do {
            return try await DB.dbQueue.read { db in
                try ChatGroup.fetchOne(db, key: id)
            }
        } catch {
            logger.error("fetchOne(id:) 失败: \(error)")
            return nil
        }
    }

    // MARK: - 写

    func insert(_ group: ChatGroup) async throws {
        try await DB.dbQueue.write { db in
            try group.insert(db)
        }
    }

    /// 引用消息生成 group: 若已有则返回,否则插入并设为当前。
    func upsertQuoteGroup(id: String, name: String) async -> ChatGroup? {
        do {
            return try await DB.dbQueue.write { db in
                if let existing = try ChatGroup.fetchOne(db, key: id) {
                    return existing
                }
                let group = ChatGroup(
                    id: id,
                    timestamp: .now,
                    name: name,
                    host: "",
                    current: true
                )
                try ChatGroup
                    .filter { $0.id != id }
                    .updateAll(db, ChatGroup.Columns.current.set(to: false))
                try group.insert(db)
                return group
            }
        } catch {
            logger.error("upsertQuoteGroup 失败: \(error)")
            return nil
        }
    }

    /// 传入 nil 时把所有 group 的 current 置 false。
    func setCurrent(_ group: ChatGroup?) async {
        do {
            try await DB.dbQueue.write { db in
                if let group = group {
                    try ChatGroup
                        .filter { $0.id != group.id }
                        .updateAll(db, ChatGroup.Columns.current.set(to: false))
                    try ChatGroup
                        .filter { $0.id == group.id }
                        .updateAll(db, ChatGroup.Columns.current.set(to: true))
                } else {
                    try ChatGroup
                        .filter { $0.current }
                        .updateAll(db, ChatGroup.Columns.current.set(to: false))
                }
            }
        } catch {
            logger.error("setCurrent 失败: \(error)")
        }
    }

    func setPointToNow(id: String) async -> Bool {
        do {
            return try await DB.dbQueue.write { db in
                if var group = try ChatGroup.filter(id: id).fetchOne(db) {
                    group.point = .now
                    try group.upsert(db)
                    return true
                }
                return false
            }
        } catch {
            return false
        }
    }

    func rename(id: String, newName: String, makeCurrent: Bool = false) async {
        do {
            try await DB.dbQueue.write { db in
                if var group = try ChatGroup.filter(ChatGroup.Columns.id == id).fetchOne(db) {
                    group.name = newName
                    if makeCurrent {
                        group.current = true
                    }
                    try group.update(db)
                }
            }
        } catch {
            logger.error("rename 失败: \(error)")
        }
    }

    /// 级联: 先删同 group 的 ChatMessage,再删该 ChatGroup。
    func delete(id: String) async {
        do {
            try await DB.dbQueue.write { db in
                try ChatMessage
                    .filter(ChatMessage.Columns.chat == id)
                    .deleteAll(db)
                _ = try ChatGroup.filter { $0.id == id }.deleteAll(db)
            }
        } catch {
            logger.error("delete(id:) 失败: \(error)")
        }
    }

    /// 一次性清空所有 ChatGroup + ChatMessage。
    func deleteAll() async {
        do {
            try await DB.dbQueue.write { db in
                try ChatMessage.deleteAll(db)
                try ChatGroup.deleteAll(db)
            }
        } catch {
            logger.error("ChatGroup deleteAll 失败: \(error)")
        }
    }

    /// 清理无消息的 group (原 clearunuse)
    func deleteEmpty() async {
        do {
            try await DB.dbQueue.write { db in
                let allGroups = try ChatGroup.fetchAll(db)
                for group in allGroups {
                    let messageCount = try ChatMessage
                        .filter(ChatMessage.Columns.chat == group.id)
                        .fetchCount(db)
                    if messageCount == 0 {
                        try group.delete(db)
                    }
                }
            }
        } catch {
            logger.error("deleteEmpty 失败: \(error)")
        }
    }

    // MARK: - Observation

    /// 观察 group 总数 + 当前 group。
    func observeSummary() -> AsyncStream<(groupsCount: Int, current: ChatGroup?)> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> (Int, ChatGroup?) in
                let count = try ChatGroup.fetchCount(db)
                let current = try? ChatGroup.filter { $0.current }.fetchOne(db)
                return (count, current)
            }

            let cancellable = observation.start(
                in: DB.dbQueue,
                scheduling: .async(onQueue: .global()),
                onError: { error in
                    logger.error("observeSummary 失败: \(error)")
                    continuation.finish()
                },
                onChange: { value in
                    continuation.yield((groupsCount: value.0, current: value.1))
                }
            )

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
