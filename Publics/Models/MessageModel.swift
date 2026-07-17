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
    var body: String
    var icon: String?
    var url: String?
    var image: String?
    var reply: String?
    var ttl: Int
    var read: Bool
    var style: String?
    var other: String?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let group = Column(CodingKeys.group)
        static let createDate = Column(CodingKeys.createDate)
        static let title = Column(CodingKeys.title)
        static let subtitle = Column(CodingKeys.subtitle)
        static let body = Column(CodingKeys.body)
        static let icon = Column(CodingKeys.icon)
        static let url = Column(CodingKeys.url)
        static let image = Column(CodingKeys.image)
        static let reply = Column(CodingKeys.reply)
        static let ttl = Column(CodingKeys.ttl)
        static let read = Column(CodingKeys.read)
        static let style = Column(CodingKeys.style)
        static let other = Column(CodingKeys.other)
    }

    // MARK: - Computed Properties

    // 优化：Lazy 干净拼接，避免产生过多临时中间数组
    var search: String {
        [group, title, subtitle, body, url]
            .lazy
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ";") + ";"
    }

    // 优化：提取公共计算逻辑，保持 DRY (Don't Repeat Yourself)
    private var elapsedSeconds: TimeInterval {
        Date().timeIntervalSince(createDate)
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
        return otherDictionary?[key] as? T ?? value
    }
}

struct ChatGroup: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Equatable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var name: String
    var host: String
    var current: Bool
    var point: Date?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
        static let current = Column(CodingKeys.current)
        static let point = Column(CodingKeys.point)
    }
}

struct ChatMessage: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Equatable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var chat: String
    var role: String
    var content: String
    var message: String?
    var reason: String?
    var result: [String: String]?

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let chat = Column(CodingKeys.chat)
        static let role = Column(CodingKeys.role)
        static let content = Column(CodingKeys.content)
        static let message = Column(CodingKeys.message)
        static let reason = Column(CodingKeys.reason)
        static let result = Column(CodingKeys.result)
    }
    
    enum Role: String {
        case user
        case assistant
        case tool
    }
}

struct ChatPrompt: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var timestamp: Date = .now
    var title: String
    var content: String
    var inside: Bool
    var mode: PromptMode = .promt

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let title = Column(CodingKeys.title)
        static let content = Column(CodingKeys.content)
        static let inside = Column(CodingKeys.inside)
    }

    enum PromptMode: String, Codable {
        case promt
        case mcp
        case call

        var name: String {
            switch self {
            case .promt: String(localized: "提示词")
            case .mcp: "MCP"
            case .call: "CALL"
            }
        }
    }
}

enum ChatPromptMode: Equatable {
    case mcp(String?)
    case translate(String?)
    case abstract(String?)
}
