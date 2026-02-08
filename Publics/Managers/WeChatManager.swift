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
    

import WechatOpenSDK

final class WeChatManager: NSObject {
    static let shared = WeChatManager()
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

    static func sendPng(_ data: String, type: SendType = .WXSceneSession) {
        Task {
            let png = WXImageObject()

            guard let dataUrl = await ImageManager.downloadImage(data),
                  let image = UIImage(contentsOfFile: dataUrl),
                  let thumb = image.preparingThumbnail(of: CGSize(width: 100, height: 100))
            else { return }

            png.imageData = image.pngData() ?? Data()

            let message = WXMediaMessage()
            message.mediaObject = png
            message.thumbData = thumb.pngData()

            let request = SendMessageToWXReq()
            request.bText = false
            request.message = message
            request.scene = type.rawValue
            await WXApi.send(request)
        }
    }
}

extension WeChatManager: WXApiDelegate {
    func onReq(_ req: BaseReq) {}

    func onResp(_ resp: BaseResp) {}

    func register() {
        WXApi.registerApp("wx20dc05a5d82cabbe", universalLink: "https://wzs.app/")
    }

    func handleOpenUniversalLink(continue userActivity: NSUserActivity) {
        WXApi.handleOpenUniversalLink(userActivity, delegate: self)
    }
}
