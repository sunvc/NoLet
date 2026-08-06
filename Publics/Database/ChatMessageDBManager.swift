//
//  ChatMessageDBManager.swift
//  NoLet
//
//  ChatMessage 表的所有数据库操作。Core Data 实现，直接返回 ChatMessageEntity。
//

import CoreData
import Foundation

@MainActor
final class ChatMessageDBManager {
    static let shared = ChatMessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    private var viewContext: NSManagedObjectContext { DB.viewContext }

    // MARK: - 读

    func count(inGroup groupID: String) -> Int {
        (try? viewContext.count(for: Self.request(group: groupID))) ?? 0
    }

    func countSync(inGroup groupID: String) -> Int {
        (try? viewContext.count(for: Self.request(group: groupID))) ?? 0
    }

    func fetch(
        inGroup groupID: String,
        ascending: Bool = true,
        limit: Int
    ) -> [ChatMessageEntity] {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
        request.predicate = NSPredicate(format: "chat == %@", groupID)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: ascending)]
        request.fetchLimit = limit
        return (try? viewContext.fetch(request)) ?? []
    }

    func fetchHistory(
        groupID: String,
        after point: Date?,
        limit: Int
    ) -> [ChatMessageEntity] {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
        request.predicate = predicate(group: groupID, after: point)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        return (try? viewContext.fetch(request)) ?? []
    }

    func fetchHistorySync(
        groupID: String,
        after point: Date?,
        limit: Int
    ) -> [ChatMessageEntity] {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
        request.predicate = predicate(group: groupID, after: point)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        return ((try? viewContext.fetch(request)) ?? [])
    }

    // MARK: - 写

    /// Persist a transient ChatMessageEntity (created in the view context by the
    /// manager) into a background context, then refresh the view context.
    func insert(_ message: ChatMessageEntity) async throws {
        let payload = SendableChatMessage(
            id: message.id ?? UUID().uuidString,
            timestamp: message.timestamp ?? .now,
            chat: message.chat ?? "",
            role: message.role ?? "",
            content: message.content ?? "",
            message: message.message,
            reason: message.reason,
            result: message.resultJSON
        )
        try await DB.write { ctx in
            let request = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
            request.predicate = NSPredicate(format: "id == %@", payload.id)
            request.fetchLimit = 1
            let entity = (try ctx.fetch(request).first) ?? ChatMessageEntity(context: ctx)
            entity.id = payload.id
            entity.timestamp = payload.timestamp
            entity.chat = payload.chat
            entity.role = payload.role
            entity.content = payload.content
            entity.message = payload.message
            entity.reason = payload.reason
            entity.resultJSON = payload.result
        }
    }

    /// Creates a new transient ChatMessageEntity in the view context (not yet saved).
    /// The manager mutates it during streaming, then calls `insert(_:)` to persist.
    func makeTransient(
        id: String,
        timestamp: Date = .now,
        chat: String,
        role: String,
        content: String,
        message: String? = nil,
        reason: String? = nil,
        result: [String: String]? = nil
    ) -> ChatMessageEntity {
        let entity = ChatMessageEntity(context: viewContext)
        entity.id = id
        entity.timestamp = timestamp
        entity.chat = chat
        entity.role = role
        entity.content = content
        entity.message = message
        entity.reason = reason
        entity.resultJSON = result
        return entity
    }

    func deleteByGroup(_ groupID: String) async {
        try? await DB.write { ctx in
            let request = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
            request.predicate = NSPredicate(format: "chat == %@", groupID)
            for entity in try ctx.fetch(request) { ctx.delete(entity) }
        }
    }

    func deleteAll() async {
        try? await DB.write { ctx in
            for entity in try ctx.fetch(NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)) {
                ctx.delete(entity)
            }
        }
    }

    // MARK: - Observation

    func observeCount(inGroup groupID: String?) -> AsyncStream<Int> {
        let center = NotificationCenter.default
        return AsyncStream { continuation in
            let emit: @Sendable () -> Void = {
                let ctx = DatabaseManager.shared.viewContext
                ctx.perform {
                    let count = (try? ctx.count(for: Self.request(group: groupID))) ?? 0
                    continuation.yield(count)
                }
            }
            let token = Observer(center.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: nil,
                queue: nil
            ) { note in
                guard let userInfo = note.userInfo else { return }
                let touches =
                    ((userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == ChatMessageEntity.entityName } == true)
                    || ((userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == ChatMessageEntity.entityName } == true)
                    || ((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == ChatMessageEntity.entityName } == true)
                guard touches else { return }
                emit()
            })
            emit()
            continuation.onTermination = { _ in center.removeObserver(token.wrapped) }
        }
    }

    // MARK: - Helpers

    nonisolated private static func request(group: String?) -> NSFetchRequest<ChatMessageEntity> {
        let request = NSFetchRequest<ChatMessageEntity>(entityName: ChatMessageEntity.entityName)
        if let group {
            request.predicate = NSPredicate(format: "chat == %@", group)
        }
        return request
    }

    nonisolated private func predicate(group: String, after point: Date?) -> NSPredicate {
        var subpredicates = [NSPredicate(format: "chat == %@", group)]
        if let point {
            subpredicates.append(NSPredicate(format: "timestamp > %@", point as NSDate))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }
}

// MARK: - result JSON accessors

extension ChatMessageEntity {
    /// `result` is stored as a JSON string; expose it as a dictionary.
    var resultJSON: [String: String]? {
        get {
            guard let raw = result, let data = raw.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([String: String].self, from: data)
        }
        set {
            if let newValue,
               let data = try? JSONEncoder().encode(newValue),
               let raw = String(data: data, encoding: .utf8)
            {
                result = raw
            } else {
                result = nil
            }
        }
    }
}

private final class Observer: @unchecked Sendable {
    let wrapped: any NSObjectProtocol
    init(_ wrapped: any NSObjectProtocol) { self.wrapped = wrapped }
}

private struct SendableChatMessage: @unchecked Sendable {
    let id: String
    let timestamp: Date
    let chat: String
    let role: String
    let content: String
    let message: String?
    let reason: String?
    let result: [String: String]?
}
