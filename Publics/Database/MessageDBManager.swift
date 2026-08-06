//
//  MessageDBManager.swift
//  NoLet
//

@preconcurrency import CoreData
import Foundation
import UIKit
import OSLog

extension Notification.Name {
    static let messageDBBulkDidChange = Notification.Name("messageDBBulkDidChange")
}

final class MessageDBManager: @unchecked Sendable {
    
    private let logger = Logger(subsystem: "app.wzs.logger", category: "MessageDBManager")
    
    static let shared = MessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    private var viewContext: NSManagedObjectContext { DB.viewContext }

    /// 持久化存储是否已就绪（无 store 时写操作会抛 Swift 错误而不是崩溃）。
    var hasStore: Bool { DB.hasStore }

    @MainActor
    var mainContext: NSManagedObjectContext { viewContext }

    // MARK: - 后台快照

    /// 一次后台查询拿到列表外的全部统计数据（总数、未读、分组头、分组未读）。
    /// 只回传 NSManagedObjectID 和标量，NSManagedObject 不跨线程。
    struct Snapshot: Sendable {
        var count: Int
        var unread: Int
        var groupHeadIDs: [NSManagedObjectID]
        var groupUnread: [String: Int]

        static let empty = Snapshot(count: 0, unread: 0, groupHeadIDs: [], groupUnread: [:])
    }

    func loadSnapshot() async -> Snapshot {
        (try? await DB.read { ctx in
            let total = (try? ctx.count(for: Self.request(predicate: nil))) ?? 0
            let unread = (try? ctx.count(for: Self.request(
                predicate: NSPredicate(format: "read == NO")
            ))) ?? 0

            let groupRequest = NSFetchRequest<NSDictionary>(entityName: MessageEntity.entityName)
            groupRequest.resultType = .dictionaryResultType
            groupRequest.returnsDistinctResults = true
            groupRequest.propertiesToFetch = ["group"]
            let groups = ((try? ctx.fetch(groupRequest)) ?? [])
                .compactMap { $0["group"] as? String }

            var heads: [(id: NSManagedObjectID, date: Date, textID: String)] = []
            heads.reserveCapacity(groups.count)
            for group in groups {
                let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
                request.predicate = NSPredicate(format: "group == %@", group)
                request.sortDescriptors = [
                    NSSortDescriptor(key: "createDate", ascending: false),
                    NSSortDescriptor(key: "id", ascending: false),
                ]
                request.fetchLimit = 1
                if let head = try? ctx.fetch(request).first {
                    heads.append((head.objectID, head.createDate ?? .distantPast, head.idText))
                }
            }
            heads.sort {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.textID > $1.textID
            }

            return Snapshot(
                count: total,
                unread: unread,
                groupHeadIDs: heads.map(\.id),
                groupUnread: try Self.unreadCountsByGroup(in: ctx)
            )
        }) ?? .empty
    }

    @MainActor
    func fetchOne(id: String) -> MessageEntity? {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    func count(group: String? = nil) async -> Int {
        nonisolated(unsafe) let predicate: NSPredicate? = group.map { NSPredicate(format: "group == %@", $0) }
        return (try? await DB.read { ctx in
            try ctx.count(for: Self.request(predicate: predicate))
        }) ?? 0
    }

    func count(before date: Date) async -> Int {
        (try? await DB.read { ctx in
            try ctx.count(for: Self.request(predicate: NSPredicate(
                format: "createDate < %@", date as NSDate
            )))
        }) ?? 0
    }

    func unreadCount(group: String? = nil) async -> Int {
        (try? await DB.read { ctx in
            try ctx.count(for: Self.request(predicate: Self.unreadPredicate(group: group)))
        }) ?? 0
    }

    func query(
        search: String,
        group: String? = nil,
        limit lim: Int = 50,
        before date: Date? = nil,
        beforeID: String? = nil
    ) async throws -> ([String], Int) {
        let keywords = search
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return ([], 0) }

        if MessageFTS.canFTS(keywords) {
            let pattern = MessageFTS.pattern(for: keywords)
            let ids = await MessageFTS.shared.search(
                pattern: pattern, group: group, limit: lim, before: date, beforeID: beforeID
            )
            if ids.isEmpty {
                return ([], await MessageFTS.shared.count(pattern: pattern, group: group))
            }
            let total = await MessageFTS.shared.count(pattern: pattern, group: group)
            return (ids, total)
        }

        let ids = await MessageFTS.shared.searchLike(
            keywords: keywords, group: group, limit: lim, before: date, beforeID: beforeID
        )
        let total = await MessageFTS.shared.countLike(keywords: keywords, group: group)
        return (ids, total)
    }

