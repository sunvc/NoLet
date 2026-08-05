//
//  MessageDBManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  Message 表的所有数据库操作,统一在此层收敛。
//  上层 (MessagesManager / View / Intent) 只调用本类的 async 方法。
//

import Foundation
import GRDB

final class MessageDBManager: @unchecked Sendable {
    static let shared = MessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    // MARK: - 读

    func fetchOne(id: String) async -> Message? {
        do {
            return try await DB.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            logger.error("Failed to query message by id: \(error)")
            return nil
        }
    }

    /// 同步版本 (供 NoLetChatManager 里的 sync 流程使用)
    func fetchOneSync(id: String) -> Message? {
        do {
            return try DB.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            logger.error("Failed to query message by id: \(error)")
            return nil
        }
    }

    func count(group: String? = nil) async -> Int {
        do {
            return try await DB.dbQueue.read { db in
                if let group = group {
                    return try Message.filter(Message.Columns.group == group).fetchCount(db)
                } else {
                    return try Message.fetchCount(db)
                }
            }
        } catch {
            logger.error("\(error)")
            return 0
        }
    }

    func unreadCount(group: String? = nil) async -> Int {
        do {
            return try await DB.dbQueue.read { db in
                var request = Message.filter(Message.Columns.read == false)
                if let group = group {
                    request = request.filter(Message.Columns.group == group)
                }
                return try request.fetchCount(db)
            }
        } catch {
            logger.error("查询失败")
            return 0
        }
    }

    func searchRequest(
        search: String,
        group: String? = nil,
        date: Date? = nil
    ) -> QueryInterfaceRequest<Message> {
        let keywords = search
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var request = Message.order(Message.Columns.createDate.desc)

        for keyword in keywords {
            let escaped = keyword
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")

            let pattern = "%\(escaped)%"

            let perKeywordFilter =
                Message.Columns.title.like(pattern)
                    || Message.Columns.subtitle.like(pattern)
                    || Message.Columns.body.like(pattern)
                    || Message.Columns.group.like(pattern)
                    || Message.Columns.url.like(pattern)

            request = request.filter(perKeywordFilter)
        }

        if let group = group {
            request = request.filter(Message.Columns.group == group)
        }

        if let date = date {
            request = request.filter(Message.Columns.createDate < date)
        }

        return request
    }

    func query(search: String,
        group: String? = nil,
        limit lim: Int = 50,
        before date: Date? = nil
    ) async -> ([Message], Int) {
        let start = CFAbsoluteTimeGetCurrent()
        let request = searchRequest(search: search, group: group, date: date)

        do {
            async let datas = DB.dbQueue.read { db in
                try request.limit(lim).fetchAll(db)
            }

            async let counts = DB.dbQueue.read { db in
                try request.fetchCount(db)
            }

            let (results, total) = try await (datas, counts)
            let diff = CFAbsoluteTimeGetCurrent() - start
            logger.info("⏱️ \(search)-用时: \(diff)s")
            return (results, total)
        } catch {
            logger.error("Query error: \(error)")
            return ([], 0)
        }
    }

    func queryGroupHeads() async -> [Message] {
        do {
            return try await DB.dbQueue.read { db in
                try Message.fetchAll(db, sql: """
                       SELECT *
                       FROM (
                           SELECT *,
                                  ROW_NUMBER() OVER (PARTITION BY "group" ORDER BY createDate DESC) AS rn
                           FROM message
                       )
                       WHERE rn = 1
                    """)
            }
        } catch {
            logger.error("Failed to query messages: \(error)")
            return []
        }
    }

    func query(
        group: String? = nil,
        limit lim: Int = 100,
        before date: Date? = nil,
        function: String = #function
    ) async -> [Message] {
        let startTime = ContinuousClock.now
        do {
            let results = try await DB.dbQueue.read { db in
                var request = Message.order(Message.Columns.createDate.desc)
                if let group = group { request = request.filter(Message.Columns.group == group) }
                if let date = date { request = request.filter(Message.Columns.createDate < date) }
                return try request.limit(lim).fetchAll(db)
            }

            let endTime = ContinuousClock.now
            let duration = startTime.duration(to: endTime)
            logger.info("\(function)🔍 查询组 [\(group ?? "全部")] 耗时: \(duration)")
            return results
        } catch {
            logger.error("Query failed: \(error)")
            return []
        }
    }

    // MARK: - 写

    func upsert(_ message: Message) async throws {
        try await DB.dbQueue.write { db in
            try message.insert(db, onConflict: .replace)
        }
    }

