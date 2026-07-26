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
//  仅保留 @Published 状态、group 缓存、Darwin 通知桥接。
//  所有 DB 操作转发到 MessageDBManager。
//
import Foundation
import GRDB

final class MessagesManager: ObservableObject {
    static let shared = MessagesManager()
    private let DB: MessageDBManager = .shared
    private let cache: MessageGroupCache = .shared

    private var observationTask: Task<Void, Never>?

    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 9_999_999
    @Published var updateSign: Int = 0
    @Published var groupMessages: [Message] = []
    @Published var messages: [Message] = []
    let messagePage: Int = 50

    private init() {
        groupMessages = MessageGroupCache.shared.get()
        if !Bundle.main.isAppExtension {
            startObservingUnreadCount()
            setupDarwinListener()
        }
    }

    deinit {
        observationTask?.cancel()
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            CFNotificationName(NCONFIG.notificationName as CFString),
            nil
        )
    }

    private func startObservingUnreadCount() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let stream = self?.DB.observeCounts() else { return }
            for await value in stream {
                guard let self = self else { break }
                logger.info("🧲: 监听 Message: \(value.unread)-\(value.total)")
                await MainActor.run {
                    self.updateSign += 1
                    self.unreadCount = value.unread
                    self.allCount = value.total
                }
                await self.updateGroup()
            }
        }
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

// MARK: - Forwarders to MessageDBManager

extension MessagesManager {
    nonisolated func updateRead() async -> Int {
        await MessageDBManager.shared.markUnreadAsRead()
    }

    nonisolated func unreadCount(group: String? = nil) async -> Int {
        await MessageDBManager.shared.unreadCount(group: group)
    }

    func count(group: String? = nil) async -> Int {
        await MessageDBManager.shared.count(group: group)
    }

    func add(_ message: Message) async {
        do {
            try await MessageDBManager.shared.upsert(message)
            cache.set(message)
        } catch {
            logger.error("Add or update message failed: \(error)")
        }
    }

    nonisolated func query(id: String) -> Message? {
        MessageDBManager.shared.fetchOneSync(id: id)
    }

    nonisolated func query(id: String) async -> Message? {
        await MessageDBManager.shared.fetchOne(id: id)
    }

    nonisolated func searchRequest(
        search: String,
        group: String? = nil,
        date: Date? = nil
    ) -> QueryInterfaceRequest<Message> {
        MessageDBManager.shared.searchRequest(search: search, group: group, date: date)
    }

    nonisolated func query(
        search: String,
        group: String? = nil,
        limit lim: Int = 50,
        _ date: Date? = nil
    ) async -> ([Message], Int) {
        await MessageDBManager.shared.query(search: search, group: group, limit: lim, before: date)
    }

    nonisolated func queryGroup() async -> [Message] {
        await MessageDBManager.shared.queryGroupHeads()
    }

    nonisolated func query(
        group: String? = nil,
        limit lim: Int = 100,
        _ date: Date? = nil,
        function: String = #function
    ) async -> [Message] {
        await MessageDBManager.shared.query(
            group: group,
            limit: lim,
            before: date,
            function: function
        )
    }

    nonisolated func markAllRead(group: String? = nil) async {
        await MessageDBManager.shared.markAllRead(group: group)
    }

    nonisolated func delete(allRead: Bool = false, date: Date? = nil) async {
        await MessageDBManager.shared.delete(allRead: allRead, before: date)
    }

    nonisolated func delete(_ message: Message, in group: Bool = false) async -> Int {
        await MessageDBManager.shared.delete(message, inGroup: group)
    }

    /// 同步删除 (保持原签名,内部转成同步等待)。
    nonisolated func delete(_ messageID: String) -> String? {
        final class Box: @unchecked Sendable { var value: String? }
        let box = Box()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached(priority: .userInitiated) {
            box.value = await MessageDBManager.shared.delete(id: messageID)
            semaphore.signal()
        }
        semaphore.wait()
        return box.value
    }

    nonisolated func deleteExpired() async {
        await MessageDBManager.shared.deleteExpired()
    }
}

// MARK: - Import / Export forwarders

extension MessagesManager {
    func importJSONFile(fileURL: URL) throws {
        try MessageDBManager.shared.importJSON(fileURL: fileURL)
    }

    func exportToJSONFile(fileURL: URL) throws {
        try MessageDBManager.shared.exportJSON(fileURL: fileURL)
    }
}

// MARK: - MessageGroupCache

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
