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
import UIKit

// MARK: - Page model

enum SubPage: Equatable, Identifiable {
    case customKey
    case scan
    case appIcon
    case web(URL)
    case cloudIcon
    case paywall
    case quickResponseCode(text: String, title: String?, preview: String?)
    case crypto(CryptoModelConfig)
    case share(contents: [AnyHashable], preview: UIImage?, title: String?)
    case cloudServer
    case authView

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
        case .cloudServer: "cloudServer"
        case .authView: "authView"
        }
    }
}

enum RouterPage: Hashable, Equatable {
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
    case appleServerInfo
    case files(url: URL)
    case web(url: URL)
    case ptt
}
enum TabPage: String, Sendable, CaseIterable {
    case message
    case setting
    case assistant
    case ptt
}
