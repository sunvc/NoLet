//
//  DatabaseManager.swift
//  NoLet
//
//  Core Data stack. Store lives in the App Group container so the app and
//  extensions share the file URL — but only the main app opens it.
//  Extensions persist incoming messages as plists in `pending_messages/`
//  (see PendingMessageStore); the app drains them into Core Data.
//

import CoreData
import Foundation

final class DatabaseManager: @unchecked Sendable {
    static let shared: DatabaseManager = {
        DatabaseManager()
    }()

    /// Incoming writes (extension-drained messages, upserts) win on conflict.
    nonisolated(unsafe) static let mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

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

        let modelURL = Bundle.main.url(forResource: "NoLet", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: "NoLet", managedObjectModel: model)

        let storeURL = NCONFIG.localContainer.appendingPathComponent("NoLet.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.setOption(
            FileProtectionType.completeUntilFirstUserAuthentication as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed: \(error)")
            }
            // FTS5 lives on the same SQLite file; set it up once the store is open.
            MessageFTS.shared.setup(storeURL: storeURL)
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = Self.mergePolicy
    }

    // MARK: - Context helpers
   
    func write<T>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
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
        let context = container.newBackgroundContext()
        return try await context.perform {
            try block(context)
        }
    }
}
