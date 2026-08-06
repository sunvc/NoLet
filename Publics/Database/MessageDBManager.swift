//
//  MessageDBManager.swift
//  NoLet
//

@preconcurrency import CoreData
import Foundation
import UIKit

extension Notification.Name {
    static let messageDBBulkDidChange = Notification.Name("messageDBBulkDidChange")
}

final class MessageDBManager: @unchecked Sendable {
    static let shared = MessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    private var viewContext: NSManagedObjectContext { DB.viewContext }

    @MainActor
    func fetchOne(id: String) -> MessageEntity? {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    @MainActor
    func count(group: String? = nil) -> Int {
        let predicate: NSPredicate? = group.map { NSPredicate(format: "group == %@", $0) }
        return (try? viewContext.count(for: Self.request(predicate: predicate))) ?? 0
    }

    @MainActor
    func count(before date: Date) -> Int {
        (try? viewContext.count(for: Self.request(predicate: NSPredicate(
            format: "createDate < %@",
            date as NSDate
        )))) ?? 0
    }

    @MainActor
    func unreadCount(group: String? = nil) -> Int {
        var subpredicates = [NSPredicate(format: "read == NO")]
        if let group {
            subpredicates.append(NSPredicate(format: "group == %@", group))
        }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        return (try? viewContext.count(for: Self.request(predicate: predicate))) ?? 0
    }

    /// Unread counts for every group in one GROUP BY query — replaces per-row COUNT
    /// queries that fired as each MessageRow appeared during scrolling.
    @MainActor
    func unreadCountsByGroup() -> [String: Int] {
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
        for row in (try? viewContext.fetch(request)) ?? [] {
            if let g = row["group"] as? String,
               let n = row["count"] as? Int
            {
                result[g] = n
            }
        }
        return result
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

    @MainActor
    func queryGroupHeads() -> [MessageEntity] {
        let groupRequest = NSFetchRequest<NSDictionary>(entityName: MessageEntity.entityName)
        groupRequest.resultType = .dictionaryResultType
        groupRequest.returnsDistinctResults = true
        groupRequest.propertiesToFetch = ["group"]
        let groups = ((try? viewContext.fetch(groupRequest)) ?? [])
            .compactMap { $0["group"] as? String }

        var heads: [MessageEntity] = []
        heads.reserveCapacity(groups.count)

        for group in groups {
            let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
            request.predicate = NSPredicate(format: "group == %@", group)
            request.sortDescriptors = [
                NSSortDescriptor(key: "createDate", ascending: false),
                NSSortDescriptor(key: "id", ascending: false),
            ]
            request.fetchLimit = 1

            request.returnsObjectsAsFaults = false
            if let head = try? viewContext.fetch(request).first {
                heads.append(head)
            }
        }

        return heads.sorted {
            if $0.createDate != $1.createDate {
                return ($0.createDate ?? .distantPast) > ($1.createDate ?? .distantPast)
            }
            return $0.idText > $1.idText
        }
    }

    @MainActor
    func query(
        group: String? = nil,
        limit lim: Int = 100,
        before date: Date? = nil,
        beforeID: String? = nil
    ) -> [MessageEntity] {
        let basePredicate = group.map { NSPredicate(format: "group == %@", $0) }
        let predicate = pagePredicate(base: basePredicate, before: date, beforeID: beforeID)
        return (try? fetchEntities(predicate: predicate, limit: lim, in: viewContext)) ?? []
    }

    private nonisolated func fetchEntities(
        predicate: NSPredicate?,
        limit: Int?,
        in ctx: NSManagedObjectContext
    ) throws -> [MessageEntity] {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = predicate

        request.returnsObjectsAsFaults = false

        request.sortDescriptors = [
            NSSortDescriptor(key: "createDate", ascending: false),
            NSSortDescriptor(key: "id", ascending: false),
        ]
        if let limit { request.fetchLimit = limit }
        return try ctx.fetch(request)
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
        try? await DB.write { ctx in
            try Self.fetch(predicate: Self.unreadPredicate(group: group), in: ctx)
                .forEach { $0.read = true }
        }
    }

    @MainActor
    func markUnreadAsRead() async -> Int {
        let count = unreadCount()
        await markAllRead()
        return count
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

        MessageFTS.shared.deleteMessage(id: id)
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
        MessageFTS.shared.deleteMessage(id: id)
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
                MessageFTS.shared.deleteBulk(
                    group: group,
                    onlyRead: onlyRead,
                    before: date?.timeIntervalSinceReferenceDate
                )
            }

            nonisolated(unsafe) let p = predicate
            try await DB.write { ctx in
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: MessageEntity
                    .entityName)
                request.predicate = p
                let delete = NSBatchDeleteRequest(fetchRequest: request)

                delete.resultType = .resultTypeStatusOnly
                try ctx.execute(delete)
            }

            if rebuildFTSAfter {
                await MessageFTS.shared.rebuildAwait()
            }

            await MainActor.run {
                viewContext.reset()
                NotificationCenter.default.post(name: .messageDBBulkDidChange, object: nil)
            }
        } catch {
            await MainActor.run { bg.end() }
            throw error
        }
        await MainActor.run { bg.end() }
    }

    func deleteExpired() async {
        let now = Date()
        try? await DB.write { ctx in
            let survivors = try Self.fetch(
                predicate: NSPredicate(format: "ttl != %d", ExpirationTime.forever.rawValue),
                in: ctx
            )
            for entity in survivors
                where (entity.createDate ?? .now)
                .addingTimeInterval(TimeInterval(entity.ttl)) < now
            {
                ctx.delete(entity)
            }
        }
    }

    // MARK: - Import / Export

    @MainActor
    func importJSON(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let results = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        for item in results {
            guard let id = item["id"] as? String else { continue }
            let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            let entity = try (viewContext.fetch(request).first) ??
                MessageEntity(context: viewContext)
            entity.apply(jsonDictionary: item)
        }
        try viewContext.save()
    }

    @MainActor
    func exportJSON(fileURL: URL) throws {
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }

        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        let all = (try? viewContext.fetch(request)) ?? []
        try handle.write(contentsOf: Data("[".utf8))
        var first = true
        for entity in all {
            try autoreleasepool {
                let data = try JSONSerialization.data(
                    withJSONObject: entity.jsonDictionary,
                    options: [.sortedKeys, .prettyPrinted]
                )
                if !first { try handle.write(contentsOf: Data(",\n".utf8)) }
                try handle.write(contentsOf: data)
                first = false
            }
        }
        try handle.write(contentsOf: Data("]".utf8))
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
                dict["ttl"] = 1
                dict["read"] = true
                counter.k += 1
                return counter.k >= count
            }
        )
        batch.resultType = .statusOnly

        nonisolated(unsafe) let request = batch
        _ = try await DB.write { ctx in
            try ctx.execute(request)
        }
        await MainActor.run {
            viewContext.refreshAllObjects()
            NotificationCenter.default.post(name: .messageDBBulkDidChange, object: nil)
        }
    }

    // MARK: - Observation

    func observeCounts() -> AsyncStream<(unread: Int, total: Int)> {
        let center = NotificationCenter.default
        return AsyncStream { continuation in
            let emit: @Sendable () -> Void = {
                let ctx = DatabaseManager.shared.viewContext
                ctx.perform {
                    let total = (try? ctx.count(for: Self.request(predicate: nil))) ?? 0
                    let unread = (try? ctx.count(for: Self.request(
                        predicate: NSPredicate(format: "read == NO")
                    ))) ?? 0
                    continuation.yield((unread: unread, total: total))
                }
            }
            let token = Observer(center.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: nil,
                queue: nil
            ) { note in
                guard let userInfo = note.userInfo else { return }
                guard Self.touchesMessage(userInfo) else { return }
                emit()
            })

            let bulkToken = Observer(center.addObserver(
                forName: .messageDBBulkDidChange,
                object: nil,
                queue: nil
            ) { _ in emit() })
            emit()
            continuation.onTermination = { _ in
                center.removeObserver(token.wrapped)
                center.removeObserver(bulkToken.wrapped)
            }
        }
    }

    // MARK: - Helpers

    private static func touchesMessage(_ userInfo: [AnyHashable: Any]) -> Bool {
        for key in [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey] {
            if (userInfo[key] as? Set<NSManagedObject>)?
                .contains(where: { $0.entity.name == MessageEntity.entityName }) == true
            {
                return true
            }
        }
        return false
    }

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

    private static func fetch(
        predicate: NSPredicate,
        in ctx: NSManagedObjectContext
    ) throws -> [MessageEntity] {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = predicate
        return try ctx.fetch(request)
    }

    private static func fetch(id: String, in ctx: NSManagedObjectContext) throws -> MessageEntity? {
        let request = NSFetchRequest<MessageEntity>(entityName: MessageEntity.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }

    @inline(__always)
    private nonisolated func pagePredicate(
        base: NSPredicate?,
        before date: Date?,
        beforeID id: String?
    ) -> NSPredicate? {
        guard let date, let id else { return base }
        let cursor = NSPredicate(
            format: "(createDate < %@) OR (createDate == %@ AND id < %@)",
            date as NSDate, date as NSDate, id
        )
        if let base {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [base, cursor])
        }
        return cursor
    }
}

final private class Observer: @unchecked Sendable {
    let wrapped: any NSObjectProtocol
    init(_ wrapped: any NSObjectProtocol) { self.wrapped = wrapped }
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
