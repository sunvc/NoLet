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

protocol NoletChatProtocol: CaseIterable {
    static var actionName: String { get }
    var parameter: JSONSchema { get }
    func execute(with value: Any) async -> String
    static func funcs() -> [FunctionDefinition]
}

enum NoLetChatAction: String, NoletChatProtocol {
    case voiceFeedback
    case autoSaveImages
    case showMessageIcon
    case messageHeight
    case defaultBrowser
    case openSystemSettings
    case openServerSettings
    case openUploadCloudIcon
    case openAIAssistantSettings
    case openSoundSettings
    case openEncryptionSettings
    case openDataManagement
    case openExample
    case openAbout
    case openAppDocs
    case openServerDocs
    case clearAppCache
    case setDefaultMessageStorageDays
    case setDefaultImageStorageDays
    case deleteAllMuteGroups
    case clearTheContext
    case startNewChat
}

extension NoLetChatAction {
    func execute(with value: Any) async -> String {

        let manager = AppManager.shared

        let paramsError = "Invalid parameters"
        switch self {
        case .voiceFeedback:
            guard let val = value as? Bool else { return paramsError }
            
            Defaults[.feedbackSound] = val

        case .autoSaveImages:
            guard let val = value as? Bool else { return paramsError }
            Defaults[.autoSaveToAlbum] = val

        case .showMessageIcon:
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
        case .openSystemSettings:
            AppManager.openSetting()

        case .openServerSettings:
            manager.router = [.server]

        case .openUploadCloudIcon:
            manager.open(sheet: .cloudIcon)

        case .openAIAssistantSettings:
            manager.router = [.noletChatSetting(nil)]

        case .openSoundSettings:
            manager.router = [.sound]

        case .openEncryptionSettings:
            manager.router = [.crypto]

        case .openDataManagement:
            manager.router = [.dataSetting]

        case .openAbout:
            manager.router = [.about]

        case .openExample:
            manager.router = [.example]

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

        case .clearTheContext:
            let success = await NoLetChatManager.shared.setPoint()
            if !success {
                return "Execution failed"
            }

        case .startNewChat:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NoLetChatManager.shared.cancellableRequest?.cancel()
                NoLetChatManager.shared.setGroup()
            }
        }
        
        return "OK"
    }
}

extension NoLetChatAction {
    var parameter: JSONSchema {
        switch self {
        case .voiceFeedback:
            return JSONSchema(
                .type(.boolean),
                .description("Whether to enable voice feedback")
            )

        case .autoSaveImages:
            return JSONSchema(
                .type(.boolean),
                .description("Whether to auto-save images to album")
            )

        case .showMessageIcon:
            return JSONSchema(
                .type(.boolean),
                .description("Whether to show app icon in message list")
            )

        case .messageHeight:
            return .init(fields: [
                .type(.integer),
                .description("Maximum lines for message bubble, range 1 to 10"),
            ])

        case .defaultBrowser:
            return .init(fields: [
                .type(.string),
                .enumValues(["internal", "safari", "auto"]),
                .description("Default browser settings"),
            ])

        case .openSystemSettings:
            return JSONSchema(
                .type(.boolean),
                .description("Open system settings page")
            )

        case .openServerSettings:
            return JSONSchema(
                .type(.boolean),
                .description("Open server settings page")
            )

        case .openUploadCloudIcon:
            return JSONSchema(
                .type(.boolean),
                .description("Open cloud icon upload page")
            )

        case .openAIAssistantSettings:
            return JSONSchema(
                .type(.boolean),
                .description("Open AI assistant settings page")
            )

        case .openSoundSettings:
            return JSONSchema(
                .type(.boolean),
                .description("Open sound settings page")
            )

        case .openEncryptionSettings:
            return JSONSchema(
                .type(.boolean),
                .description("Open encryption settings page")
            )

        case .openDataManagement:
            return JSONSchema(
                .type(.boolean),
                .description("Open data management page")
            )

        case .openAbout:
            return JSONSchema(
                .type(.boolean),
                .description("Open about page")
            )

        case .openAppDocs:
            return JSONSchema(
                .type(.boolean),
                .description("Open App usage documentation")
            )

        case .openServerDocs:
            return JSONSchema(
                .type(.boolean),
                .description("Open server deployment documentation")
            )

        case .openExample:
            return JSONSchema(
                .type(.boolean),
                .description("Open push messages example")
            )

        case .clearAppCache:
            return JSONSchema(
                .type(.boolean),
                .description("Clear App cache")
            )

        case .setDefaultMessageStorageDays:
            return JSONSchema(
                .type(.integer),
                .enumValues([0, 1, 7, 30, 999_999]),
                .description("Set default message storage days")
            )

        case .setDefaultImageStorageDays:
            return JSONSchema(
                .type(.integer),
                .enumValues([0, 1, 7, 30, 999_999]),
                .description("Set default image storage days")
            )

        case .deleteAllMuteGroups:
            return JSONSchema(
                .type(.boolean),
                .description("Delete all muted groups")
            )

        case .clearTheContext:
            return JSONSchema(
                .type(.boolean),
                .description("Clear the current context memory")
            )

        case .startNewChat:
            return JSONSchema(
                .type(.boolean),
                .description("Start a new conversation")
            )
        }
    }

    static let actionName = "manage_app"
    static let messageName = "manage_message"


    static func funcs() -> [FunctionDefinition] {
        let properties: [String: JSONSchema] =
            Dictionary(uniqueKeysWithValues:
                Self.allCases.map { action in
                    (action.rawValue, action.parameter)
                }
            )
        return [
            FunctionDefinition(
                name: actionName,
                description: "CRITICAL: Manage app settings, delete messages, open pages, view docs, etc.",
                parameters: .init(fields: [
                    .type(.object),
                    .properties(properties),
                    .additionalProperties(.boolean(false)),
                ]),
                strict: true
            ),

            FunctionDefinition(
                name: messageName,
                description: "CRITICAL: delete x before messages",
                parameters: .init(fields: [
                    .type(.object),
                    .properties([
                        "type": JSONSchema(
                            .type(.string),
                            .description("type"),
                            .enumValues(["hour", "day", "all"])
                        ),
                        "count": JSONSchema(
                            .type(.integer),
                            .description("Quantity")
                        ),
                    ]),
                    .required(["type", "count"]),
                    .additionalProperties(.boolean(false)),
                ]),
                strict: true
            ),
        ]
    }
}
