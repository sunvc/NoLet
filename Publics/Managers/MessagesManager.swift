//
//  MessagesManager.swift
//  NoLet
//
// History:
//    Created by Neo on 2025/5/26.
//
//  仅保留 @Published 状态、group 缓存、Darwin 通知桥接。
//  所有 DB 操作转发到 MessageDBManager。列表直接持有 MessageEntity (NSManagedObject)。
//
import CoreData
import Foundation
import UserNotifications

@MainActor
final class MessagesManager: ObservableObject {
    static let shared = MessagesManager()
    private let DB: MessageDBManager = .shared
    private let pending = PendingMessageStore()

    private var observationTask: Task<Void, Never>?
    private var bulkObserver: NSObjectProtocol?

    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 9_999_999
    @Published var updateSign: Int = 0
    @Published var groupMessages: [MessageEntity] = []
    @Published var groupUnread: [String: Int] = [:]
    @Published var messages: [MessageEntity] = []
    @Published var isDeleting: Bool = false
    let messagePage: Int = 50

    private init() {
        if !Bundle.main.bundlePath.hasSuffix(".appex") {
            startObservingUnreadCount()
            setupDarwinListener()
            bulkObserver = NotificationCenter.default.addObserver(
                forName: .messageDBBulkDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.messages = []
                    self?.groupMessages = []
                }
            }
            Task { await drainPendingMessages() }
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


    func drainPendingMessages() async {

        if Defaults[.sharedUnreadCount] == 0 {
            await DB.markAllRead()
        }

        let items = pending.drain()
        if !items.isEmpty {
            for item in items {
                try? await DB.upsert(JSONMessage(item))
            }
            await DB.deleteExpired()
        }
        await refreshPublished()
    }

    private func startObservingUnreadCount() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let stream = self?.DB.observeCounts() else { return }
            for await value in stream {
                guard let self = self else { break }
                logger.info("🧲: 监听 Message: \(value.unread)-\(value.total)")
                self.updateSign += 1
                self.unreadCount = value.unread
                self.allCount = value.total
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
                let manager = Unmanaged<MessagesManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    await manager.drainPendingMessages()
                }
            },
            NCONFIG.notificationName as CFString,
            nil,
            .deliverImmediately
        )
    }

    func refreshPublished() async {
        let count = DB.count()
        let unCount = DB.unreadCount()
        allCount = count
        unreadCount = unCount
        // Keep the App Group counter in sync so extensions badge correctly.
        if Defaults[.sharedUnreadCount] != unCount {
            Defaults[.sharedUnreadCount] = unCount
        }
        groupMessages = DB.queryGroupHeads()
        groupUnread = DB.unreadCountsByGroup()
    }

    func updateGroup() async {
        await refreshPublished()
    }
}

// MARK: - Forwarders to MessageDBManager

extension MessagesManager {
    func updateRead() async -> Int {
        await DB.markUnreadAsRead()
    }

    func unreadCount(group: String? = nil) async -> Int {
        DB.unreadCount(group: group)
    }

    func count(group: String? = nil) async -> Int {
        DB.count(group: group)
    }

    func count(before date: Date) async -> Int {
        DB.count(before: date)
    }

    func add(_ json: [AnyHashable: Any]) async {
        do {
            try await DB.upsert(JSONMessage(json))
        } catch {
            logger.error("Add or update message failed: \(error)")
        }
    }

    func query(id: String) -> MessageEntity? {
        DB.fetchOne(id: id)
    }

    func query(
        search: String,
        group: String? = nil,
        limit lim: Int = 50,
        before date: Date? = nil,
        beforeID: String? = nil
    ) async -> ([MessageEntity], Int) {
        do {
            let (ids, total) = try await DB.query(
                search: search, group: group, limit: lim, before: date, beforeID: beforeID
            )
            // One preloaded page on the main context (returnsObjectsAsFaults=false),
            // so scrolling never fires per-row faults.
            return (DB.entities(ids: ids), total)
        } catch {
            logger.error("搜索失败: \(error)")
            return ([], 0)
        }
    }

    func queryGroup() async -> [MessageEntity] {
        DB.queryGroupHeads()
    }

    func query(
        group: String? = nil,
        limit lim: Int = 100,
        before date: Date? = nil,
        beforeID: String? = nil
    ) async -> [MessageEntity] {
        DB.query(group: group, limit: lim, before: date, beforeID: beforeID)
    }

    func markAllRead(group: String? = nil) async {
        await DB.markAllRead(group: group)
    }

    func delete(allRead: Bool = false, date: Date? = nil) async {
        isDeleting = true
        defer { isDeleting = false }
        await DB.delete(allRead: allRead, before: date)
    }

    func delete(_ message: MessageEntity, in group: Bool = false) async -> Int {
        await DB.delete(id: message.idText, group: message.groupText, inGroup: group)
    }

    func delete(id: String, group: String, in groupOnly: Bool = false) async -> Int {
        if groupOnly {
            isDeleting = true
        }
        let count = await DB.delete(id: id, group: group, inGroup: groupOnly)

        if groupOnly {
            isDeleting = false
        }

        return count
    }

    func delete(_ userInfo: [AnyHashable: Any]) async {
        if let id: String = userInfo.raw(.id),
           let group = await self.DB.delete(id: id)
        {
            UNUserNotificationCenter.current()
                .removeDeliveredNotifications(withIdentifiers: [group])
            return
        }
    }

    func deleteExpired() async {
        await DB.deleteExpired()
    }
}

// MARK: - Import / Export forwarders

extension MessagesManager {
    func importJSONFile(fileURL: URL) throws {
        try DB.importJSON(fileURL: fileURL)
    }

    func exportToJSONFile(fileURL: URL) throws {
        try DB.exportJSON(fileURL: fileURL)
    }
}

extension String {
    fileprivate var safeFileName: String {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self
    }
}
