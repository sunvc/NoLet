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

public typealias FunctionDefinition = ChatQuery.ChatCompletionToolParam.FunctionDefinition

enum NoLetChatAction: String, CaseIterable {
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
    case clearTheContext
}

extension NoLetChatAction {
    func execute(with value: Any) async -> String {
        let manager = AppManager.shared

        let paramsError = "参数非法"
        switch self {
        case .voiceFeedback:
            guard let val = value as? Bool else { return paramsError }
            Defaults[.feedbackSound] = val

        case .autoSaveImages:
            guard let val = value as? Bool else { return paramsError }
            Defaults[.autoSaveToAlbum] = val

        case .showIcon:
            guard let val = value as? Bool else { return paramsError }
            Defaults[.showMessageAvatar] = val

        case .messageHeight:
            guard let val = value as? Int else { return paramsError }
            Defaults[.limitMessageLine] = val

        case .defaultBrowser:
            guard
                let val = value as? String,
                let mode = DefaultBrowserModel(rawValue: val)
            else { return paramsError }
            Defaults[.defaultBrowser] = mode

        case .scanAreaRestriction:
            guard let val = value as? Bool else { return paramsError }
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
            guard let path = NCONFIG.getDir(.caches) else { return paramsError }

            manager.clearContentsOfDirectory(at: path)

        case .setDefaultMessageStorageDays:
            guard
                let val = value as? Int,
                let time = ExpirationTime(rawValue: val)
            else { return paramsError }
            Defaults[.messageExpiration] = time

        case .setDefaultImageStorageDays:
            guard
                let val = value as? Int,
                let time = ExpirationTime(rawValue: val)
            else { return paramsError }
            Defaults[.imageSaveDays] = time

        case .deleteAllMuteGroups:
            Defaults[.muteSetting] = [:]

        case .deleteMessagesByTime:
            guard let rangeStr = value as? String else { return paramsError }
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

            guard let startTime, let endTime else { return paramsError }

            return MessagesManager.shared.delete(startTime, end: endTime)

        case .clearTheContext:
            let success = await openChatManager.shared.setPoint()
            if !success {
                return "执行失败"
            }
        }

        return "执行成功"
    }
}

extension NoLetChatAction {
    var parameter: JSONSchema {
        switch self {
        case .voiceFeedback:
            return JSONSchema(
                .type(.boolean),
                .description("是否开启声音反馈")
            )

        case .autoSaveImages:
            return JSONSchema(
                .type(.boolean),
                .description("是否自动保存图片到相册")
            )

        case .showIcon:
            return JSONSchema(
                .type(.boolean),
                .description("是否在消息列表中显示应用图标")
            )

        case .messageHeight:
            return .init(fields: [
                .type(.integer),
                .description("消息气泡显示的最大行数，范围 1 到 10"),
            ])

        case .defaultBrowser:
            return .init(fields: [
                .type(.string),
                .enumValues(["internal", "safari", "auto"]),
                .description("默认浏览器设置"),
            ])

        case .scanAreaRestriction:
            return JSONSchema(
                .type(.boolean),
                .description("是否开启扫描区域限制")
            )

        case .openSystemSettings:
            return JSONSchema(
                .type(.boolean),
                .description("打开系统设置页面")
            )

        case .openServerSettings:
            return JSONSchema(
                .type(.boolean),
                .description("打开服务器设置页面")
            )

        case .openUploadCloudIcon:
            return JSONSchema(
                .type(.boolean),
                .description("打开云图标上传页面")
            )

        case .openAIAssistantSettings:
            return JSONSchema(
                .type(.boolean),
                .description("打开 AI 助手设置页面")
            )

        case .openSoundSettings:
            return JSONSchema(
                .type(.boolean),
                .description("打开声音设置页面")
            )

        case .openEncryptionSettings:
            return JSONSchema(
                .type(.boolean),
                .description("打开加密设置页面")
            )

        case .openDataManagement:
            return JSONSchema(
                .type(.boolean),
                .description("打开数据管理页面")
            )

        case .openAbout:
            return JSONSchema(
                .type(.boolean),
                .description("打开关于页面")
            )

        case .openAppDocs:
            return JSONSchema(
                .type(.boolean),
                .description("打开 App 使用文档")
            )

        case .openServerDocs:
            return JSONSchema(
                .type(.boolean),
                .description("打开服务器部署文档")
            )

        case .clearAppCache:
            return JSONSchema(
                .type(.boolean),
                .description("清除 App 缓存")
            )

        case .setDefaultMessageStorageDays:
            return JSONSchema(
                .type(.integer),
                .enumValues([0, 1, 7, 30, 999_999]),
                .description("设置默认消息存储天数")
            )

        case .setDefaultImageStorageDays:
            return JSONSchema(
                .type(.integer),
                .enumValues([0, 1, 7, 30, 999_999]),
                .description("设置默认图片存储天数")
            )

        case .deleteAllMuteGroups:
            return JSONSchema(
                .type(.boolean),
                .description("删除所有静音的分组")
            )

        case .deleteMessagesByTime:
            return JSONSchema(
                .type(.object),
                .properties([
                    "startTime": JSONSchema(
                        .type(.number),
                        .description("开始时间戳")
                    ),
                    "endTime": JSONSchema(
                        .type(.number),
                        .description("结束时间戳")
                    ),
                ]),
                .required(["startTime"]),
                .description("删除指定时间范围内的消息")
            )

        case .clearTheContext:
            return JSONSchema(
                .type(.boolean),
                .description("清除当前上下文")
            )
        }
    }

    static let AllName = ActionName.allCases.compactMap { $0.rawValue }

    enum ActionName: String, Sendable, CaseIterable {
        case defaultName = "context_management"
        case appManageName = "manage_app"
    }

    static func defaultFunc() -> [FunctionDefinition] {
        let clearTheContext = Self.clearTheContext
        return [
            FunctionDefinition(
                name: ActionName.defaultName.rawValue,
                description: String(
                    localized: "CRITICAL: 管理当前模型上下文"
                ),
                parameters: .init(fields: [
                    .type(.object),
                    .properties([
                        clearTheContext.rawValue: clearTheContext.parameter,
                    ]),
                    .additionalProperties(.boolean(false)),
                ])
            ),
        ]
    }

    static func getFuncs() -> [FunctionDefinition] {
        let properties: [String: JSONSchema] =
            Dictionary(uniqueKeysWithValues:
                Self.allCases.map { action in
                    (action.rawValue, action.parameter)
                }
            )

        return [
            FunctionDefinition(
                name: ActionName.appManageName.rawValue,
                description: String(
                    localized: "CRITICAL: 管理应用设置、删除消息、打开页面、查看文档等."
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
