//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AppActionManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/2 13:53.

import Foundation
import OpenAI

enum AppSettingAction: String, CaseIterable {
    case voiceFeedback
    case autoSaveImages
    case showIcon
    case messageHeight
    case defaultBrowser
    case scanAreaRestriction

    case openSystemSettings
    case openServerSettings
    case openUploadCloudIcon
    case openAIAssistantSettings
    case openSoundSettings
    case openEncryptionSettings
    case openDataManagement
    case openAbout

    case openAppDocs
    case openServerDocs

    case clearAppCache

    case setDefaultMessageStorageDays
    case setDefaultImageStorageDays

    case deleteAllMuteGroups

    case deleteMessagesByTime
}

extension AppSettingAction {
    func execute(with value: Any) -> Bool {
        let manager = AppManager.shared

        switch self {
        case .voiceFeedback:
            guard let val = value as? Bool else { return false }
            Defaults[.feedbackSound] = val

        case .autoSaveImages:
            guard let val = value as? Bool else { return false }
            Defaults[.autoSaveToAlbum] = val

        case .showIcon:
            guard let val = value as? Bool else { return false }
            Defaults[.showMessageAvatar] = val

        case .messageHeight:
            guard let val = value as? Int else { return false }
            Defaults[.limitMessageLine] = val

        case .defaultBrowser:
            guard
                let val = value as? String,
                let mode = DefaultBrowserModel(rawValue: val)
            else { return false }
            Defaults[.defaultBrowser] = mode

        case .scanAreaRestriction:
            guard let val = value as? Bool else { return false }
            Defaults[.limitScanningArea] = val

        case .openSystemSettings:
            AppManager.openSetting()

        case .openServerSettings:
            manager.router = [.server]

        case .openUploadCloudIcon:
            manager.sheetPage = .cloudIcon

        case .openAIAssistantSettings:
            manager.router = [.assistantSetting(nil)]

        case .openSoundSettings:
            manager.router = [.sound]

        case .openEncryptionSettings:
            manager.router = [.crypto]

        case .openDataManagement:
            manager.router = [.dataSetting]

        case .openAbout:
            manager.router = [.about]

        // MARK: - Docs

        case .openAppDocs:
            AppManager.openURL(url: NCONFIG.docServer.url, .app)

        case .openServerDocs:
            AppManager.openURL(url: NCONFIG.serverSource.url, .app)

        // MARK: - Data

        case .clearAppCache:
            guard let path = NCONFIG.getDir(.caches) else {
                return false
            }

            manager.clearContentsOfDirectory(at: path)

        case .setDefaultMessageStorageDays:
            guard
                let val = value as? Int,
                let time = ExpirationTime(rawValue: val)
            else { return false }
            Defaults[.messageExpiration] = time

        case .setDefaultImageStorageDays:
            guard
                let val = value as? Int,
                let time = ExpirationTime(rawValue: val)
            else { return false }
            Defaults[.imageSaveDays] = time

        case .deleteAllMuteGroups:
            Defaults[.muteSetting] = [:]

        case .deleteMessagesByTime:
            guard let rangeStr = value as? String else { return false }
            let components = rangeStr.split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0) }

            var startTime: Date?
            var endTime: Date?

            if components.count >= 1, let start = Double(components[0]) {
                startTime = Date(timeIntervalSince1970: start)
            }
            if components.count >= 2, let end = Double(components[1]) {
                endTime = Date(timeIntervalSince1970: end)
            }

            guard let startTime, let endTime else { return false }

            return MessagesManager.shared.delete(startTime, end: endTime)
        }

        return true
    }
}

