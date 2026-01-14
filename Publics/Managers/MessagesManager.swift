//
//  MessagesManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/26.
//
import Foundation
import GRDB

final class MessagesManager: ObservableObject {
    static let shared = MessagesManager()
    private let DB: DatabaseManager = .shared
    private let cache: DiskCache = .shared
    private var observationCancellable: AnyDatabaseCancellable?

    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 9_999_999
    @Published var updateSign: Int = 0
    @Published var groupMessages: [Message] = []
    @Published var messages: [Message] = []
    @Published var showGroupLoading: Bool = false

    let messagePage: Int = 50

    private var currentContent: String = ""

    func flush(_ data: String, stop: Bool = false) {
        
    }

    private init() {
        let messages = DiskCache.shared.get()
        groupMessages = messages
        if !Bundle.main.isAppExtension {
            startObservingUnreadCount()
        }
    }

    deinit { observationCancellable?.cancel() }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int, Int) in
            let unRead = try Message.filter(Message.Columns.isRead == false).fetchCount(db)
            let count = try Message.fetchCount(db)
            return (unRead, count)
        }

        observationCancellable = observation.start(
            in: DB.dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                logger.error("❌ Failed to observe unread count:\(error)")
            },
            onChange: { [weak self] newUnreadCount in
                logger.info("🧲: 监听 Message: \(newUnreadCount.0)-\(newUnreadCount.1)")
                guard let self else { return }
                DispatchQueue.main.async {
                    self.showGroupLoading = true
                    self.updateSign += 1
                    self.unreadCount = newUnreadCount.0
                    self.allCount = newUnreadCount.1
                }
                Task.detached(priority: .userInitiated) {
                    await self.updateGroup()
                }
            }
        )
    }

    func updateGroup() async {
        await MainActor.run {
            self.showGroupLoading = true
        }
        let results = await queryGroup()
        let count = await self.count()
        let unCount = await unreadCount()
        await MainActor.run { [weak self] in
            self?.groupMessages = results
            self?.updateSign += 1
            self?.allCount = count
            self?.unreadCount = unCount
            self?.showGroupLoading = false
        }
        DiskCache.shared.set(results)
    }
}

extension MessagesManager {
    nonisolated func all() async throws -> [Message] {
        try await DB.dbQueue.read { db in
            try Message.order(Message.Columns.createDate.desc).fetchAll(db)
        }
    }

    nonisolated func updateRead() async -> Int? {
        return try? await DB.dbQueue.write { db in
            // 批量更新 read 字段为 true
            try Message
                .filter(Message.Columns.isRead == false)
                .updateAll(db, [Message.Columns.isRead.set(to: true)])
        }
    }

    nonisolated func unreadCount(group: String? = nil) async -> Int {
        do {
            return try await DB.dbQueue.read { db in
                var request = Message.filter(Message.Columns.isRead == false)

                if let group = group {
                    request = request.filter(Message.Columns.group == group)
                }

                return try request.fetchCount(db)
            }
        } catch {
            logger.error("❌ 查询失败")
            return 0
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
            logger.error("❌ \(error)")
            return 0
        }
    }

    func add(_ message: Message) async {
        do {
            try await DB.dbQueue.write { db in
                try message.insert(db, onConflict: .replace)
            }
            var messages = cache.get().filter { $0.group != message.group }
            messages.insert(message, at: 0)
            cache.set(messages)
        } catch {
            logger.error("❌ Add or update message failed: \(error)")
        }
    }

    nonisolated func query(id: String) -> Message? {
        do {
            return try DB.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            logger.error("❌ Failed to query message by id: \(error)")
            return nil
        }
    }

    nonisolated func query(id: String) async -> Message? {
        do {
            return try await DB.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            logger.error("❌ Failed to query message by id: \(error)")
            return nil
        }
    }

