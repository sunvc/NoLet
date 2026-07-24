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
    private let cache: MessageGroupCache = .shared
    private var observationCancellable: AnyDatabaseCancellable?

    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 9_999_999
    @Published var updateSign: Int = 0
    @Published var groupMessages: [Message] = []
    @Published var messages: [Message] = []
    let messagePage: Int = 50

    private var currentContent: String = ""

    private init() {
        groupMessages = MessageGroupCache.shared.get()
        if !Bundle.main.isAppExtension {
            startObservingUnreadCount()
            setupDarwinListener()
        }
    }

    deinit {
        observationCancellable?.cancel()
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            CFNotificationName(NCONFIG.notificationName as CFString),
            nil
        )
    }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int, Int) in
            let unRead = try Message.filter(Message.Columns.read == false).fetchCount(db)
            let count = try Message.fetchCount(db)
            return (unRead, count)
        }

        observationCancellable = observation.start(
            in: DB.dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                logger.error("Failed to observe unread count:\(error)")
            },
            onChange: { [weak self] response in
                logger.info("🧲: 监听 Message: \(response.0)-\(response.1)")
                guard let self else { return }
                DispatchQueue.main.async {
                    self.updateSign += 1
                    self.unreadCount = response.0
                    self.allCount = response.1
                }
                Task.detached(priority: .userInitiated) {
                    await self.updateGroup()
                }
            }
        )
    }

    func setupDarwinListener() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let manager = Unmanaged<MessagesManager>.fromOpaque(
                    observer
                ).takeUnretainedValue()
                Task.detached(priority: .userInitiated) {
                    await manager.updateGroup()
                }
            },
            NCONFIG.notificationName as CFString,
            nil,
            .deliverImmediately
        )
    }

    func updateGroup() async {
        let count = await self.count()
        let unCount = await unreadCount()

        Task { @MainActor in
            self.allCount = count
            self.unreadCount = unCount
        }
        cache.set(await self.queryGroup())
        Task { @MainActor in
            self.groupMessages = cache.get()
        }
    }
}

extension MessagesManager {
    nonisolated func updateRead() async -> Int {
        return (try? await DB.dbQueue.write { db in
            // 批量更新 read 字段为 true
            try Message
                .filter(Message.Columns.read == false)
                .updateAll(db, [Message.Columns.read.set(to: true)])
        }) ?? 0
    }

    nonisolated func unreadCount(group: String? = nil) async -> Int {
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

    func add(_ message: Message) async {
        do {
            try await DB.dbQueue.write { db in
                try message.insert(db, onConflict: .replace)
            }
            cache.set(message)
        } catch {
            logger.error("Add or update message failed: \(error)")
        }
    }

    nonisolated func query(id: String) -> Message? {
        do {
            return try DB.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            logger.error("Failed to query message by id: \(error)")
            return nil
        }
    }

    nonisolated func query(id: String) async -> Message? {
        do {
            return try await DB.dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            logger.error("Failed to query message by id: \(error)")
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
            logger.error("Query error: \(error)")
            return ([], 0)
        }
    }

    nonisolated func queryGroup() async -> [Message] {
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
            logger.error("Query failed: \(error)")
            return []
        }
    }

    nonisolated func markAllRead(group: String? = nil) async {
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

    nonisolated func delete(allRead: Bool = false, date: Date? = nil) async {
        do {
            try await DB.dbQueue.write { db in
                var request = Message.all()

                // 构建查询条件
                if allRead, let date = date {
                    request = request
                        .filter(Message.Columns.read == true)
                        .filter(Message.Columns.createDate < date)
                } else if allRead {
                    request = request.filter(Message.Columns.read == true)
                } else if let date = date {
                    request = request.filter(Message.Columns.createDate < date)
                } else {
                    return // 没有任何条件，不执行删除
                }

                try request.deleteAll(db)
            }

        } catch {
            logger.error("删除消息失败: \(error)")
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

            return result
        } catch {
            logger.error("删除消息失败：\(error)")
        }
        return -1
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

            return result
        } catch {
            logger.error("删除消息失败：\(error)")
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

        } catch {
            logger.error("删除失败: \(error)")
        }
    }
}

extension MessagesManager {
    final nonisolated class MessageGroupCache: Sendable {
        static let shared = MessageGroupCache()

        private let cacheDirectory: URL

        let fileURL: URL

        private init() {
            cacheDirectory = NCONFIG.getDir(.caches)!
            try? FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
            fileURL = cacheDirectory.appendingPathComponent("groups.plist")
        }

        /// 保存缓存
        func set(_ data: Message) {
            let datas = self.get().filter { $0.group != data.group }
            self.set([data] + datas)
        }

        func set(_ datas: [Message]) {
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary
                let data = try encoder.encode(datas)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                logger.error("写入失败:\(error)")
            }
        }

        /// 读取缓存
        func get() -> [Message] {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = PropertyListDecoder()
                let datas = try decoder.decode([Message].self, from: data)
                return datas.sorted(by: { $0.createDate > $1.createDate })
            } catch {
                return []
            }
        }

        /// 删除缓存
        func remove() {
            try? FileManager.default.removeItem(at: fileURL)
        }
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
