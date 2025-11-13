//
//  PageModel.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/18.
//
import Foundation

// MARK: - Page model
enum SubPage: Equatable{
    static func == (lhs: SubPage, rhs: SubPage) -> Bool {
        switch (lhs, rhs) {
        case (.customKey, .customKey),(.scan, .scan),(.appIcon, .appIcon),
            (.cloudIcon, .cloudIcon), (.paywall, .paywall),(.none, .none):
            return true
        case let (.web(a), .web(b)):
            return a == b
        case let (.quickResponseCode(ta, tia, pra), .quickResponseCode(tb, tib, prb)):
            return ta == tb && tia == tib && pra == prb
        case let (.crypto(a), .crypto(b)):
            return a == b
        default:
            return false
        }
    }
    
    case customKey
    case scan
    case appIcon
    case web(URL)
    case cloudIcon
    case paywall
    case quickResponseCode(text:String,title: String?,preview: String?)
    case crypto(CryptoModelConfig)
    case none
    case share(contents: [Any])
    case nearby
    
}

enum RouterPage: Hashable{
    case example
    case messageDetail(String)
    case assistant
    case sound
    case crypto
    case server
    case assistantSetting(AssistantAccount?)
    case more
    case tts
    case about
    case dataSetting
    case serverInfo(server: PushServerModel)
    case files(url: URL)
    case web(url: URL)
}


extension RouterPage: Equatable {
    static func == (lhs: RouterPage, rhs: RouterPage) -> Bool {
        switch (lhs, rhs) {
        case (.example, .example),
             (.assistant, .assistant),
             (.sound, .sound),
             (.crypto, .crypto),
             (.server, .server),
             (.more, .more),
             (.tts, .tts),
             (.about, .about),
             (.dataSetting, .dataSetting):
            return true

        case (.messageDetail, .messageDetail),
             (.assistantSetting, .assistantSetting),
             (.serverInfo, .serverInfo),
             (.files, .files),
             (.web, .web):
            return true

        default:
            return false
        }
    }
}




enum TabPage: String, Sendable, CaseIterable{
    case message
    case setting
    case search
}
