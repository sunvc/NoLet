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
    var createDate: Date
    var group: String
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
    var isRead: Bool
    var other: String?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let group = Column(CodingKeys.group)
        static let createDate = Column(CodingKeys.createDate )
        static let title = Column(CodingKeys.title )
        static let subtitle = Column(CodingKeys.subtitle )
        static let body = Column(CodingKeys.body )
        static let icon = Column(CodingKeys.icon )
        static let url = Column(CodingKeys.url )
        static let image = Column(CodingKeys.image)
        static let from = Column(CodingKeys.from)
        static let host = Column(CodingKeys.host)
        static let level = Column(CodingKeys.level)
        static let ttl = Column(CodingKeys.ttl)
        static let isRead = Column(CodingKeys.isRead)
        static let other = Column(CodingKeys.other )
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
    var current: Bool

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
        static let current = Column(CodingKeys.current)
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
}

enum ChatPromptMode: Equatable {
    case summary(String?)
    case translate(String?)
    case writing(String?)
    case code(String?)
    case abstract(String?)
}
