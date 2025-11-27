//
//  MessageModel.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/26.
//
import Foundation
import GRDB

struct Message: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var group: String
    var createDate: Date
    var title: String?
    var subtitle: String?
    var body: String?
    var icon: String?
    var url: String?
    var image: String?
    var from: String?
    var host: String?
    var level: Int
    var ttl: Int
    var read: Bool
    var other: String?

    enum Columns {
        static let id = Column(CodingKeys.id.lows)
        static let group = Column(CodingKeys.group.lows)
        static let createDate = Column(CodingKeys.createDate.lows)
        static let title = Column(CodingKeys.title.lows)
        static let subtitle = Column(CodingKeys.subtitle.lows)
        static let body = Column(CodingKeys.body.lows)
        static let icon = Column(CodingKeys.icon.lows)
        static let url = Column(CodingKeys.url.lows)
        static let image = Column(CodingKeys.image.lows)
        static let from = Column(CodingKeys.from.lows)
        static let host = Column(CodingKeys.host.lows)
        static let level = Column(CodingKeys.level.lows)
        static let ttl = Column(CodingKeys.ttl.lows)
        static let read = Column(CodingKeys.read.lows)
        static let other = Column(CodingKeys.other.lows)
    }
}

extension Message {
    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "message", ifNotExists: true) { t in
                t.primaryKey(CodingKeys.id.lows, .text)
                t.column(CodingKeys.group.lows, .text).notNull()
                t.column(CodingKeys.createDate.lows, .datetime).notNull()
                t.column(CodingKeys.title.lows, .text)
                t.column(CodingKeys.subtitle.lows, .text)
                t.column(CodingKeys.body.lows, .text)
                t.column(CodingKeys.icon.lows, .text)
                t.column(CodingKeys.url.lows, .text)
                t.column(CodingKeys.image.lows, .text)
                t.column(CodingKeys.from.lows, .text)
                t.column(CodingKeys.host.lows, .text)
                t.column(CodingKeys.level.lows, .integer).notNull()
                t.column(CodingKeys.ttl.lows, .integer).notNull()
                t.column(CodingKeys.read.lows, .boolean).notNull()
                t.column(CodingKeys.other.lows, .text)
            }

            try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_message_createdate
                    ON message(createdate DESC)
                """)

            try db.execute(sql: """
                    CREATE INDEX IF NOT EXISTS idx_message_group_createdate
                    ON message("group", createdate DESC)
                """)
        }
    }

    var search: String {
        [group, title, subtitle, body, from, url].compactMap { $0 }.filter { !$0.isEmpty }
            .joined(separator: ";") + ";"
    }
}

struct ChatGroup: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Equatable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var name: String
    var host: String

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
    }

    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "chatGroup", ifNotExists: true) { t in
                t.primaryKey(CodingKeys.id.lows, .text)
                t.column(CodingKeys.timestamp.lows, .datetime).notNull()
                t.column(CodingKeys.name.lows, .text).notNull()
                t.column(CodingKeys.host.lows, .text).notNull()
            }
        }
    }
}

struct ChatMessage: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var chat: String
    var request: String
    var content: String
    var message: String?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let chat = Column(CodingKeys.chat)
        static let request = Column(CodingKeys.request)
        static let content = Column(CodingKeys.content)
        static let message = Column(CodingKeys.message)
    }

    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "chatMessage", ifNotExists: true) { t in
                t.primaryKey(CodingKeys.id.lows, .text)
                t.column(CodingKeys.timestamp.lows, .datetime).notNull()
                t.column(CodingKeys.chat.lows, .text).notNull()
                t.column(CodingKeys.request.lows, .text).notNull()
                t.column(CodingKeys.content.lows, .text).notNull()
                t.column(CodingKeys.message.lows, .text)
            }
        }
    }
}

struct ChatPrompt: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var timestamp: Date = .now
    var title: String
    var content: String
    var inside: Bool

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let title = Column(CodingKeys.title)
        static let content = Column(CodingKeys.content)
        static let inside = Column(CodingKeys.inside)
    }

    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "chatPrompt", ifNotExists: true) { t in
                t.primaryKey(CodingKeys.id.lows, .text)
                t.column(CodingKeys.timestamp.lows, .datetime).notNull()
                t.column(CodingKeys.title.lows, .text).notNull()
                t.column(CodingKeys.content.lows, .date).notNull()
                t.column(CodingKeys.inside.lows, .boolean)
            }
        }
    }
}

enum ChatPromptMode: Equatable {
    case summary(String?)
    case translate(String?)
    case writing(String?)
    case code(String?)
    case abstract(String?)
}

extension CodingKey {
    fileprivate var lows: String {
        stringValue.lowercased()
    }
}
