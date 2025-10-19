//
//  LocalKeys.swift
//  NoLet
//
//  Created by uuneo 2024/10/26.
//

import Defaults
import Foundation


extension Defaults.Keys {
    static let servers = Key<[PushServerModel]>(.serverArrayStroage, [])
    static let cloudServers = Key<[PushServerModel]>(.serverArrayCloudStroage, [], iCloud: true)

    static let badgeMode = Key<BadgeAutoMode>(.Meowbadgemode, .auto)
    static let appIcon = Key<AppIconEnum>(.setting_active_app_icon, .nolet)
    static let messageExpiration = Key<ExpirationTime>(.messageExpirtionTime, .forever)
    static let defaultBrowser = Key<DefaultBrowserModel>(.defaultBrowserOpen, .safari)
    static let imageSaveDays = Key<ExpirationTime>(.imageSaveDays, .forever)
    static let assistantAccouns = Key<[AssistantAccount]>(.AssistantAccount,[], iCloud: true)
    static let moreMessageCache = Key<[MoreMessage]>(.moreMessageCache, [])
}


extension ExpirationTime: Defaults.Serializable{ }
extension DefaultBrowserModel:Defaults.Serializable {}
extension AssistantAccount: Defaults.Serializable{}
extension Identifiers: Defaults.Serializable{}
extension AppIconEnum: Defaults.Serializable{}
extension BadgeAutoMode: Defaults.Serializable{}
extension PushServerModel: Defaults.Serializable{}
extension MoreMessage: Defaults.Serializable{}
extension PushToTalkGroup: Defaults.Serializable{}




