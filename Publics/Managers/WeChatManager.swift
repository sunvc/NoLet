//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - WeChatManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/2/9 02:27.

import SwiftUI
import WechatOpenSDK

final nonisolated class WeChatManager: NSObject {
    @MainActor static let shared = WeChatManager()

    private override init() {
        super.init()
    }

    enum SendType: Int32, CaseIterable {
        case WXSceneSession = 0
        case WXSceneTimeline = 1
        case WXSceneFavorite = 2

        var name: String {
            switch self {
            case .WXSceneSession: String(localized: "朋友")
            case .WXSceneTimeline: String(localized: "朋友圈")
            case .WXSceneFavorite: String(localized: "收藏")
            }
        }

        var symbol: String {
            switch self {
            case .WXSceneSession: "person"
            case .WXSceneTimeline: "livephoto"
            case .WXSceneFavorite: "archivebox"
            }
        }
    }

    static func sendMessage(_ text: String, type: SendType = .WXSceneSession) {
        let request = SendMessageToWXReq()
        request.bText = true
        request.text = text
        request.scene = type.rawValue
        WXApi.send(request)
    }

    nonisolated static func sendPng(_ data: Data, type: SendType = .WXSceneSession) {
        let png = WXImageObject()
        png.imageData = data
        let message = WXMediaMessage()
        message.mediaObject = png
        message.thumbData = data.toThumbnail(max: 100)?.pngData()
        
        let request = SendMessageToWXReq()
        request.bText = false
        request.message = message
        request.scene = type.rawValue
        WXApi.send(request)
    }

    nonisolated static func sendPng(_ data: String, type: SendType = .WXSceneSession) {
        Task { 
            guard let dataUrl = await ImageManager.downloadImage(data),
                  let image = UIImage(contentsOfFile: dataUrl),
                  let data = image.pngData()
            else { return }

            Self.sendPng(data, type: type)
        }
    }

    static func isWXAppInstalled() -> Bool {
        WXApi.isWXAppInstalled()
    }
}

extension WeChatManager: WXApiDelegate {
    func onReq(_ req: BaseReq) {}

    func onResp(_ resp: BaseResp) {}

    func register() {
//        WXApi.startLog(by: .detail) { log in
//            print("WeChatSDK: \(log)")
//        }
        WXApi.registerApp("wx20dc05a5d82cabbe", universalLink: "https://wzs.app/")

//        WXApi.checkUniversalLinkReady { step, result in
//            print("\(step.rawValue), \(result.success), \(result.errorInfo),
//            \(result.suggestion)")
//        }
    }

    func handleOpenUniversalLink(continue userActivity: NSUserActivity) {
        WXApi.handleOpenUniversalLink(userActivity, delegate: self)
    }
}

extension SceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        WeChatManager.shared.handleOpenUniversalLink(continue: userActivity)
    }
}

struct ShareWeChatView: View {
    var text: String?
    var png: String?
    var symbol: String {
        if text != nil {
            return "ellipsis.message"
        }
        if png != nil {
            return "photo.on.rectangle"
        }
        return "square.and.arrow.up"
    }

    var body: some View {
        if text != nil || png != nil {
            Menu {
                ForEach(WeChatManager.SendType.allCases, id: \.self) { item in
                    Section {
                        Button {
                            if let text {
                                WeChatManager.sendMessage(text, type: item)
                            } else if let png {
                                WeChatManager.sendPng(png, type: item)
                            }

                        } label: {
                            Label(item.name, systemImage: item.symbol)
                        }
                    }
                }
            } label: {
                Label("分享到微信", systemImage: symbol)
            }
        }
    }
}
