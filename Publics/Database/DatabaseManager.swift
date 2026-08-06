//
//  DatabaseManager.swift
//  NoLet
//
//  Core Data stack. Store lives in the App Group container so the app and
//  extensions share the file URL — but only the main app opens it.
//  Extensions persist incoming messages as plists in `pending_messages/`
//  (see PendingMessageStore); the app drains them into Core Data.
//

import Combine
import CoreData
import Foundation
import OSLog

enum DatabaseError: Error, LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        String(localized: "数据库未就绪，请重置后重试")
    }
}

final class DatabaseManager: ObservableObject, @unchecked Sendable {
    static let shared: DatabaseManager = {
        DatabaseManager()
    }()

    private static let logger = Logger(subsystem: "app.wzs.logger", category: "DatabaseManager")

    /// Incoming writes (extension-drained messages, upserts) win on conflict.
    nonisolated(unsafe) static let mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    /// 非 nil 表示持久化存储加载失败（数据库损坏等）。UI 应提示用户重置。
    @MainActor @Published var storeLoadError: String?
    @MainActor @Published var isResetting = false
    /// 重置成功后置 true，提示用户退出重开（内存中的旧 NSManagedObject 已全部失效）。
    @MainActor @Published var needsRestart = false

    private let storeURL: URL
    private let storeDescription: NSPersistentStoreDescription
    private let storeLock = NSLock()
    private var _hasStore = false

    /// coordinator 当前是否挂载了存储。无存储时写入会抛 ObjC 异常（Swift 无法捕获），
    /// 所以所有 write/read 入口必须先检查此标志。
    var hasStore: Bool {
        storeLock.lock()
        defer { storeLock.unlock() }
        return _hasStore
    }

    private func setHasStore(_ value: Bool) {
        storeLock.lock()
        _hasStore = value
        storeLock.unlock()
    }

    private init() {
        // One-time cleanup of the legacy GRDB store (no migration, fresh Core Data start).
        if !Defaults[.didMigrateFromGRDB] {
            let fm = FileManager.default
            let name = NCONFIG.databaseName
            if let files = try? fm.contentsOfDirectory(at: NCONFIG.localContainer, includingPropertiesForKeys: nil) {
                for url in files where url.lastPathComponent.hasPrefix(name) {
                    try? fm.removeItem(at: url)
                }
            }
            Defaults[.didMigrateFromGRDB] = true
        }

        let modelURL = Bundle.main.url(forResource: NCONFIG.appSymbol, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: NCONFIG.appSymbol, managedObjectModel: model)

        storeURL = NCONFIG.localContainer.appendingPathComponent("\(NCONFIG.appSymbol).sqlite")
        storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.setOption(
            FileProtectionType.completeUntilFirstUserAuthentication as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { [storeURL, weak self] _, error in
            if let error {
                Self.logger.error("Core Data store failed to load: \(error as NSError)")
                let message = error.localizedDescription
                Task { @MainActor in
                    DatabaseManager.shared.storeLoadError = message
                }
                return
            }
            self?.setHasStore(true)
            // FTS5 lives on the same SQLite file; set it up once the store is open.
            MessageFTS.shared.setup(storeURL: storeURL)
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = Self.mergePolicy
    }

    // MARK: - Context helpers

    @discardableResult
    func write<T>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        guard hasStore else { throw DatabaseError.storeUnavailable }
        let context = container.newBackgroundContext()
        context.mergePolicy = Self.mergePolicy
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges {
                try context.save()
            }
            return result
        }
    }

    func read<T>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        guard hasStore else { throw DatabaseError.storeUnavailable }
        let context = container.newBackgroundContext()
        return try await context.perform {
            try block(context)
        }
    }

    // MARK: - Recovery

    /// 删除损坏的数据库文件并重新挂载空存储。成功后所有内存中的 NSManagedObject
    /// 都会失效，UI 会通过 @FetchRequest / 通知自动重建。
    @MainActor
    func resetStore() async throws {
        isResetting = true
        defer { isResetting = false }

        // 先关掉 FTS 的原生 sqlite 句柄，否则它会占用旧文件。
        await MessageFTS.shared.close()

        let coordinator = container.persistentStoreCoordinator
        let url = storeURL
        let description = storeDescription

        try await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            for store in coordinator.persistentStores {
                try? coordinator.remove(store)
            }
            self.setHasStore(false)

            // 销毁前备份原始文件（含 -wal/-shm），供数据抢救使用
            let backupDir = NCONFIG.localContainer
                .appendingPathComponent("database_backups", isDirectory: true)
            let timestamp = ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
            let backupStore = backupDir
                .appendingPathComponent("\(timestamp).sqlite")
            try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
            for ext in ["sqlite", "sqlite-wal", "sqlite-shm"] {
                let src = url.deletingPathExtension().appendingPathExtension(ext)
                guard fm.fileExists(atPath: src.path) else { continue }
                let dst = backupStore.deletingPathExtension().appendingPathExtension(ext)
                try? fm.copyItem(at: src, to: dst)
            }
            // 只保留最近 5 份备份
            if let backups = try? fm.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) {
                let old = backups
                    .filter { $0.pathExtension == "sqlite" }
                    .sorted {
                        let d0 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey])
                            .contentModificationDate) ?? .distantPast
                        let d1 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey])
                            .contentModificationDate) ?? .distantPast
                        return d0 > d1
                    }
                    .dropFirst(5)
                for file in old {
                    let base = file.deletingPathExtension()
                    for ext in ["sqlite", "sqlite-wal", "sqlite-shm"] {
                        try? fm.removeItem(at: base.appendingPathExtension(ext))
                    }
                }
            }

            // Core Data 会删掉 sqlite、-wal、-shm 等全部关联文件
            try coordinator.destroyPersistentStore(
                at: url,
                ofType: NSSQLiteStoreType,
                options: description.options
            )

            // 同时清掉 PTT 语音文件（数据库引用会一起丢失）
            if let pttDir = NCONFIG.Path(.ptt) {
                try? fm.removeItem(at: pttDir)
            }

            // 重新挂载一个全新的空存储
            _ = try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: url,
                options: description.options
            )
            self.setHasStore(true)
        }.value

        viewContext.reset()
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = Self.mergePolicy

        MessageFTS.shared.setup(storeURL: storeURL)

        storeLoadError = nil
        // 不直接继续运行：内存中所有旧 NSManagedObject 已随 destroy 失效，继续使用
        // 可能触发 "could not fulfill fault" 异常。提示用户退出重开最安全。
        needsRestart = true
    }
}
