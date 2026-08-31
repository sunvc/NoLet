//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - IdentifiersEnum.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 21:32.

import Foundation
import UserNotifications

enum Identifiers: String, CaseIterable, Codable, Identifiable, Hashable, Equatable {
    case myNotificationCategory
    case markdown
    case reply

    case alfa
    case bravo
    case charlie
    case delta
    case echo
    case foxtrot
    case golf
    case hotel
    case india
    case juliett
    case kilo
    case lima
    case mike
    case november
    case oscar
    case papa
    case quebec
    case romeo
    case sierra
    case tango
    case uniform
    case victor
    case whiskey
    case xray
    case yankee
    case zulu

    static let system: Set<Self> = [
        .myNotificationCategory,
        .markdown,
        .reply
    ]

    static var custom: [Self] {
        allCases.filter { !system.contains($0) }
    }

    var isSystem: Bool {
        Self.system.contains(self)
    }

    var isCustom: Bool {
        !isSystem
    }

    enum Action: String, CaseIterable, Codable {
        case copyAction = "copy"
        case muteAction = "mute"
        case translateAction = "translate"
        case abstractAction = "abstract"

        var title: String {
            switch self {
            case .copyAction: String(localized: "复制")
            case .muteAction: String(localized: "静音分组1小时")
            case .translateAction: String(localized: "翻译")
            case .abstractAction: String(localized: "总结")
            }
        }

        var icon: String {
            switch self {
            case .copyAction: "doc.on.doc"
            case .muteAction: "speaker.slash"
            case .translateAction: "globe.europe.africa"
            case .abstractAction: "doc.text.magnifyingglass"
            }
        }

        var model: NotificationActionModel {
            NotificationActionModel(identifier: rawValue, builtInId: rawValue, title: "", icon: "")
        }
    }

    static func setCategories() {
        let actions = Action.allCases.compactMap { item in
            UNNotificationAction(
                identifier: item.rawValue,
                title: item.title,
                options: [],
                icon: .init(systemImageName: item.icon)
            )
        }

        let customCategories = Defaults[.customNotificationCategories]
            .compactMap { category -> UNNotificationCategory? in
                let unActions = category.actions.map { item in
                    if let builtInId = item.builtInId, let action = Action(rawValue: builtInId) {
                        return UNNotificationAction(
                            identifier: item.identifier,
                            title: action.title,
                            options: [],
                            icon: .init(systemImageName: action.icon)
                        )
                    } else {
                        return UNNotificationAction(
                            identifier: item.identifier,
                            title: item.title,
                            options: [.foreground],
                            icon: item.icon.isEmpty ? nil : .init(systemImageName: item.icon)
                        )
                    }
                }
                return UNNotificationCategory(
                    identifier: category.id,
                    actions: unActions,
                    intentIdentifiers: [],
                    options: .customDismissAction
                )
            }

        let replyActions = [
            UNTextInputNotificationAction(
                identifier: Identifiers.reply.rawValue,
                title: Identifiers.reply.rawValue,
                options: .foreground
            ),
        ]

        let categories = system.compactMap { item -> UNNotificationCategory? in
            switch item {
            case .reply:
                return UNNotificationCategory(
                    identifier: item.rawValue,
                    actions: replyActions,
                    intentIdentifiers: [],
                    options: .customDismissAction
                )
            default:
                return UNNotificationCategory(
                    identifier: item.rawValue,
                    actions: actions,
                    intentIdentifiers: [],
                    options: .customDismissAction
                )
            }
        }

        UNUserNotificationCenter.current()
            .setNotificationCategories(Set(categories + customCategories))
    }
    
    var id: String { rawValue }
}

extension NotificationActionModel {
    var builtInAction: Identifiers.Action? {
        guard let builtInId else { return nil }
        return Identifiers.Action(rawValue: builtInId)
    }

    var displayTitle: String {
        builtInAction?.title ?? title
    }

    var displayIcon: String {
        builtInAction?.icon ?? icon
    }
}