    nonisolated func searchRequest(
        search: String,
        group: String? = nil,
        date: Date? = nil
    ) -> QueryInterfaceRequest<Message> {
        // 1. 分词，去掉空字符串
        let keywords = search
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var request = Message.order(Message.Columns.createDate.desc)

        // 2. 多关键词叠加 AND 条件
        for keyword in keywords {
            let escaped = keyword
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")

            let pattern = "%\(escaped)%"

            // 每个关键词作用在所有字段：用 OR
            let perKeywordFilter =
                Message.Columns.title.like(pattern)
                    || Message.Columns.subtitle.like(pattern)
                    || Message.Columns.body.like(pattern)
                    || Message.Columns.group.like(pattern)
                    || Message.Columns.url.like(pattern)

            // 每个关键词之间用 AND 累加
            request = request.filter(perKeywordFilter)
        }

        // 3. 附加其他过滤条件
        if let group = group {
            request = request.filter(Message.Columns.group == group)
        }

        if let date = date {
            request = request.filter(Message.Columns.createDate < date)
        }

        return request
    }

    nonisolated func query(
        search: String,
        group: String? = nil,
        limit lim: Int = 50,
        _ date: Date? = nil
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
            logger.error("❌ Query error: \(error)")
            return ([], 0)
        }
    }

    nonisolated func queryGroup() async -> [Message] {
        do {
            return try await DB.dbQueue.read { db in
                try self.fetchGroupedMessages(from: db)
            }
        } catch {
            logger.error("❌ Failed to query messages: \(error)")
            return []
        }
    }

    private nonisolated func fetchGroupedMessages(from db: Database) throws -> [Message] {
        let rows = try Row.fetchAll(db, sql: """
                SELECT m.*, unread.count AS unreadCount
                FROM (
                    SELECT *
                    FROM (
                        SELECT *,
                               ROW_NUMBER() OVER (PARTITION BY "group" ORDER BY createDate DESC, id DESC) AS rn
                        FROM message
                    )
                    WHERE rn = 1
                ) AS m
                LEFT JOIN (
                    SELECT "group", COUNT(*) AS count
                    FROM message
                    WHERE isRead = 0
                    GROUP BY "group"
                ) AS unread
                ON m."group" = unread."group"
                ORDER BY unread.count DESC NULLS LAST, m.createDate DESC
            """)

        return try rows.map { try Message(row: $0) }
    }

    nonisolated func query(
        group: String? = nil,
        limit lim: Int = 100,
        _ date: Date? = nil,
        function: String = #function
    ) async -> [Message] {
        let startTime = ContinuousClock.now // 记录开始时间

        do {
            let results = try await DB.dbQueue.read { db in
                var request = Message.order(Message.Columns.createDate.desc)
                if let group = group { request = request.filter(Message.Columns.group == group) }
                if let date = date { request = request.filter(Message.Columns.createDate < date) }
                return try request.limit(lim).fetchAll(db)
            }

            let endTime = ContinuousClock.now
            let duration = startTime.duration(to: endTime)

            // 打印结果，例如：0.015s
            logger.info("\(function)🔍 查询组 [\(group ?? "全部")] 耗时: \(duration)")

            return results
        } catch {
            logger.error("❌ Query failed: \(error)")
            return []
        }
    }

    nonisolated func markAllRead(group: String? = nil) async {
        do {
            try await DB.dbQueue.write { db in
                var request = Message.filter(Message.Columns.isRead == false)
                if let group = group {
                    request = request.filter(Message.Columns.group == group)
                }
                try request.updateAll(db, [Message.Columns.isRead.set(to: true)])
            }
        } catch {
            logger.error("❌ markAllRead error")
        }
    }

    nonisolated func delete(allRead: Bool = false, date: Date? = nil) async {
        do {
            try await DB.dbQueue.write { db in
                var request = Message.all()

                // 构建查询条件
                if allRead, let date = date {
                    request = request
                        .filter(Message.Columns.isRead == true)
                        .filter(Message.Columns.createDate < date)
                } else if allRead {
                    request = request.filter(Message.Columns.isRead == true)
                } else if let date = date {
                    request = request.filter(Message.Columns.createDate < date)
                } else {
                    return // 没有任何条件，不执行删除
                }

                try request.deleteAll(db)
            }

            try await DB.dbQueue.vacuum()

        } catch {
            logger.error("❌ 删除消息失败: \(error)")
        }
    }

    nonisolated func delete(_ message: Message, in group: Bool = false) async -> Int {
        do {
            if group {
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
            try? await DB.dbQueue.vacuum()
            return result
        } catch {
            logger.error("❌ 删除消息失败：\(error)")
        }
        return -1
    }

    nonisolated func delete(_ start: Date, end: Date) -> String {
        debugPrint(start.formatted(), end.formatted())
        return "success"
    }

    nonisolated func delete(_ messageID: String) -> String? {
        do {
            let result: String? = try DB.dbQueue.write { db in
                if let message = try Message.filter(Message.Columns.id == messageID).fetchOne(db) {
                    try message.delete(db)
                    return message.group
                }
                return nil
            }
            try? DB.dbQueue.vacuum()
            return result
        } catch {
            logger.error("❌ 删除消息失败：\(error)")
            return nil
        }
    }

    nonisolated func deleteExpired() async {
        do {
            try await DB.dbQueue.write { db in
                let now = Date()
                let cutoffDateExpr = now.addingTimeInterval(-1) // 当前时间

                // 删除逻辑：
                // ttl != forever（-1） 并且 createDate + ttl天 < now
                try db.execute(sql: """
                        DELETE FROM message
                        WHERE ttl != ?
                          AND datetime(createdate, '+' || ttl || ' days') < ?
                    """, arguments: [ExpirationTime.forever.rawValue, cutoffDateExpr])
            }
            try? await DB.dbQueue.vacuum()
        } catch {
            logger.error("❌ 删除失败: \(error)")
        }
    }

    static func ensureMarkdownLineBreaks(_ text: String) -> String {
        // 将文本按行分割
        let lines = text.components(separatedBy: .newlines)

        // 处理每一行：检查结尾是否已经有两个空格
        let processedLines = lines.map { line in
            if line.hasSuffix("  ") || line.isEmpty {
                return line
            } else {
                return line + "  " // 添加两个空格
            }
        }

        // 使用 \n 连接回去
        return processedLines.joined(separator: "\n")
    }

    static func createStressTest(
        max number: Int = 100_000,
        len textLength: Int = 600
    ) async -> Bool {
        do {
            let body = Self.generateRandomChineseText()

            try await shared.DB.dbQueue.write { db in
                try autoreleasepool {
                    for k in 0..<number {
                        let message = Message(
                            id: UUID().uuidString, createDate: .now,
                            group: "\(k % 10)", title: "\(k) Test",
                            body: "Text Data \(body)", level: 1, ttl: 1, isRead: true
                        )
                        try message.insert(db)
                    }
                }
            }
            return true
        } catch {
            logger.error("❌ 创建失败")
            return false
        }
    }

    static func generateRandomChineseText(_ approxBytes: Int = 500) -> String {
        // 常用汉字 Unicode 范围：0x4E00 ~ 0x9FA5
        let minCodePoint = 0x4E00
        let maxCodePoint = 0x9FA5

        var result = ""

        while result.utf8.count < approxBytes {
            let codePoint = Int.random(in: minCodePoint...maxCodePoint)
            if let scalar = UnicodeScalar(codePoint) {
                result.append(Character(scalar))
            }
        }

        return result
    }
}

final private class DiskCache: Sendable {
    static let shared = DiskCache()

    private let cacheDirectory: URL

    var fileURL: URL {
        cacheDirectory.appendingPathComponent("groupsKey".safeFileName, conformingTo: .data)
    }

    private init() {
        cacheDirectory = NCONFIG.getDir(.caches)!

        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    /// 保存缓存
    func set(_ messages: [Message]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // 格式化输出
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(messages)
            try data.write(to: fileURL)
        } catch {
            print("❌ DiskCache write error:", error)
        }
    }

    /// 读取缓存
    func get() -> [Message] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let messages = try decoder.decode([Message].self, from: data)
            return messages
        } catch {
            return []
        }
    }

    /// 删除缓存
    func remove() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

extension String {
    /// 将 key 转换为安全的文件名
    fileprivate var safeFileName: String {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self
    }
}

extension MessagesManager {
    // TODO: - 没有实现流式读取
    func importJSONFile(fileURL: URL) throws {
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

    // MARK: - 流式导出数据库到 JSON 文件

    func exportToJSONFile(fileURL: URL) throws {
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }

        try handle.write(contentsOf: Data("[".utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // 格式化输出
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
}
