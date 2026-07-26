//
//  ChatPromptDBManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  ChatPrompt 表的所有数据库操作,统一在此层收敛。
//

import Foundation
import GRDB

final nonisolated class ChatPromptDBManager: @unchecked Sendable {
    static let shared = ChatPromptDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    // MARK: - 读

    nonisolated func fetchAll() async -> [ChatPrompt] {
        do {
            return try await DB.dbQueue.read { db in
                try ChatPrompt.fetchAll(db)
            }
        } catch {
            logger.error("fetchAll 失败: \(error)")
            return []
        }
    }

    nonisolated func fetchOne(id: String) async -> ChatPrompt? {
        do {
            return try await DB.dbQueue.read { db in
                try ChatPrompt.fetchOne(db, key: id)
            }
        } catch {
            logger.error("fetchOne(id:) 失败: \(error)")
            return nil
        }
    }

    /// 若传入 inside,则只统计 inside == 该值 的记录。
    nonisolated func count(inside: Bool? = nil) async -> Int {
        do {
            return try await DB.dbQueue.read { db in
                if let inside = inside {
                    return try ChatPrompt
                        .filter(ChatPrompt.Columns.inside == inside)
                        .fetchCount(db)
                }
                return try ChatPrompt.fetchCount(db)
            }
        } catch {
            logger.error("count(inside:) 失败: \(error)")
            return 0
        }
    }

    // MARK: - 写

    nonisolated func insert(_ prompt: ChatPrompt) async throws {
        try await DB.dbQueue.write { db in
            try prompt.insert(db)
        }
    }

    nonisolated func update(id: String, title: String, content: String) async {
        do {
            try await DB.dbQueue.write { db in
                if var prompt = try ChatPrompt.fetchOne(db, key: id) {
                    prompt.title = title
                    prompt.content = content
                    try prompt.update(db)
                }
            }
        } catch {
            logger.error("update 失败: \(error)")
        }
    }

    nonisolated func delete(id: String) async {
        do {
            try await DB.dbQueue.write { db in
                _ = try ChatPrompt
                    .filter(Column("id") == id)
                    .deleteAll(db)
            }
        } catch {
            logger.error("delete(id:) 失败: \(error)")
        }
    }

    nonisolated func deleteAll(inside: Bool) async {
        do {
            _ =  try await DB.dbQueue.write { db in
                try ChatPrompt
                    .filter(ChatPrompt.Columns.inside == inside)
                    .deleteAll(db)
            }
        } catch {
            logger.error("deleteAll(inside:) 失败: \(error)")
        }
    }

    /// 事务地清空所有 inside==true 的 prompt 并插入新的一批。
    nonisolated func replaceInsidePrompts(_ prompts: [ChatPrompt]) async throws {
        try await DB.dbQueue.write { db in
            try ChatPrompt
                .filter(ChatPrompt.Columns.inside == true)
                .deleteAll(db)
            for prompt in prompts {
                try prompt.insert(db)
            }
        }
    }

    // MARK: - Observation

    nonisolated func observeCount() -> AsyncStream<Int> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> Int in
                try ChatPrompt.fetchCount(db)
            }

            let cancellable = observation.start(
                in: DB.dbQueue,
                scheduling: .async(onQueue: .global()),
                onError: { error in
                    logger.error("observeCount 失败: \(error)")
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
