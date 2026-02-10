//
//  OptionsProvider.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//
import AppIntents
import Defaults

// struct ServerAddressProvider: DynamicOptionsProvider {
//    func results() async throws -> [String] {
//        Defaults[.servers].map { $0.server }
//    }
//
//    func defaultResult() async -> String? {
//        Defaults[.servers].first?.server
//    }
// }

struct SoundOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let (customSounds, defaultSounds) = AudioManager.shared.getFileList()
        return ["Default"] + (customSounds + defaultSounds).map {
            $0.deletingPathExtension().lastPathComponent
        }
    }

    func defaultResult() async -> String? {
        return "Default"
    }
}

struct LevelClassProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        return LevelTitle.allCases.map { level in
            level.name
        }
    }

    func defaultResult() async -> String? {
        return LevelTitle.active.name
    }
}

struct VolumeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [Int] {
        return Array(0...10)
    }

    func defaultResult() async -> Int? {
        return 5
    }
}

struct CategoryParamsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        Identifiers.allCases.compactMap { item in
            if item != .reply {
                return item.name
            }
            return nil
        }
    }

    func defaultResult() async -> String? {
        return Identifiers.myNotificationCategory.name
    }
}

extension Identifiers {
    var name: String {
        switch self {
        case .myNotificationCategory:
            return String(localized: "普通内容")
        case .markdown, .reply:
            return "Markdown"
        }
    }
}

struct APIPushToDeviceResponse: Codable {
    let code: Int
    let message: String
    let timestamp: Int
}

enum LevelTitle: String, CaseIterable, Codable, Defaults.Serializable {
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
        return LevelTitle.allCases.first(where: { $0.name == name })?.rawValue
    }
}
