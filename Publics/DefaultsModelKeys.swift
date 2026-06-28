//
//  DefaultsModelKeys.swift
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

nonisolated extension Defaults.Keys {
    static let servers = Key<[PushServerModel]>("serverArrayStroage", [])
    static let messageExpiration = Key<ExpirationTime>("messageExpirtionTime", .forever)
    static let defaultBrowser = Key<DefaultBrowserModel>("defaultBrowserOpen", .auto)
    static let imageSaveDays = Key<ExpirationTime>("imageSaveDays", .forever)
    static let proxyServer = Key<PushServerModel>("proxyDownloadServer", PushServerModel.space)
    static let customReasoningEffort = Key<String>("customReasoningEffort", "custom")
}

nonisolated extension Defaults.Keys {
    static let appIcon = Key<AppIconEnum>("setting_active_app_icon", .nolet)
}

nonisolated extension ExpirationTime: Defaults.Serializable {}
nonisolated extension DefaultBrowserModel: Defaults.Serializable {}
nonisolated extension Identifiers: Defaults.Serializable {}
nonisolated extension AppIconEnum: Defaults.Serializable {}
nonisolated extension PushServerModel: Defaults.Serializable {}
