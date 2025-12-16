//
//  PushIntent.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import AppIntents

struct PushToDeviceIntent: AppIntent {
    static let title: LocalizedStringResource = "发送通知到设备"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "服务器/ID")
    var address: String

    @Parameter(title: "通知级别", optionsProvider: LevelClassProvider())
    var level: String?

    @Parameter(title: "推送样式", optionsProvider: CategoryParamsProvider())
    var category: String?

    @Parameter(title: "铃声", optionsProvider: SoundOptionsProvider())
    var sound: String?

    @Parameter(title: "持续响铃")
    var isCall: Bool

    @Parameter(title: "重要通知音量", optionsProvider: VolumeOptionsProvider())
    var volume: Int?

    @Parameter(title: "密钥")
    var cipherKey: String?

    @Parameter(title: "推送图标")
    var icon: URL?

    @Parameter(title: "推送图片")
    var image: URL?

    @Parameter(title: "URL")
    var url: URL?

    @Parameter(title: "群组", default: "默认")
    var group: String

    @Parameter(title: "标题")
    var title: String?

    @Parameter(title: "副标题")
    var subTitle: String?

    @Parameter(title: "内容")
    var body: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        var params: [String: Any] = [:]

        if let level, !level.isEmpty,
           let level = await LevelTitle.rawValue(fromDisplayName: level)
        {
            params["level"] = level

            if await level == LevelTitle.critical.name {
                params["volume"] = volume
            }
        }

        if let sound, !sound.isEmpty, sound.lowercased() != "default" {
        
            params["sound"] = "\(sound).caf"
            
        }

        if !group.isEmpty {
            params["group"] = group
        }

        if let title, !title.isEmpty {
            params["title"] = title
        }

        if let subTitle, !subTitle.isEmpty {
            params["subtitle"] = subTitle
        }

        if let body, !body.isEmpty {
            params["body"] = body
        }

        if isCall {
            params["call"] = "1"
        }

        if let icon {
            params["icon"] = icon.absoluteString
        }

        if let image {
            params["image"] = image.absoluteString
        }

        if let category, category == "Markdown" {
            params["category"] = Identifiers.markdown.rawValue
        }

        if let url {
            params["url"] = url.absoluteString
        }

        if let cipherKey, !cipherKey.isEmpty {
            
            if let algorithm = CryptoAlgorithm(rawValue: cipherKey.count){
                var cryptoConfig = await CryptoModelConfig.data
                
                cryptoConfig.algorithm = algorithm
                cryptoConfig.key = cipherKey

                let jsonData = try JSONSerialization.data(withJSONObject: params)
                
                guard let cipherResult = await CryptoManager(cryptoConfig).encrypt(jsonData) else {
                    return .result(value: "cipher fail")
                }
                
                params["ciphertext"] = cipherResult
                params["body"] = "-"
                params.removeValue(forKey: "title")
                params.removeValue(forKey: "subtitle")
                
            }else{
                return .result(value: "Encryption key error")
            }
            
        }
        
        

        if let address = URL(string: address), await address.hasHttp {
            let res: APIPushToDeviceResponse? = try await NetworkManager()
                .fetch(
                    url: address.absoluteString,
                    method: .POST,
                    params: params
                )
            return .result(value: res?.code == 200 ? "ok" : "fail")
        } else {
            guard let token = await CloudManager.shared.queryOrUpdateDeviceToken(address) else {
                return .result(value: "Token is Empty...")
            }
           
            params.removeValue(forKey: "title")
            params.removeValue(forKey: "subtitle")
            params.removeValue(forKey: "body")
            
            let response = try await APNs.shared.push(
                token,
                id: UUID().uuidString,
                title: title,
                subtitle: subTitle,
                body: body,
                markdown: category == "Markdown",
                group: group,
                custom: params
            )
            NLog.log("response:" ,response)
            return .result(value: response.statusCode == 200 ? "ok" : response.reason ?? "fail")
        }
    }
}
