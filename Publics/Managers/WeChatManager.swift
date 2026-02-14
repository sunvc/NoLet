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

import CryptoKit
import SwiftUI
import WechatOpenSDK

final class WeChatManager: NetworkManager, ObservableObject {
    static let shared = WeChatManager()

    @Published var QRCodeImage: UIImage? = nil
    @Published var QRCodeLoading: Bool = false

    private override init() {
        super.init()
    }

    private var auth: WechatAuthSDK?

    private var appid = "wx20dc05a5d82cabbe"
    private var secret = ""
    private var universalLink = "https://wzs.app/"

    nonisolated static func sendMessage(_ text: String, type: SendType = .WXSceneSession) {
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
        message.thumbData = data.toThumbnail()?.jpegData(compressionQuality: 1)

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

    nonisolated static func isWXAppInstalled() -> Bool {
        WXApi.isWXAppInstalled()
    }

    static func auth() {
        let req = SendAuthReq()
        req.scope = "snsapi_userinfo"
        req.state = "nolet"

        WXApi.send(req)
    }

    func requestAuth(code: String) async -> WeChatTokenResponse? {
        do {
            let url = "https://api.weixin.qq.com/sns/oauth2/access_token"

            let params: [String: Any] = [
                "appid": self.appid,
                "secret": self.secret,
                "code": code,
                "grant_type": "authorization_code",
            ]

            let data = try await self.fetch(url: url, method: .GET, params: params, headers: [:])

            let res: WeChatTokenResponse = try data.decode()

            return res
        } catch {
            logger.error("\(error)")
        }

        return nil
    }

    func getAccessToken() async -> WeChatAccessTokenResponse? {
        do {
            let url = "https://api.weixin.qq.com/cgi-bin/stable_token"

            let params = [
                "grant_type": "client_credential",
                "appid": self.appid,
                "secret": self.secret,
            ]

            let response = try await self.fetch(url: url, method: .POST, params: params)

            let data: WeChatAccessTokenResponse = try response.decode()
            return data
        } catch {
            logger.error("\(error)")
            return nil
        }
    }

    func generateWeChatSignature(params: [String: String]) -> String {
        let sortedKeys = params.keys.sorted()

        let string1 = sortedKeys
            .map { "\($0.lowercased())=\(params[$0]!)" }
            .joined(separator: "&")
        let data = Data(string1.utf8)
        let hash = Insecure.SHA1.hash(data: data)

        let signature = hash.map { String(format: "%02x", $0) }.joined()

        return signature
    }
}

extension WeChatManager: WechatAuthAPIDelegate {
    func qrCode() async {
        self.QRCodeLoading = true

        self.auth = WechatAuthSDK()
        self.auth?.delegate = self

        guard let response = await getAccessToken(),
              let ticket = await self.get_sdk_ticket(accessToken: response.accessToken)?.ticket
        else { return }

        let timeStamp = "\(Int(Date().timeIntervalSince1970))"
        let scope = "snsapi_userinfo"
        let schemeData = "nolet"
        let random = Domap.generateRandomString()

        let params = [
            "appid": self.appid,
            "sdk_ticket": ticket,
            "nonceStr": random,
            "timeStamp": timeStamp,
        ]

        let sign = self.generateWeChatSignature(params: params)

        self.auth?.auth(
            self.appid,
            nonceStr: random,
            timeStamp: timeStamp,
            scope: scope,
            signature: sign,
            schemeData: schemeData
        )
    }

    func get_sdk_ticket(accessToken: String) async -> WeChatTicketResponse? {
        do {
            let url = "https://api.weixin.qq.com/cgi-bin/ticket/getticket"
            let params = [
                "access_token": accessToken,
                "type": "2",
            ]

            let response = try await self.fetch(url: url, params: params)

            let data: WeChatTicketResponse = try response.decode()

            return data
        } catch {
            logger.error("\(error)")
            return nil
        }
    }

    func onAuthGotQrcode(_ image: UIImage) {
        self.QRCodeImage = image
        self.QRCodeLoading = false
    }

    func onQrcodeScanned() {
        self.QRCodeImage = nil
    }

    func onAuthFinish(_ errCode: Int32, authCode: String?) {
        logger.log("\(errCode)\(authCode)")
    }
}

extension WeChatManager: WXApiDelegate {
    func onReq(_ req: BaseReq) {
        logger.log("\(req)")
    }

    func getUserInfo(token: String, id: String) async -> WeChatUserResponse? {
        do {
            let url = "https://api.weixin.qq.com/sns/userinfo?access_token=\(token)&openid=\(id)"
            let data = try await self.fetch(url: url)
            let res: WeChatUserResponse = try data.decode()
            return res
        } catch {
            logger.error("\(error)")
            return nil
        }
    }

    func onResp(_ resp: BaseResp) {
        logger.log("\(resp)")

        if let res = resp as? SendAuthResp, res.errCode == 0, let code = res.code,
           let state = res.state
        {
            Task {
                if let data = await requestAuth(code: code), let id = data.openid {
                    logger.log("\(state) - \(id)")
                }
            }
        }
    }

    func register() {
//        #if DEBUG
//        WXApi.startLog(by: .detail) { log in
//            print("WeChatSDK: \(log)")
//        }
//        #endif
        WXApi.registerApp(self.appid, universalLink: self.universalLink)
//        #if DEBUG
//        WXApi.checkUniversalLinkReady { step, result in
//            print("\(step.rawValue), \(result.success), \(result.errorInfo),\(result.suggestion)")
//        }
//        #endif
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

nonisolated extension WeChatManager {
    nonisolated struct WeChatTokenResponse: Codable {
        let accessToken: String?
        let expiresIn: Int?
        let refreshToken: String?
        let openid: String?
        let scope: String?

        let errcode: Int?
        let errmsg: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case openid
            case scope
            case errcode
            case errmsg
        }
    }

    nonisolated struct WeChatUserResponse: Codable {
        // 成功字段
        let openid: String?
        let nickname: String?
        let sex: Int?
        let province: String?
        let city: String?
        let country: String?
        let headimgurl: String?
        let privilege: [String]?
        let unionid: String?

        // 错误字段
        let errcode: Int?
        let errmsg: String?

        var isSuccess: Bool {
            return errcode == nil
        }
    }

    nonisolated struct WeChatTicketResponse: Codable {
        let errcode: Int
        let errmsg: String
        let ticket: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case errcode
            case errmsg
            case ticket
            case expiresIn = "expires_in"
        }

        var isSuccess: Bool {
            return errcode == 0
        }
    }

    nonisolated enum SendType: Int32, CaseIterable {
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

    nonisolated struct WeChatAccessTokenResponse: Codable {
        let accessToken: String
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }
}