    @MainActor
    func entities(ids: [String]) -> [MessageEntity] {
        guard !ids.isEmpty else { return [] }
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "id IN %@", ids)
        request.returnsObjectsAsFaults = false
        let rows = (try? viewContext.fetch(request)) ?? []
        let byID = Dictionary(uniqueKeysWithValues: rows.map { ($0.idText, $0) })
        return ids.compactMap { byID[$0] }
    }

    // ponytail: 查询全部在后台 context 执行；NSFetchRequest 是 Sendable 值类型。
    private nonisolated static func unreadCountsByGroup(
        in ctx: NSManagedObjectContext
    ) throws -> [String: Int] {
        let countExp = NSExpressionDescription()
        countExp.name = "count"
        countExp.expression = NSExpression(
            forFunction: "count:",
            arguments: [NSExpression(forKeyPath: "id")]
        )
        countExp.expressionResultType = .integer64AttributeType

        let request = NSFetchRequest<NSDictionary>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "read == NO")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["group", countExp]
        request.propertiesToGroupBy = ["group"]

        var result: [String: Int] = [:]
        for row in try ctx.fetch(request) {
            if let g = row["group"] as? String,
               let n = row["count"] as? Int
            {
                result[g] = n
            }
        }
        return result
    }

    // MARK: - 写

    func upsert(_ payload: JSONMessage) async throws {
        guard let id = payload.value["id"] as? String else { return }
        try await DB.write { ctx in
            let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            let entity = try (ctx.fetch(request).first) ?? MessageEntity(context: ctx)
            entity.apply(jsonDictionary: payload.value)
        }
    }

    func markAllRead(group: String? = nil) async {
        let update = NSBatchUpdateRequest(entityName: MessageEntity.entityName)
        update.predicate = Self.unreadPredicate(group: group)
        update.propertiesToUpdate = ["read": true]
        update.resultType = .updatedObjectIDsResultType

        let updatedIDs: [NSManagedObjectID] = (try? await DB.write { ctx in
            let result = try ctx.execute(update) as? NSBatchUpdateResult
            return result?.result as? [NSManagedObjectID] ?? []
        }) ?? []

        if !updatedIDs.isEmpty {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSUpdatedObjectsKey: updatedIDs],
                into: [viewContext]
            )
        }
    }

    func delete(allRead: Bool = false, before date: Date? = nil) async {
        if !allRead, date == nil { return }
        try? await batchDelete(group: nil, onlyRead: allRead, before: date)
    }

    func delete(id: String, group: String, inGroup: Bool = false) async -> Int {
        if inGroup {
            try? await batchDelete(group: group, onlyRead: false, before: nil)
            return await count(group: group)
        }

        await MessageFTS.shared.deleteMessage(id: id)
        do {
            try await DB.write { ctx in
                if let entity = try Self.fetch(id: id, in: ctx) { ctx.delete(entity) }
            }
        } catch {
            logger.error("删除消息失败:\(error)")
            return -1
        }
        return await count(group: group)
    }

    func delete(id: String) async -> String? {
        await MessageFTS.shared.deleteMessage(id: id)
        do {
            return try await DB.write { ctx in
                guard let entity = try Self.fetch(id: id, in: ctx) else { return nil }
                let group = entity.groupText
                ctx.delete(entity)
                return group
            }
        } catch {
            logger.error("删除消息失败:\(error)")
            return nil
        }
    }

    func delete(beforeDate: Date) async throws {
        try await batchDelete(group: nil, onlyRead: false, before: beforeDate)
    }

    private func batchDelete(group: String?, onlyRead: Bool, before date: Date?) async throws {
        let bg = await MainActor.run {
            let box = BackgroundTaskBox()
            box.begin("message-bulk-delete")
            return box
        }
        do {
            var subs: [NSPredicate] = []
            if let group { subs.append(NSPredicate(format: "group == %@", group)) }
            if onlyRead { subs.append(NSPredicate(format: "read == YES")) }
            if let date { subs.append(NSPredicate(format: "createDate < %@", date as NSDate)) }
            let predicate = subs
                .isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: subs)

            let rebuildFTSAfter = (group == nil)
            if !rebuildFTSAfter {
                await MessageFTS.shared.deleteBulk(
                    group: group,
                    onlyRead: onlyRead,
                    before: date?.timeIntervalSinceReferenceDate
                )
            }

            nonisolated(unsafe) let p = predicate
            // ponytail: 收集被删 objectID 合并到 viewContext，让 @FetchRequest 精确刷新
            let deletedIDs: [NSManagedObjectID] = try await DB.write { ctx in
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: MessageEntity
                    .entityName)
                request.predicate = p
                let delete = NSBatchDeleteRequest(fetchRequest: request)

                delete.resultType = .resultTypeObjectIDs
                let result = try ctx.execute(delete) as? NSBatchDeleteResult
                return result?.result as? [NSManagedObjectID] ?? []
            }

            if rebuildFTSAfter {
                await MessageFTS.shared.rebuildAwait()
            }

            await MainActor.run {
                if !deletedIDs.isEmpty {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                        into: [viewContext]
                    )
                }
                NotificationCenter.default.post(name: .messageDBBulkDidChange, object: nil)
            }
        } catch {
            await MainActor.run { bg.end() }
            throw error
        }
        await MainActor.run { bg.end() }
    }

    func deleteExpired() async {
        let now = Int64(Date().timeIntervalSince1970)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "ttl > 0 AND ttl <= %d", now)
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        delete.resultType = .resultTypeObjectIDs

        do {
            let deletedIDs: [NSManagedObjectID] = try await DB.write { ctx in
                let result = try ctx.execute(delete) as? NSBatchDeleteResult
                return result?.result as? [NSManagedObjectID] ?? []
            }
            await MainActor.run {
                if !deletedIDs.isEmpty {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs],
                        into: [viewContext]
                    )
                }
                NotificationCenter.default.post(name: .messageDBBulkDidChange, object: nil)
            }
        } catch {
            NSLog("[MessageDB] deleteExpired failed: %@", error as NSError)
        }
    }

    // MARK: - Import / Export

    func importJSON(fileURL: URL) async throws {
        let data = try Data(contentsOf: fileURL)
        let results = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        nonisolated(unsafe) let items = results
        try await DB.write { ctx in
            for item in items {
                guard let id = item["id"] as? String else { continue }
                let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                let entity = try (ctx.fetch(request).first) ?? MessageEntity(context: ctx)
                entity.apply(jsonDictionary: item)
            }
        }
    }

    func exportJSON(fileURL: URL) async throws {
        let outputURL = fileURL
        try await DB.read { ctx in
            let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
            request.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
            let all = try ctx.fetch(request)

            FileManager.default.createFile(atPath: outputURL.path, contents: nil)
            let handle = try FileHandle(forWritingTo: outputURL)
            defer { try? handle.close() }

            try handle.write(contentsOf: Data("[".utf8))
            for (i, entity) in all.enumerated() {
                try autoreleasepool {
                    let data = try JSONSerialization.data(
                        withJSONObject: entity.jsonDictionary,
                        options: [.sortedKeys, .prettyPrinted]
                    )
                    if i > 0 { try handle.write(contentsOf: Data(",\n".utf8)) }
                    try handle.write(contentsOf: data)
                }
            }
            try handle.write(contentsOf: Data("]".utf8))
        }
    }

    func bulkInsertStress(count: Int, body: String) async throws {
        final class Counter { var k = 0 }
        let counter = Counter()
        let batch = NSBatchInsertRequest(
            entityName: MessageEntity.entityName,
            dictionaryHandler: { dict in
                let k = counter.k
                dict["id"] = UUID().uuidString

                dict["createDate"] = Date(timeIntervalSinceNow: -TimeInterval(k))
                dict["group"] = "\(k % 50)"
                dict["title"] = "\(k) Test"
                dict["body"] = body
                dict["ttl"] = Date().addingTimeInterval(600).timeIntervalSince1970
                dict["read"] = true
                counter.k += 1
                return counter.k >= count
            }
        )
        batch.resultType = .objectIDs

        nonisolated(unsafe) let request = batch
        let insertedIDs = try await DB.write { ctx -> [NSManagedObjectID] in
            let result = try ctx.execute(request) as? NSBatchInsertResult
            return result?.result as? [NSManagedObjectID] ?? []
        }
        if !insertedIDs.isEmpty {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSInsertedObjectsKey: insertedIDs],
                into: [viewContext]
            )
        }
        await MainActor.run {
            NotificationCenter.default.post(name: .messageDBBulkDidChange, object: nil)
        }
    }

    // MARK: - Helpers

    private nonisolated static func request(predicate: NSPredicate?)
        -> NSFetchRequest<MessageEntity>
    {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = predicate
        return request
    }

    private static func unreadPredicate(group: String?) -> NSPredicate {
        var subpredicates = [NSPredicate(format: "read == NO")]
        if let group {
            subpredicates.append(NSPredicate(format: "group == %@", group))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }

    private static func fetch(id: String, in ctx: NSManagedObjectContext) throws -> MessageEntity? {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }
}

struct JSONMessage: @unchecked Sendable {
    let value: [AnyHashable: Any]
    init(_ value: [AnyHashable: Any]) { self.value = value }
}

@MainActor
final private class BackgroundTaskBox {
    private let app = UIApplication.shared
    private var id: UIBackgroundTaskIdentifier = .invalid

    func begin(_ name: String) {
        id = app.beginBackgroundTask(withName: name) { [weak self] in
            Task { @MainActor in self?.end() }
        }
    }

    func end() {
        guard id != .invalid else { return }
        app.endBackgroundTask(id)
        id = .invalid
    }
}
