//
//  ParamsModel.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/28.
//

import SwiftUI



enum LevelTitle: String, CaseIterable, Codable , Defaults.Serializable{
    case passive
    case active
    case timeSensitive
    case critical

    var name: String {
        switch self {
        case .passive: return String(localized: "静默通知")
        case .active: return String(localized: "正常通知")
        case .timeSensitive: return String(localized: "即时通知")
        case .critical: return String(localized: "重要通知")
        }
    }

    // 🔁 从 displayName 获取 rawValue（如："静默通知" -> "passive"）
    static func rawValue(fromDisplayName name: String) -> String? {
        return LevelTitle.allCases.first(where: {$0.name == name})?.rawValue
    }
}
