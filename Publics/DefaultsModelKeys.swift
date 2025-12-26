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

@MainActor
extension Defaults.Keys {
    static let noServerModel = Key<Bool>("noServerModel", false)
    static let servers = Key<[PushServerModel]>("serverArrayStroage", [])
    static let cloudServers = Key<[PushServerModel]>("serverArrayCloudStroage", [], iCloud: true)
    static let appIcon = Key<AppIconEnum>("setting_active_app_icon", .nolet)
    static let messageExpiration = Key<ExpirationTime>("messageExpirtionTime", .forever)
    static let defaultBrowser = Key<DefaultBrowserModel>("defaultBrowserOpen", .auto)
    static let imageSaveDays = Key<ExpirationTime>("imageSaveDays", .forever)
    static let proxyServer = Key<PushServerModel>("proxyDownloadServer", PushServerModel.space)
}

extension ExpirationTime: @MainActor Defaults.Serializable {}
extension DefaultBrowserModel: @MainActor Defaults.Serializable {}
extension Identifiers: @MainActor Defaults.Serializable {}
extension AppIconEnum: @MainActor Defaults.Serializable {}
extension PushServerModel: @MainActor Defaults.Serializable {}

struct MoreMessage: Codable, Hashable, @MainActor Defaults.Serializable {
    var createDate: Date
    var id: String
    var body: String
    var index: Int
    var count: Int
}
