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
