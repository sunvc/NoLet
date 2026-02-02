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

#if DEBUG
actor UniqueKeysChecker {
    static let shared = UniqueKeysChecker()
    private var keys = Set<String>()

    func checkAndInsert(_ key: String) {
        assert(!keys.contains(key), "错误：\(key) 已经存在！")
        keys.insert(key)
    }
}
#endif



func DEFAULTSTORE() -> UserDefaults {
   return  UserDefaults(suiteName: NCONFIG.groupName)!
}

extension Defaults.Key {
    convenience init(_ name: String, _ defaultValue: Value, iCloud: Bool = false) {
        #if DEBUG
        Task {
            await UniqueKeysChecker.shared.checkAndInsert(name)
        }
        #endif

        self.init(name, default: defaultValue, suite: DEFAULTSTORE(), iCloud: iCloud)
    }
}

extension Defaults.Keys {
    static let deviceToken = Key<String>("deviceToken", "")
    static let voipDeviceToken = Key<String>("voipDeviceToken", "")
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
    static let showMessageAvatar = Key<Bool>("showMessageAvatar", false)
    static let id = Key<String>("UserDeviceUniqueID", "")
    static let lang = Key<String>("LocalePreferredLanguagesFirst", "")
    static let allMessagecount = Key<Int>("allMessagecount", 0, iCloud: true)

    static let feedbackSound = Key<Bool>("feedbackSound", false)
    static let nearbyShow = Key<Bool>("nearbyShow", false)
}
