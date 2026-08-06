//
//  AudioMessageDBManager.swift
//  NoLet
//
//  AudioMessage 表的所有数据库操作。Core Data 实现，直接返回 AudioMessageEntity。
//

import CoreData
import Foundation
import SwiftUI

@MainActor
final class AudioMessageDBManager {
    static let shared = AudioMessageDBManager()
    private let DB: DatabaseManager = .shared
    private init() {}

    var viewContext: NSManagedObjectContext { DB.viewContext }

    // MARK: - 读

    func recentMessages(limit: Int = 50) -> [AudioMessageEntity] {
        let request = NSFetchRequest<AudioMessageEntity>(entityName: AudioMessageEntity.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        return (try? viewContext.fetch(request)) ?? []
    }

    func unread() -> [AudioMessageEntity] {
        let request = NSFetchRequest<AudioMessageEntity>(entityName: AudioMessageEntity.entityName)
        request.predicate = NSPredicate(format: "read == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }

    func fetchOne(id: String) -> AudioMessageEntity? {
        try? Self.fetch(id: id, in: viewContext)
    }

    // MARK: - 写
    func save(_ message: AudioMessageEntity) async throws {
        let payload = SendableAudio(
            id: message.id ?? UUID().uuidString,
            timestamp: message.timestamp ?? .now,
            channel: message.channel ?? "",
            from: message.from ?? "",
            file: message.file ?? "",
            url: message.url ?? "",
            read: message.read,
            sign: message.sign,
            status: Int(message.status)
        )
        try await DB.write { ctx in
            let request = NSFetchRequest<AudioMessageEntity>(entityName: AudioMessageEntity.entityName)
            request.predicate = NSPredicate(format: "id == %@", payload.id)
            request.fetchLimit = 1
            let entity = (try ctx.fetch(request).first) ?? AudioMessageEntity(context: ctx)
            entity.id = payload.id
            entity.timestamp = payload.timestamp
            entity.channel = payload.channel
            entity.from = payload.from
            entity.file = payload.file
            entity.url = payload.url
            entity.read = payload.read
            entity.sign = payload.sign
            entity.status = Int16(payload.status)
        }
    }

    func makeTransient(
        id: String = UUID().uuidString,
        timestamp: Date = .now,
        channel: String,
        from userID: String,
        file: String,
        url: String = "",
        read: Bool = false,
        sign: Bool = false,
        status: AudioMessageEntity.Status = .ready
    ) -> AudioMessageEntity {
        let entity = AudioMessageEntity(context: viewContext)
        entity.id = id
        entity.timestamp = timestamp
        entity.channel = channel
        entity.from = userID
        entity.file = file
        entity.url = url
        entity.read = read
        entity.sign = sign
        entity.statusValue = status
        return entity
    }

    func setStatus(
        id: String,
        read: Bool? = nil,
        status: AudioMessageEntity.Status? = nil
    ) async -> Bool {
        guard read != nil || status != nil else { return false }
        let statusValue = status?.rawValue
        do {
            return try await DB.write { ctx in
                guard let entity = try Self.fetch(id: id, in: ctx) else { return false }
                if let read { entity.read = read }
                if let statusValue { entity.status = Int16(statusValue) }
                return true
            }
        } catch {
            return false
        }
    }

    func deleteAll() async throws {
        try await DB.write { ctx in
            for entity in try ctx.fetch(NSFetchRequest<AudioMessageEntity>(entityName: AudioMessageEntity.entityName)) {
                ctx.delete(entity)
            }
        }
    }

    // MARK: - Observation

    func observeMessages() -> AsyncStream<[AudioMessageEntity]> {
        let center = NotificationCenter.default
        return AsyncStream { continuation in
            let emit: @Sendable () -> Void = {
                let ctx = DatabaseManager.shared.viewContext
                ctx.perform {
                    let request = NSFetchRequest<AudioMessageEntity>(entityName: AudioMessageEntity.entityName)
                    request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                    request.fetchLimit = 20
                    let messages = (try? ctx.fetch(request)) ?? []
                    continuation.yield(messages)
                }
            }
            let token = Observer(center.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: nil,
                queue: nil
            ) { note in
                guard let userInfo = note.userInfo else { return }
                let touches =
                    ((userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == AudioMessageEntity.entityName } == true)
                    || ((userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == AudioMessageEntity.entityName } == true)
                    || ((userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.contains { $0.entity.name == AudioMessageEntity.entityName } == true)
                guard touches else { return }
                emit()
            })
            emit()
            continuation.onTermination = { _ in center.removeObserver(token.wrapped) }
        }
    }

    // MARK: - Helpers

    nonisolated private static func fetch(id: String, in ctx: NSManagedObjectContext) throws -> AudioMessageEntity? {
        let request = NSFetchRequest<AudioMessageEntity>(entityName: AudioMessageEntity.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try ctx.fetch(request).first
    }
}

// MARK: - AudioMessageEntity helpers

extension AudioMessageEntity {
    enum Status: Int16 {
        case ready
        case send
        case success
        case failed

        var name: String {
            switch self {
            case .ready: return String(localized: "就绪")
            case .send: return String(localized: "发送中...")
            case .success: return String(localized: "发送成功")
            case .failed: return String(localized: "发送失败")
            }
        }

        var color: Color {
            switch self {
            case .ready: .blue
            case .send: .green
            case .success: .mint
            case .failed: .red
            }
        }
    }

    var statusValue: Status {
        get { Status(rawValue: status) ?? .ready }
        set { status = newValue.rawValue }
    }

    func filePath() -> URL? {
        guard let file else { return nil }
        return NCONFIG.Path(.ptt, file)
    }

    /// Parse a remote voice URL's filename into a transient entity.
    /// Caller must provide the view context.
    static func make(fromRemote address: URL, context: NSManagedObjectContext) -> AudioMessageEntity? {
        let fileName = address.deletingPathExtension().lastPathComponent
        let params = fileName.split(separator: "-").compactMap { String($0) }
        guard params.count == 4, let times = Int(params[3], radix: 32) else { return nil }

        let entity = AudioMessageEntity(context: context)
        entity.timestamp = Date(timeIntervalSince1970: TimeInterval(times) / 1000)
        entity.sign = params.first == "1"
        entity.from = params[2]
        entity.channel = params[1]
        entity.url = address.absoluteString
        entity.file = params[1...].joined(separator: "-") + "." + address.pathExtension
        entity.statusValue = .success
        return entity
    }
}

private final class Observer: @unchecked Sendable {
    let wrapped: any NSObjectProtocol
    init(_ wrapped: any NSObjectProtocol) { self.wrapped = wrapped }
}

private struct SendableAudio: @unchecked Sendable {
    let id: String
    let timestamp: Date
    let channel: String
    let from: String
    let file: String
    let url: String
    let read: Bool
    let sign: Bool
    let status: Int
}

#if DEBUG
extension AudioMessageDBManager {
    static var previewMessage: AudioMessageEntity {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let entity = AudioMessageEntity(context: context)
        entity.id = UUID().uuidString
        entity.timestamp = .now
        entity.channel = "923"
        entity.from = "123"
        entity.file = "file"
        entity.statusValue = .failed
        return entity
    }
}
#endif
