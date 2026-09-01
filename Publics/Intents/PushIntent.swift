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

    @Parameter(title: "持续响铃", default: false)
    var isCall: Bool

    @Parameter(title: "重要通知音量", optionsProvider: VolumeOptionsProvider())
    var volume: Int?

    @Parameter(title: "角标")
    var badge: Int?

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

    @Parameter(title: "回复")
    var reply: String?

    @Parameter(title: "脚本", optionsProvider: ScriptOptionsProvider())
    var script: String?

    @Parameter(title: "标题")
    var title: String?

    @Parameter(title: "副标题")
    var subTitle: String?

    @Parameter(title: "内容")
    var body: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        var params: [String: String] = [:]

        // level 用数字传递：服务端与通知扩展都兼容 0 passive / 1 active / 2 timeSensitive / 3 critical
        if let level, !level.isEmpty,
           let levelTitle = LevelTitle.allCases.first(where: { $0.name == level })
        {
            params["level"] = String(LevelTitle.allCases.firstIndex(of: levelTitle) ?? 1)

            if levelTitle == .critical {
                params["volume"] = String(volume ?? 5)
            }
        }

        if let badge {
            params["badge"] = String(badge)
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

        if let category, !category.isEmpty,
           let identifier = Identifiers.allCases.first(where: { $0.name == category })?.rawValue
        {
            params["category"] = identifier
        }

        if let url {
            params["url"] = url.absoluteString
        }

        if let reply, !reply.isEmpty {
            params["reply"] = reply
        }

        if let script, !script.isEmpty {
            params["script"] = script
        }

        var encrypted = false

        if let cipherKey, !cipherKey.isEmpty {
            guard let algorithm = CryptoAlgorithm(rawValue: cipherKey.count) else {
                return .result(value: "Encryption key error")
            }

            var cryptoConfig = CryptoModelConfig.data
            cryptoConfig.algorithm = algorithm
            cryptoConfig.key = cipherKey

            let jsonData = try JSONSerialization.data(withJSONObject: params)

            guard let cipherResult = CryptoManager(cryptoConfig).encrypt(jsonData) else {
                return .result(value: "cipher fail")
            }

            params["ciphertext"] = cipherResult
            params["body"] = "-"
            params.removeValue(forKey: "title")
            params.removeValue(forKey: "subtitle")
            encrypted = true
        }

        do {
            if URL(remote: address) != nil {
                let data = try await NetworkManager()
                    .fetch(url: address, method: .POST, body: params)
                let res: APIPushToDeviceResponse? = try data.decode()
                return .result(value: res?.code == 200 ? "ok" : "fail")
            } else {
                guard let member = try await MemberModel.fetch(
                    id: address,
                    from: NCONFIG.publicCloudDatabase
                ) else {
                    return .result(value: "Token is Empty...")
                }

                params.removeValue(forKey: "title")
                params.removeValue(forKey: "subtitle")
                params.removeValue(forKey: "body")

                // 加密推送明文只放占位符，真实内容由通知扩展解密后填充
                let response = try await APNs.shared.push(
                    member.token,
                    id: UUID().uuidString,
                    title: encrypted ? nil : title,
                    subtitle: encrypted ? nil : subTitle,
                    body: encrypted ? "-" : body,
                    markdown: category == Identifiers.markdown.name,
                    category: params["category"],
                    group: group,
                    custom: params
                )

                logger.info("response: \(String(describing: response))")
                return .result(value: response.statusCode == 200 ? "ok" : response.reason ?? "fail")
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            return .result(value: "\(error.localizedDescription)")
        }
    }
}
