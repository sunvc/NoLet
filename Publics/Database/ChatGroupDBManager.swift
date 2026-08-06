//
//  ChatGroupDBManager.swift
//  NoLet
//
//  ChatGroup 表的所有数据库操作。Core Data 实现，直接返回 ChatGroupEntity。
//

import CoreData
import Foundation

@MainActor
final class ChatGroupDBManager {
    static let shared = ChatGroupDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    private var viewContext: NSManagedObjectContext { DB.viewContext }

    // MARK: - 读

    func fetchCurrent() -> ChatGroupEntity? {
        try? Self.fetchCurrent(in: viewContext)
    }

    func fetchCurrentSync() -> ChatGroupEntity? {
        try? Self.fetchCurrent(in: viewContext)
    }

    func fetchAll() -> [ChatGroupEntity] {
        (try? viewContext.fetch(Self.request())) ?? []
    }

    func fetchOne(id: String) -> ChatGroupEntity? {
        try? Self.fetch(id: id, in: viewContext)
    }

    // MARK: - 写

    /// Inserts a new ChatGroupEntity from plain fields (used by the quote/reply flow).
    @discardableResult
    func insert(id: String, timestamp: Date = .now, name: String, host: String = "", current: Bool) async throws -> ChatGroupEntity {
        let payload = SendableGroup(id: id, timestamp: timestamp, name: name, host: host, current: current)
        return try await DB.write { ctx in
            if let existing = try Self.fetch(id: id, in: ctx) { return existing }
            try Self.setAllCurrent(false, except: id, in: ctx)
            let entity = ChatGroupEntity(context: ctx)
            entity.id = payload.id
            entity.timestamp = payload.timestamp
            entity.name = payload.name
            entity.host = payload.host
            entity.current = payload.current
            return entity
        }
    }

    func upsertQuoteGroup(id: String, name: String) async {
        do {
            try await DB.write { ctx in
                if (try Self.fetch(id: id, in: ctx)) != nil { return }
                try Self.setAllCurrent(false, except: id, in: ctx)
                let entity = ChatGroupEntity(context: ctx)
                entity.id = id
                entity.timestamp = .now
                entity.name = name
                entity.host = ""
                entity.current = true
            }
        } catch {
            logger.error("upsertQuoteGroup 失败: \(error)")
        }
    }

    func setCurrent(id targetID: String?) async {
        try? await DB.write { ctx in
            let request = NSFetchRequest<ChatGroupEntity>(entityName: ChatGroupEntity.entityName)
            if let targetID {
                request.predicate = NSPredicate(format: "id != %@", targetID)
            }
            for entity in try ctx.fetch(request) { entity.current = false }
            if let targetID, let entity = try Self.fetch(id: targetID, in: ctx) {
                entity.current = true
            }
        }
    }

    func setPointToNow(id: String) async -> Bool {
        do {
            return try await DB.write { ctx in
                guard let entity = try Self.fetch(id: id, in: ctx) else { return false }
                entity.point = Date()
                return true
            }
        } catch {
            return false
        }
    }

    func rename(id: String, newName: String, makeCurrent: Bool = false) async {
        try? await DB.write { ctx in
            if let entity = try Self.fetch(id: id, in: ctx) {
                entity.name = newName
                if makeCurrent { entity.current = true }
            }
        }
    }

    /// 级联：先删同 group 的 ChatMessage，再删 ChatGroup。
    func delete(id: String) async {
        try? await DB.write { ctx in
            let messages = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
            messages.predicate = NSPredicate(format: "chat == %@", id)
            for message in try ctx.fetch(messages) { ctx.delete(message) }
            if let group = try Self.fetch(id: id, in: ctx) { ctx.delete(group) }
        }
    }

    func deleteAll() async {
        try? await DB.write { ctx in
            for message in try ctx.fetch(NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)) {
                ctx.delete(message)
            }
            for group in try ctx.fetch(NSFetchRequest<ChatGroupEntity>(entityName: ChatGroupEntity.entityName)) {
                ctx.delete(group)
            }
        }
    }

    func deleteEmpty() async {
        try? await DB.write { ctx in
            for group in try ctx.fetch(Self.request()) {
                let count = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
                count.predicate = NSPredicate(format: "chat == %@", group.id ?? "")
                if (try? ctx.count(for: count)) == 0 { ctx.delete(group) }
            }
        }
    }

    // MARK: - Observation

    func observeSummary() -> AsyncStream<(groupsCount: Int, current: ChatGroupEntity?)> {
        let center = NotificationCenter.default
        return AsyncStream { continuation in
            let emit: @Sendable () -> Void = {
                let ctx = DatabaseManager.shared.viewContext
                ctx.perform {
                    let all = (try? ctx.fetch(Self.request())) ?? []
                    continuation.yield((groupsCount: all.count, current: all.first { $0.current }))
                }
            }
            let token = Observer(center.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: nil,
                queue: nil
            ) { note in
                guard let userInfo = note.userInfo else { return }
                let touches =
                    ((userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == ChatGroupEntity.entityName } == true)
                    || ((userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == ChatGroupEntity.entityName } == true)
                    || ((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == ChatGroupEntity.entityName } == true)
                guard touches else { return }
                emit()
            })
            emit()
            continuation.onTermination = { _ in center.removeObserver(token.wrapped) }
        }
    }

    // MARK: - Helpers

    nonisolated private static func request() -> NSFetchRequest<ChatGroupEntity> {
        let request = NSFetchRequest<ChatGroupEntity>(entityName: ChatGroupEntity.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }

    nonisolated private static func fetchCurrent(in ctx: NSManagedObjectContext) throws -> ChatGroupEntity? {
        let request = NSFetchRequest<ChatGroupEntity>(entityName: ChatGroupEntity.entityName)
        request.predicate = NSPredicate(format: "current == YES")
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }

    nonisolated private static func fetch(id: String, in ctx: NSManagedObjectContext) throws -> ChatGroupEntity? {
        let request = NSFetchRequest<ChatGroupEntity>(entityName: ChatGroupEntity.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }

    nonisolated private static func setAllCurrent(_ value: Bool, except id: String?, in ctx: NSManagedObjectContext) throws {
        let request = NSFetchRequest<ChatGroupEntity>(entityName: ChatGroupEntity.entityName)
        if let id {
            request.predicate = NSPredicate(format: "id != %@", id)
        }
        for entity in try ctx.fetch(request) { entity.current = value }
    }
}

private final class Observer: @unchecked Sendable {
    let wrapped: any NSObjectProtocol
    init(_ wrapped: any NSObjectProtocol) { self.wrapped = wrapped }
}

/// Sendable payload for cross-actor group creation.
private struct SendableGroup: @unchecked Sendable {
    let id: String
    let timestamp: Date
    let name: String
    let host: String
    let current: Bool
}
