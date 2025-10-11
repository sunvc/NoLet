//
//  DefaultsConfig.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//

@_exported import Defaults
import Foundation

let DEFAULTSTORE = UserDefaults(suiteName: BaseConfig.groupName)!

#if DEBUG
private var uniquekeys: Set<String> = []
#endif


extension Defaults.Key{
    convenience init(_ name: NoletKey, _ defaultValue: Value, iCloud: Bool = false){
#if DEBUG
        assert(!uniquekeys.contains(name.rawValue), "错误：\(name.rawValue) 已经存在！")
        uniquekeys.insert(name.rawValue)
#endif
        self.init(
            name.rawValue,
            default: defaultValue,
            suite: DEFAULTSTORE,
            iCloud: iCloud
        )
    }
}

extension Defaults.Keys{
    
    
    static let deviceToken = Key<String>(.deviceToken, "")
    static let voipDeviceToken = Key<String>(.voipDeviceToken, "")
    static let firstStart = Key<Bool>(.firstStartApp, true)
    static let autoSaveToAlbum = Key<Bool>(.autoSaveImageToPhotoAlbum, false)
    static let sound = Key<String>(.defaultSound, "xiu")
    static let showGroup = Key<Bool>(.showGroupMessage, false)
    static let historyMessageCount = Key<Int>(.historyMessageCount, 10)
    static let freeCloudImageCount = Key<Int>(.freeCloudImageCount, 30)
    static let muteSetting = Key<[String: Date]>(.muteSetting,[:])

    static let imageSaves = Key<[String]>(.imageSaves, [])
    static let showMessageAvatar = Key<Bool>(.showMessageAvatar, false)
    static let id = Key<String>(.UserDeviceUniqueId, "")
    static let lang = Key<String>(.LocalePreferredLanguagesFirst,"")
    static let voicesAutoSpeak = Key<Bool>(.voicesAutoSpeak, false)
    static let voicesViewShow = Key<Bool>(.voicesViewShow, true)
    static let allMessagecount = Key<Int>(.allMessagecount, 0, iCloud: true)
    static let widgetURL = Key<String>(.widgetURL, "")

    static let feedback = Key<Bool>(.feedback, true)
    static let limitScanningArea = Key<Bool>(.limitScanningArea, false)
    
    static let limitMessageLine = Key<Int>(.limitMessageLine, 6)

}

enum NoletKey:String, CaseIterable{
    case deviceToken
    case voipDeviceToken
    case firstStartApp
    case autoSaveImageToPhotoAlbum
    case defaultSound
    case showGroupMessage
    case historyMessageCount
    case freeCloudImageCount
    case muteSetting
    case imageSaves
    case showMessageAvatar
    case UserDeviceUniqueId
    case LocalePreferredLanguagesFirst
    case voicesAutoSpeak
    case voicesViewShow
    case allMessagecount
    case widgetURL
    case serverArrayStroage
    case serverArrayCloudStroage
    case Meowbadgemode
    case setting_active_app_icon
    case messageExpirtionTime
    case defaultBrowserOpen
    case imageSaveDays
    case AssistantAccount
    case moreMessageCache
    case CryptoSettingFieldsList
    case SpeakTTSConfig
    case SpeakVoiceList
    case SpeakEndpoint
    case SpeakEndpointExpiry
    case SpeakVoicesCacheExpiry
    case exampleCustom
    case feedback
    case limitScanningArea
    case limitMessageLine
}
