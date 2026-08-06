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
    // MARK: - JSON (field names match the Core Data attributes)

    /// JSON keys mirror the entity attribute names exactly.
    enum JSONKey {
        static let id = "id"
        static let createDate = "createDate"
        static let group = "group"
        static let title = "title"
        static let subtitle = "subtitle"
        static let body = "body"
        static let icon = "icon"
        static let url = "url"
        static let image = "image"
        static let reply = "reply"
        static let ttl = "ttl"
        static let read = "read"
        static let style = "style"
        static let other = "other"
    }

    /// A plain JSON dictionary ready to be written by the extension / PendingMessageStore.
    /// Dates are seconds-since-1970 to match the on-disk/export format.
    var jsonDictionary: [String: Any] {
        var dict: [String: Any] = [
            JSONKey.id: id ?? "",
            JSONKey.createDate: Int((createDate ?? .now).timeIntervalSince1970),
            JSONKey.group: group ?? "",
            JSONKey.body: body ?? "",
            JSONKey.ttl: Int(ttl),
            JSONKey.read: read,
        ]
        if let title { dict[JSONKey.title] = title }
        if let subtitle { dict[JSONKey.subtitle] = subtitle }
        if let icon { dict[JSONKey.icon] = icon }
        if let url { dict[JSONKey.url] = url }
        if let image { dict[JSONKey.image] = image }
        if let reply { dict[JSONKey.reply] = reply }
        if let style { dict[JSONKey.style] = style }
        if let other { dict[JSONKey.other] = other }
        return dict
    }

    /// Populates this entity from a JSON dictionary (as written by `jsonDictionary`
    /// or by the extension). Unknown / missing fields are left defaulted.
    @discardableResult
    func apply(jsonDictionary dict: [AnyHashable: Any]) -> MessageEntity {
        if let v = dict[JSONKey.id] as? String { id = v }
        if let v = dict[JSONKey.createDate] as? Double { createDate = Date(timeIntervalSince1970: v) }
        else if let v = dict[JSONKey.createDate] as? Int { createDate = Date(timeIntervalSince1970: Double(v)) }
        if let v = dict[JSONKey.group] as? String { group = v }
        if let v = dict[JSONKey.body] as? String { body = v }
        if let v = dict[JSONKey.ttl] as? Int { ttl = Int64(v) }
        else if let v = dict[JSONKey.ttl] as? Int64 { ttl = v }
        if let v = dict[JSONKey.read] as? Bool { read = v }
        title = dict[JSONKey.title] as? String
        subtitle = dict[JSONKey.subtitle] as? String
        icon = dict[JSONKey.icon] as? String
        url = dict[JSONKey.url] as? String
        image = dict[JSONKey.image] as? String
        reply = dict[JSONKey.reply] as? String
        style = dict[JSONKey.style] as? String
        other = dict[JSONKey.other] as? String
        return self
    }

    // MARK: - Non-optional accessors

    var idText: String { id ?? "" }
    var groupText: String { group ?? "" }
    var bodyText: String { body ?? "" }

    // MARK: - Computed helpers (moved from the old Message struct)

    var search: String {
        [group, title, subtitle, body, url]
            .lazy
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ";") + ";"
    }

    private var elapsedSeconds: TimeInterval {
        Date().timeIntervalSince(createDate ?? .now)
    }

    var lifePercent: Double {
        guard ttl > 0 else { return 0.0 }
        return max(0.0, min(1.0, 1.0 - (elapsedSeconds / Double(ttl))))
    }

    var isExpired: Bool {
        elapsedSeconds > Double(ttl)
    }

    var otherDictionary: [String: Any]? {
        guard let otherData = other?.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: otherData) as? [String: Any]
    }

    func value<T>(for key: String, _ value: T) -> T {
        otherDictionary?[key] as? T ?? value
    }
}

#if DEBUG
extension MessageEntity {
    /// Preview-only: builds a MessageEntity from a JSON dictionary in memory.
    static func preview(_ dict: [AnyHashable: Any]) -> MessageEntity {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return MessageEntity(context: context).apply(jsonDictionary: dict)
    }
}
#endif
