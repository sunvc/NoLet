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

enum Identifiers: String, CaseIterable, Codable {
    case myNotificationCategory
    case markdown
    case reply

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

        /// 翻译/总结由通知扩展就地处理，不拉起主 App
        var inExtension: Bool {
            switch self {
            case .translateAction, .abstractAction: true
            default: false
            }
        }
    }

    static func setCategories() {
        let actions = Action.allCases.compactMap { item in
            UNNotificationAction(
                identifier: item.rawValue,
                title: item.title,
                options: item.inExtension ? [] : [.foreground],
                icon: .init(systemImageName: item.icon)
            )
        }

        let replyActions = [
            UNTextInputNotificationAction(
                identifier: Identifiers.reply.rawValue,
                title: Identifiers.reply.rawValue,
                options: .foreground
            ),
        ]

        let categories = Self.allCases.compactMap { item in
            UNNotificationCategory(
                identifier: item.rawValue,
                actions: item == .reply ? replyActions : actions,
                intentIdentifiers: [],
                options: .customDismissAction
            )
        }

        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
}
