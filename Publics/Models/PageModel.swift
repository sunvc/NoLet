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

enum SubPage: Equatable, Identifiable {
    static func == (lhs: SubPage, rhs: SubPage) -> Bool {
        switch (lhs, rhs) {
        case (.customKey, .customKey), (.scan, .scan), (.appIcon, .appIcon),
             (.cloudIcon, .cloudIcon), (.paywall, .paywall):
            return true
        case (.web(let a), .web(let b)):
            return a == b
        case (
            .quickResponseCode(let ta, let tia, let pra),
            .quickResponseCode(let tb, let tib, let prb)
        ):
            return ta == tb && tia == tib && pra == prb
        case (.crypto(let a), .crypto(let b)):
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
    case quickResponseCode(text: String, title: String?, preview: String?)
    case crypto(CryptoModelConfig)
    case share(contents: [Any])
    case nearby

    var id: String {
        switch self {
        case .customKey: "customKey"
        case .scan: "scan"
        case .appIcon: "appIcon"
        case .web: "web"
        case .cloudIcon: "cloudIcon"
        case .paywall: "paywall"
        case .quickResponseCode: "quickResponseCode"
        case .crypto: "crypto"
        case .share: "share"
        case .nearby: "nearby"
        }
    }
}

enum RouterPage: Hashable {
    case example
    case messageDetail(String)
    case sound
    case crypto
    case server
    case noletChat
    case noletChatSetting(AssistantAccount?)
    case more
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
             (.sound, .sound),
             (.crypto, .crypto),
             (.server, .server),
             (.more, .more),
             (.about, .about),
             (.dataSetting, .dataSetting):
            return true

        case (.messageDetail, .messageDetail),
             (.noletChatSetting, .noletChatSetting),
             (.noletChat, .noletChat),
             (.serverInfo, .serverInfo),
             (.files, .files),
             (.web, .web):
            return true

        default:
            return false
        }
    }
}

enum TabPage: String, Sendable, CaseIterable {
    case message
    case setting
    case assistant
}
