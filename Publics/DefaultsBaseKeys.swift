//
//  DefaultsBaseKeys.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/9.
//

@_exported import Defaults
import Foundation


nonisolated func DEFAULTSTORE() -> UserDefaults {
    return UserDefaults(suiteName: NCONFIG.groupName)!
}

nonisolated extension Defaults.Key {
    convenience init(_ name: String, _ defaultValue: Value, iCloud: Bool = false) {
        self.init(name, default: defaultValue, suite: DEFAULTSTORE(), iCloud: iCloud)
    }
}

nonisolated extension Defaults.Keys {
  
    static let firstStart = Key<Bool>("firstStartApp", true)
    static let autoSaveToAlbum = Key<Bool>("autoSaveImageToPhotoAlbum", false)
    static let sound = Key<String>("defaultSound", "nolet")
    static let showGroup = Key<Bool>("showGroupMessage", false)
    static let historyMessageCount = Key<Int>("historyMessageCount", 5)
    static let temperatureChat = Key<Int>("temperatureChat", 13)
    static let showAssistantAnimation = Key<Bool>("showAssistantAnimation", false)
    static let freeCloudImageCount = Key<Int>("freeCloudImageCount", 30)
    static let muteSetting = Key<[String: Date]>("muteSetting", [:])

    static let imageSaves = Key<[String]>("imageSaves", [])
    static let id = Key<String>("UserDeviceUniqueID", "")
    static let lang = Key<String>("LocalePreferredLanguagesFirst", "")
    static let allMessagecount = Key<Int>("allMessagecount", 0, iCloud: true)

    static let feedbackSound = Key<Bool>("feedbackSound", false)
    static let nearbyShow = Key<Bool>("nearbyShow", false)
    static let usePtt = Key<Bool>("usePushToTalk", false)
}