    func markAllRead(group: String? = nil) async {
        do {
            try await DB.dbQueue.write { db in
                var request = Message.filter(Message.Columns.read == false)
                if let group = group {
                    request = request.filter(Message.Columns.group == group)
                }
                try request.updateAll(db, [Message.Columns.read.set(to: true)])
            }
        } catch {
            logger.error("markAllRead error")
        }
    }

    func markUnreadAsRead() async -> Int {
        return (try? await DB.dbQueue.write { db in
            try Message
                .filter(Message.Columns.read == false)
                .updateAll(db, [Message.Columns.read.set(to: true)])
        }) ?? 0
    }

    func delete(allRead: Bool = false, before date: Date? = nil) async {
        do {
            try await DB.dbQueue.write { db in
                var request = Message.all()
                if allRead, let date = date {
                    request = request
                        .filter(Message.Columns.read == true)
                        .filter(Message.Columns.createDate < date)
                } else if allRead {
                    request = request.filter(Message.Columns.read == true)
                } else if let date = date {
                    request = request.filter(Message.Columns.createDate < date)
                } else {
                    return
                }
                try request.deleteAll(db)
            }
        } catch {
            logger.error("删除消息失败: \(error)")
        }
    }

    func delete(_ message: Message, inGroup: Bool = false) async -> Int {
        do {
            if inGroup {
                return try await DB.dbQueue.write { db in
                    try Message
                        .filter(Message.Columns.group == message.group)
                        .deleteAll(db)
                    return try Message.filter(Message.Columns.group == message.group).fetchCount(db)
                }
            }
            let result = try await DB.dbQueue.write { db in
                try message.delete(db)
                return try Message.filter(Message.Columns.group == message.group).fetchCount(db)
            }
            return result
        } catch {
            logger.error("删除消息失败:\(error)")
        }
        return -1
    }

    func delete(id: String) async -> String? {
        do {
            let result: String? = try await DB.dbQueue.write { db in
                if let message = try Message.filter(Message.Columns.id == id).fetchOne(db) {
                    try message.delete(db)
                    return message.group
                }
                return nil
            }
            return result
        } catch {
            logger.error("删除消息失败:\(error)")
            return nil
        }
    }

    func delete(beforeDate: Date) async throws {
        _ = try await DB.dbQueue.write { db in
            try Message
                .filter(Message.Columns.createDate < beforeDate)
                .deleteAll(db)
        }
    }

    func deleteExpired() async {
        do {
            try await DB.dbQueue.write { db in
                try db.execute(
                    sql: """
                    DELETE FROM message
                    WHERE ttl != ?
                      AND datetime(createdate, '+' || ttl || ' seconds') < datetime('now')
                    """,
                    arguments: [
                        ExpirationTime.forever.rawValue
                    ]
                )
            }
        } catch {
            logger.error("删除失败: \(error)")
        }
    }

    // MARK: - Import / Export / Stress

    /// TODO: 流式读取
    func importJSON(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let results = try decoder.decode([Message].self, from: data)

        try DB.dbQueue.write { db in
            for item in results {
                try item.insert(db)
            }
        }
    }

    /// 流式导出数据库到 JSON 文件
    func exportJSON(fileURL: URL) throws {
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }

        try handle.write(contentsOf: Data("[".utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .secondsSince1970

        try DB.dbQueue.read { db in
            let cursor = try Message.fetchCursor(db)
            var first = true
            while let message = try cursor.next() {
                autoreleasepool {
                    if let data = try? encoder.encode(message) {
                        if !first { try? handle.write(contentsOf: Data(",\n".utf8)) }
                        try? handle.write(contentsOf: data)
                        first = false
                    }
                }
            }
        }

        try handle.write(contentsOf: Data("]".utf8))
    }

    func bulkInsertStress(count: Int, body: String) async throws {
        try await DB.dbQueue.write { db in
            try autoreleasepool {
                for k in 0..<count {
                    let message = Message(
                        id: UUID().uuidString, createDate: .now,
                        group: "\(k % 50)", title: "\(k) Test",
                        body: "\(body)", ttl: 1, read: true
                    )
                    try message.insert(db)
                }
            }
        }
    }

    // MARK: - Observation

    /// 观察 Message 表的 (未读数, 总数) 变化,产生 AsyncStream。
    func observeCounts() -> AsyncStream<(unread: Int, total: Int)> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> (Int, Int) in
                let unread = try Message.filter(Message.Columns.read == false).fetchCount(db)
                let total = try Message.fetchCount(db)
                return (unread, total)
            }

            let cancellable = observation.start(
                in: DB.dbQueue,
                scheduling: .async(onQueue: .global()),
                onError: { error in
                    logger.error("Failed to observe unread count: \(error)")
                    continuation.finish()
                },
                onChange: { response in
                    continuation.yield((unread: response.0, total: response.1))
                }
            )

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