extension AppSettingAction {
    var description: String.LocalizationValue {
        switch self {
        case .voiceFeedback:
            return "是否开启声音反馈"

        case .autoSaveImages:
            return "是否自动保存图片到相册"

        case .showIcon:
            return "是否在消息列表中显示应用图标"

        case .messageHeight:
            return "消息气泡显示的最大行数，范围 1 到 10"

        case .defaultBrowser:
            return "默认浏览器设置"

        case .scanAreaRestriction:
            return "是否开启扫描区域限制"

        case .openSystemSettings:
            return "打开系统设置页面"

        case .openServerSettings:
            return "打开服务器设置页面"

        case .openUploadCloudIcon:
            return "打开云图标上传页面"

        case .openAIAssistantSettings:
            return "打开 AI 助手设置页面"

        case .openSoundSettings:
            return "打开声音设置页面"

        case .openEncryptionSettings:
            return "打开加密设置页面"

        case .openDataManagement:
            return "打开数据管理页面"

        case .openAbout:
            return "打开关于页面"

        case .openAppDocs:
            return "打开 App 使用文档"

        case .openServerDocs:
            return "打开服务器部署文档"

        case .clearAppCache:
            return "清除 App 缓存"

        case .setDefaultMessageStorageDays:
            return "设置默认消息存储天数"

        case .setDefaultImageStorageDays:
            return "设置默认图片存储天数"

        case .deleteAllMuteGroups:
            return "删除所有静音的分组"

        case .deleteMessagesByTime:
            return "删除指定时间范围内的消息。参数格式为 'start_timestamp,end_timestamp'（秒级时间戳）。例如：删除2025年6月到10月的消息 -> '1748736000,1759276800'。若只删除某时间之前，用 ',end'；某时间之后，用 'start,'。"
        }
    }

    var valueType: AppActionValueType {
        switch self {
        case .voiceFeedback,
             .autoSaveImages,
             .showIcon,
             .scanAreaRestriction,
             .openSystemSettings,
             .openServerSettings,
             .openUploadCloudIcon,
             .openAIAssistantSettings,
             .openSoundSettings,
             .openEncryptionSettings,
             .openDataManagement,
             .openAbout,
             .openAppDocs,
             .openServerDocs,
             .clearAppCache,
             .deleteAllMuteGroups:
            return .bool

        case .deleteMessagesByTime:
            return .string()

        case .messageHeight:
            return .int(range: 1...10)

        case .setDefaultMessageStorageDays,
             .setDefaultImageStorageDays:
            return .int(enums: [0, 1, 7, 30, 999_999])

        case .defaultBrowser:
            return .string(enums: ["internal", "safari", "auto"])
        }
    }

    enum AppActionValueType: Sendable {
        case bool
        case int(range: ClosedRange<Int>? = nil, enums: [Int]? = nil)
        case string(enums: [String]? = nil)
    }

    static func getFuncs() -> [openChatManager.FunctionDefinition] {
        let properties: [String: JSONSchema] =
            Dictionary(uniqueKeysWithValues:
                AppSettingAction.allCases.map { action in
                    (action.rawValue, action.toParameter())
                }
            )

        return [
            openChatManager.FunctionDefinition(
                name: "manage_app",
                description: String(
                    localized: "CRITICAL: 当用户请求操作应用设置、删除消息、打开页面、查看文档、管理数据或清理缓存时，必须调用此函数。"
                ),
                parameters: .init(fields: [
                    .type(.object),
                    .properties(properties),
                    .additionalProperties(.boolean(false)),
                ])
            ),
        ]
    }
}

extension AppSettingAction {
    func toParameter() -> JSONSchema {
        let description = String(localized: description)

        switch valueType {
        case .bool:
            return .init(fields: [
                .type(.boolean),
                .description(description),
            ])

        case .int(_, let enums):
            if let enums {
                return .init(fields: [
                    .type(.integer),
                    .enumValues(enums),
                    .description(description),
                ])
            } else {
                return .init(fields: [
                    .type(.integer),
                    .description(description),
                ])
            }

        case .string(let enums):
            if let enums {
                return .init(fields: [
                    .type(.string),
                    .enumValues(enums),
                    .description(description),
                ])
            } else {
                return .init(fields: [
                    .type(.string),
                    .description(description),
                ])
            }
        }
    }
}
