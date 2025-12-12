//
//  OtherModel.swift
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

import Defaults
import Foundation
import SwiftUI

// MARK: - Remote Response

struct baseResponse<T>: Codable where T: Codable {
    var code: Int
    var message: String
    var data: T?
    var timestamp: Int?
}

struct DeviceInfo: Codable {
    var deviceKey: String
    var deviceToken: String
    var group: String?

    // 使用 `CodingKeys` 枚举来匹配 JSON 键和你的变量命名
    enum CodingKeys: String, CodingKey {
        case deviceKey = "key"
        case deviceToken = "token"
        case group
    }
}

enum requestHeader: String {
    case https = "https://"
    case http = "http://"
}

enum Identifiers: String, CaseIterable, Codable {
    case myNotificationCategory
    case markdown

    enum Action: String, CaseIterable, Codable {
        case copyAction = "copy"
        case muteAction = "mute"

        var title: String {
            switch self {
            case .copyAction: String(localized: "复制")
            case .muteAction: String(localized: "静音分组1小时")
            }
        }

        var icon: String {
            switch self {
            case .copyAction: "doc.on.doc"
            case .muteAction: "speaker.slash"
            }
        }
    }

    static func setCategories() {
        let actions = Action.allCases.compactMap { item in
            UNNotificationAction(
                identifier: item.rawValue,
                title: item.title,
                options: [.foreground],
                icon: .init(systemImageName: item.icon)
            )
        }

        let categories = Self.allCases.compactMap { item in
            UNNotificationCategory(
                identifier: item.rawValue,
                actions: actions,
                intentIdentifiers: [],
                options: [.hiddenPreviewsShowTitle]
            )
        }

        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
}

// MARK: - MessageAction model

enum MessageAction: String, CaseIterable, Equatable {
    case lastHour
    case lastDay
    case lastWeek
    case lastMonth
    case allTime
    case cancel
}

// MARK: - QuickAction model

enum QuickAction: String, CaseIterable {
    static var selectAction: UIApplicationShortcutItem?

    case assistant
    case scan
}

// MARK: - PushServerModel

struct PushServerModel: Codable, Identifiable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var device: String
    var url: String
    var key: String = ""
    var group: String? = nil
    var status: Bool = false
    var createDate: Date = .now
    var updateDate: Date = .now
    var voice: Bool = false
    var sign: String? = nil

    init(
        id: String = UUID().uuidString,
        device: String? = nil,
        url: String,
        key: String = "",
        group: String? = nil,
        status: Bool = false,
        createDate: Date = .now,
        updateDate: Date = .now,
        voice: Bool = false,
        sign: String? = nil
    ) {
        self.id = id
        self.device = device ?? NCONFIG.deviceInfoString()
        self.url = url
        self.key = key
        self.group = group
        self.status = status
        self.createDate = createDate
        self.updateDate = updateDate
        self.voice = voice
        self.sign = sign
    }

    var name: String {
        var name = url
        if let range = url.range(of: "://") {
            name.removeSubrange(url.startIndex..<range.upperBound)
        }
        return name
    }

    var color: Color { status ? .green : .orange }

    var server: String { url + "/" + key }

    static let space = Self(url: String(localized: "无"))

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url && lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(key)
    }
}

// MARK: - AppIconMode

enum AppIconEnum: String, CaseIterable, Equatable {
    case nolet
    case nolet0
    case nolet1
    case nolet2
    case nolet3

    var name: String? { self == .nolet ? nil : rawValue }

    var logo: String {
        switch self {
        case .nolet: "logo"
        case .nolet0: "logo0"
        case .nolet1: "logo1"
        case .nolet2: "logo2"
        case .nolet3: "logo3"
        }
    }
}

// MARK: - PushExampleModel

struct PushExampleModel: Identifiable {
    var id = UUID().uuidString
    var header, footer: AnyView
    var title: String
    var params: String
    var index: Int

    init<Header: View, Footer: View>(
        header: Header,
        footer: Footer,
        title: String,
        params: String,
        index: Int
    ) {
        self.header = AnyView(header)
        self.footer = AnyView(footer)
        self.title = title
        self.params = params
        self.index = index
    }
}

// MARK: - ExpirationTime

enum DefaultBrowserModel: String, CaseIterable {
    case auto
    case safari
    case app
}

struct AssistantAccount: Codable, Identifiable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var current: Bool = false
    var timestamp: Date = .now
    var name: String
    var host: String
    var basePath: String
    var key: String
    var model: String

    func toBase64() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }

    init(
        current: Bool = false,
        name: String,
        host: String,
        basePath: String,
        key: String,
        model: String
    ) {
        self.current = current
        self.name = name
        self.host = host
        self.basePath = basePath
        self.key = key
        self.model = model
    }

    init?(base64: String) {
        guard let data = Data(base64Encoded: base64), let decoded = try? JSONDecoder().decode(
            Self.self,
            from: data
        ) else {
            return nil
        }
        self = decoded
        id = UUID().uuidString
    }
}

extension AssistantAccount {
    mutating func trimAssistantAccountParameters() {
        name = name.trimmingSpaceAndNewLines
        host = host.trimmingSpaceAndNewLines
        host = host.removeHTTPPrefix()
        basePath = basePath.trimmingSpaceAndNewLines
        key = key.trimmingSpaceAndNewLines
        model = model.trimmingSpaceAndNewLines
    }
}

enum OutDataType {
    case text(String)
    case crypto(String)
    case server(url: String, key: String, group: String?, sign: String?)
    case otherURL(String)
    case assistant(String)
    case cloudIcon
}

enum ExpirationTime: Int, CaseIterable, Equatable {
    case forever = 999_999
    case month = 30
    case weekDay = 7
    case oneDay = 1
    case no = 0

    var days: Int { rawValue }
}

struct SelectMessage: Codable {
    var id: UUID = .init()
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
    var level: Int = 1
    var ttl: Int = ExpirationTime.forever.days
    var read: Bool = false
    var search: String
}

enum PBScheme: String, CaseIterable {
    case pb
    case mw
    case nolet

    static var schemes: [String] { allCases.compactMap { $0.rawValue } }

    enum HostType: String {
        case server
        case crypto
        case assistant
        case openPage
    }

    // pb://openpage?title=string or mw://openpage?title=string
    func scheme(host: HostType, params parameters: [String: Any]) -> URL {
        var components = URLComponents()
        components.scheme = rawValue
        components.host = host.rawValue // 固定 host，如果有 path 也可以加上

        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }

        return components.url!
    }
}

struct MoreMessage: Codable, Hashable {
    var createDate: Date
    var id: String
    var body: String
    var index: Int
    var count: Int
}

struct PushToTalkGroup: Codable, Hashable {
    var id: UUID
    var name: String
    var avatar: URL?
    var active: Bool
    private(set) var prefix: Int = 10
    private(set) var suffix: Int = 1

    var uiimage: UIImage? {
        if let avatar {
            UIImage(contentsOfFile: avatar.absoluteString)
        } else {
            UIImage(contentsOfFile: "logo2")
        }
    }

    mutating func set(_ prefix: Int? = nil, suffix: Int? = nil) {
        if let prefix {
            self.prefix = max(min(prefix, 999), 10)
        }
        if let suffix {
            self.suffix = max(min(suffix, 999), 1)
        }
    }
}
