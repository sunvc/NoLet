//
//  MessagesManager.swift
//  NoLet
//
// History:
//    Created by Neo on 2025/5/26.
//
//  仅保留 @Published 状态、Darwin 通知桥接。
//  所有 DB 操作转发到 MessageDBManager；统计查询全部在后台 context 执行，
//  保存通知做防抖合并，避免消息多时插入一条就重查全表导致主线程卡顿。
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
    private var snapshotTask: Task<Void, Never>?

    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 0
    @Published var groupMessages: [MessageEntity] = []
    @Published var groupUnread: [String: Int] = [:]
    @Published var isDeleting: Bool = false
    let messagePage: Int = 50

    private init() {
        if !Bundle.main.bundlePath.hasSuffix(".appex") {
            startObservingChanges()
            setupDarwinListener()
            bulkObserver = NotificationCenter.default.addObserver(
                forName: .messageDBBulkDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    // reset()/批量操作后旧对象可能失效，立即清空再异步重建快照，
                    // 避免 SwiftUI 渲染无法兑现的 fault。
                    self?.groupMessages = []
                    self?.groupUnread = [:]
                    self?.scheduleSnapshot()
                }
            }
            Task {
                await applySnapshot(DB.loadSnapshot())
                await drainPendingMessages()
            }
        }
    }

    deinit {
        observationTask?.cancel()
        snapshotTask?.cancel()
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            CFNotificationName(NCONFIG.notificationName as CFString),
            nil
        )
    }

    // MARK: - Pending drain

    func drainPendingMessages() async {
        // 数据库未就绪时不要 drain（drain 会删除 plist），保留待处理消息，重置后再入。
        guard DB.hasStore else { return }

        if Defaults[.sharedUnreadCount] == 0 {
            await DB.markAllRead()
        }

        let items = pending.drain()
        if !items.isEmpty {
            for item in items {
                try? await DB.upsert(JSONMessage(item))
            }
            await DB.deleteExpired()
            await applySnapshot(DB.loadSnapshot())
        }
    }

    // MARK: - Observation

    private func startObservingChanges() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            let center = NotificationCenter.default
            let notifications = center.notifications(named: .NSManagedObjectContextDidSave)
            for await note in notifications {
                guard let self else { break }
                guard let userInfo = note.userInfo, Self.touchesMessage(userInfo) else { continue }
                await MainActor.run { self.scheduleSnapshot() }
            }
        }
    }

    /// 保存通知可能在批量插入时连续到达；合并到一个后台快照查询，
    /// ponytail: 0.25s 防抖，持续写入时每 0.25s 才刷新一次统计，而不是每条刷新。
    private func scheduleSnapshot() {
        snapshotTask?.cancel()
        snapshotTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled, let self else { return }
            let snapshot = await DB.loadSnapshot()
            guard !Task.isCancelled else { return }
            self.applySnapshot(snapshot)
        }
    }

    private func applySnapshot(_ snapshot: MessageDBManager.Snapshot) {
        allCount = snapshot.count
        unreadCount = snapshot.unread
        if Defaults[.sharedUnreadCount] != snapshot.unread {
            Defaults[.sharedUnreadCount] = snapshot.unread
        }
        let context = DB.mainContext
        groupMessages = snapshot.groupHeadIDs.compactMap { context.object(with: $0) as? MessageEntity }
        groupUnread = snapshot.groupUnread
    }

    nonisolated private static func touchesMessage(_ userInfo: [AnyHashable: Any]) -> Bool {
        for key in [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey] {
            if (userInfo[key] as? Set<NSManagedObject>)?
                .contains(where: { $0.entity.name == MessageEntity.entityName }) == true
            {
                return true
            }
        }
        return false
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
}

// MARK: - Forwarders to MessageDBManager

extension MessagesManager {
    func updateRead() async {
        await DB.markAllRead()
    }

    func unreadCount(group: String? = nil) async -> Int {
        await DB.unreadCount(group: group)
    }

    func count(group: String? = nil) async -> Int {
        await DB.count(group: group)
    }

    func count(before date: Date) async -> Int {
        await DB.count(before: date)
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
            return (DB.entities(ids: ids), total)
        } catch {
            logger.error("搜索失败: \(error)")
            return ([], 0)
        }
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
        if let id = userInfo.raw(.id, as: String.self),
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
    func importJSONFile(fileURL: URL) async throws {
        try await DB.importJSON(fileURL: fileURL)
    }

    func exportToJSONFile(fileURL: URL) async throws {
        try await DB.exportJSON(fileURL: fileURL)
    }
}

extension String {
    fileprivate var safeFileName: String {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self
    }
}
