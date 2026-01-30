//
//  DatabaseManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/26.
//

import Foundation
import GRDB

final class DatabaseManager {
    static let shared: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Database init failed: \(error)")
        }
    }()

    let dbQueue: DatabaseQueue
    let localPath: URL
    let messageTabelName = "message"
    let chatGroupTabelName = "chatGroup"
    let chatMessageTabelName = "chatMessage"
    let chatPromptTabelName = "chatPrompt"

    private init() throws {
        localPath = CONTAINER.appendingPathComponent(NCONFIG.databaseName, conformingTo: .database)

        // DatabasePool 只在这里创建一次
        dbQueue = try DatabaseQueue(path: localPath.path)
        var migrator = DatabaseMigrator()
        registerMessageMigrations(&migrator)
        registerChatGroupMigrations(&migrator)
        registerChatMessageMigrations(&migrator)
        registerChatPromptMigrations(&migrator)
        try migrator.migrate(dbQueue)
    }

    func registerMessageMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("create_Message") { db in
            try db.create(table: self.messageTabelName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("group", .text).notNull()
                t.column("createDate", .datetime).notNull()
                t.column("title", .text)
                t.column("subtitle", .text)
                t.column("body", .text)
                t.column("icon", .text)
                t.column("url", .text)
                t.column("image", .text)
                t.column("from", .text)
                t.column("host", .text)
                t.column("level", .integer).notNull()
                t.column("ttl", .integer).notNull()
                t.column("read", .boolean).notNull()
                t.column("other", .text)
            }

            try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_message_createdate
                    ON message(createDate DESC)
                """)

            try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_message_group_createdate
                    ON message("group", createDate DESC)
                """)
        }
        migrator.registerMigration("rename_Message") { db in
            try db.alter(table: self.messageTabelName) { t in
                t.rename(column: "read", to: "isRead")
            }
        }
        
        migrator.registerMigration("add reply") { db in
            try db.alter(table: self.messageTabelName) { t in
                t.add(column: "reply", .text)
            }
        }
    }

    func registerChatGroupMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("create_chatGroup") { db in
            try db.create(table: self.chatGroupTabelName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .datetime).notNull()
                t.column("name", .text).notNull()
                t.column("host", .text).notNull()
                t.column("current", .boolean)
            }
        }

        migrator.registerMigration("add point") { db in
            try db.alter(table: self.chatGroupTabelName) { t in
                t.add(column: "point", .datetime)
            }
        }
    }

    func registerChatMessageMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("create_chatMessage") { db in
            try db.create(table: self.chatMessageTabelName, ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .datetime).notNull()
                t.column("chat", .text).notNull()
                t.column("request", .text).notNull()
                t.column("content", .text).notNull()
                t.column("message", .text)
            }
        }

        migrator.registerMigration("add result") { db in
            try db.alter(table: self.chatMessageTabelName) { t in
                t.add(column: "result", .jsonText)
            }
        }

        migrator.registerMigration("add reason") { db in
            try db.alter(table: self.chatMessageTabelName) { t in
                t.add(column: "reason", .text)
            }
        }
    }

    func registerChatPromptMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("create_chatPrompt") { db in
            try db.create(table: self.chatPromptTabelName, ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .datetime).notNull()
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("inside", .boolean).notNull()
            }
        }

        migrator.registerMigration("add mode") { db in
            try db.alter(table: self.chatPromptTabelName) { t in
                t.add(column: "mode", .text)
            }
        }
    }
}
