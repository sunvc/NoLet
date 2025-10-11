//
//  PageModel.swift
//  pushme
//
//  Created by lynn on 2025/6/18.
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
    case web(String)
    case cloudIcon
    case paywall
    case quickResponseCode(text:String,title: String?,preview: String?)
    case crypto(CryptoModelConfig)
    case none
    case share(contents: [Any])
    
}

enum RouterPage: Hashable, Equatable {
    case example
    case messageDetail(String)
    case assistant
    case sound
    case crypto
    case server
    case assistantSetting(AssistantAccount?)
    case more
    case widget(title:String?, data:String)
    case tts
    case pushtalk
    case about
    case dataSetting
    case serverInfo(server: PushServerModel?)
    case files(url: URL)
}





enum TabPage: String, Sendable, CaseIterable{
    case message
    case setting
    case search
}

enum outRouterPage: String{
    case widget
    case icon
}
