//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - NotificationActionModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/21 17:51.

@_exported import Defaults
import Foundation

struct NotificationActionModel: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    /// UNNotificationAction 的 identifier，通知内据此处理操作，需全局唯一
    var identifier: String
    /// 非 nil 表示是内置操作，值为对应内置操作的原始标识
    var builtInId: String?
    var title: String
    var icon: String
    var scriptName: String?

    var isBuiltIn: Bool { builtInId != nil }
}

struct NotificationCategoryModel: Codable, Hashable, Identifiable {
    var id: String { identifier.rawValue }
    var identifier: Identifiers
    var actions: [NotificationActionModel]
}

extension [NotificationCategoryModel] {
    func queryAction(identifier: String) -> NotificationActionModel? {
        for k in self {
            if let action = k.actions.first(where: { $0.identifier == identifier }) {
                return action
            }
        }
        return nil
    }
}

extension NotificationActionModel: Defaults.Serializable {}
extension NotificationCategoryModel: Defaults.Serializable {}

extension Defaults.Keys {
    static let customNotificationCategories = Key<[NotificationCategoryModel]>(
        "customNotificationCategories",
        []
    )
}
