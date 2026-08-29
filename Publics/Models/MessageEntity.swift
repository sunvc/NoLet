//
//  MessageEntity.swift
//  NoLet
//
//  Convenience extensions on the code-generated MessageEntity:
//  - direct JSON serialization (same field names), used by the notification
//    extension's pending inbox and by JSON import/export — no separate DTO,
//  - computed helpers (search/lifePercent/...) from the old Message struct.
//

import CoreData
import Foundation

extension MessageEntity {
    /// 列表/详情共用的拉取请求：按创建时间倒序，`fetchBatchSize` 让 Core Data
    /// 按 50 条一批物化行数据，避免长列表一次性读入内存。
    static func messageFetchRequest(predicate: NSPredicate? = nil) -> NSFetchRequest<MessageEntity> {
        let request = NSFetchRequest<MessageEntity>(entityName: entityName)
        request.sortDescriptors = [
            NSSortDescriptor(key: "createDate", ascending: false),
            NSSortDescriptor(key: "id", ascending: false),
        ]
        request.predicate = predicate
        request.fetchBatchSize = 50
        return request
    }

    /// A plain JSON dictionary ready to be written by the extension / PendingMessageStore.
    /// Dates are seconds-since-1970 to match the on-disk/export format.
    var jsonDictionary: [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        dict[.id] = id ?? UUID().uuidString
        dict[.createDate] = Int((createDate ?? .now).timeIntervalSince1970)
        dict[.group] = group ?? String(localized: "默认")
        dict[.body] = body ?? ""
        dict[.ttl] = Int64(ttl)
        dict[.read] = read
        if let title { dict[.title] = title }
        if let subtitle { dict[.subtitle] = subtitle }
        if let url { dict[.url] = url }
        if let style { dict[.style] = style }
        if let other { dict[.other] = other }
        return dict
    }

    /// Populates this entity from a JSON dictionary (as written by `jsonDictionary`
    /// or by the extension). Unknown / missing fields are left defaulted.
    @discardableResult
    func apply(jsonDictionary dict: [AnyHashable: Any]) -> MessageEntity {
        id = dict[.id] as? String ?? UUID().uuidString

        if let v = dict[.createDate] as? Double {
            createDate = Date(timeIntervalSince1970: v)
        } else if let v = dict[.createDate] as? Int64 {
            createDate = Date(timeIntervalSince1970: Double(v))
        } else {
            createDate = Date()
        }

        if let v = dict[.group] as? String {
            group = v
        } else {
            group = String(localized: "默认")
        }
        if let v = dict[.body] as? String { body = v }
        if let v = dict[.ttl] as? Int64 { ttl = v }
        if let v = dict[.read] as? Bool { read = v }
        title = dict[.title] as? String
        subtitle = dict[.subtitle] as? String
        url = dict[.url] as? String
        style = dict[.style] as? String
        other = dict[.other] as? String
        return self
    }

    // MARK: - Non-optional accessors

    var idText: String { id ?? UUID().uuidString }
    var groupText: String { group ?? String(localized: "默认") }
    var bodyText: String { body ?? "" }

    // MARK: - Computed helpers (moved from the old Message struct)

    var search: String {
        [group, title, subtitle, body, url]
            .lazy
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ";") + ";"
    }

    private var nowSeconds: TimeInterval { Date().timeIntervalSince1970 }

    var lifePercent: Double {
        guard ttl >= 0, let created = createDate else { return 1.0 } // -1 = permanent
        let total = Double(ttl) - created.timeIntervalSince1970
        guard total > 0 else { return 0.0 }
        return max(0.0, min(1.0, (Double(ttl) - nowSeconds) / total))
    }

    var otherDictionary: [String: Any]? {
        guard let otherData = other?.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: otherData) as? [String: Any]
    }

    func value<T>(for key: Params, as valueType: T.Type = String.self) -> T? {
        otherDictionary?[key.name] as? T
    }

    func value<T>(for key: String, as valueType: T.Type = String.self) -> T? {
        otherDictionary?[key] as? T
    }
}
extension MessageEntity {
    /// Preview-only: builds a MessageEntity from a JSON dictionary in memory.
    static func preview(_ dict: [AnyHashable: Any]) -> MessageEntity {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return MessageEntity(context: context).apply(jsonDictionary: dict)
    }
}
