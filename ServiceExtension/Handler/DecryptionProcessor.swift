//
//  DecryptionProcessor.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/11/23.
//

import Foundation
import UserNotifications

final class DecryptionProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        var userInfo = bestAttemptContent.userInfo
        
        guard let ciphertext = userInfo.raw(.cipherText, as: String.self) else {
            return bestAttemptContent
        }

        do {
            let ciphertNumber = userInfo.raw(.cipherNumber, as: Int64.self) ?? 0

            let map = try decrypt(ciphertext: ciphertext, number: Int(ciphertNumber))

            var alert = [String: Any]()
            var soundName: String? = nil

            if let id = map.raw(.id, as: String.self) {
                bestAttemptContent.targetContentIdentifier = id
            }

            if let title = map.raw(.title, as: String.self) {
                bestAttemptContent.title = title
                alert[Params.title.name] = title
            }

            if let subtitle = map.raw(.subtitle, as: String.self) {
                bestAttemptContent.subtitle = subtitle
                alert[Params.subtitle.name] = subtitle
            }
            if let body = map.raw(.body, as: String.self) {
                bestAttemptContent.body = body
                alert[Params.body.name] = body
            }

            if let markdown = map.raw(.markdown, as: String.self) {
                bestAttemptContent.body = markdown
                alert[Params.body.name] = markdown
                alert[Params.style.name] = "markdown"
            }

            if let group = map.raw(.group, as: String.self) {
                bestAttemptContent.threadIdentifier = group
            }

            if var sound = map.raw(.sound, as: String.self) {
                if !sound.hasSuffix(Params.caf.name) {
                    sound = "\(sound).\(Params.caf.name)"
                }
                soundName = sound
                bestAttemptContent
                    .sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
            }

            var aps: [String: Any] = [Params.alert.name: alert]
            if let soundName {
                aps[Params.sound.name] = soundName
            }

            userInfo[Params.aps.name] = aps

            for (key, value) in map {
                userInfo[key] = value
            }

            bestAttemptContent.userInfo = userInfo

            return bestAttemptContent

        } catch {
            bestAttemptContent.title = String(localized: "解密失败!")
            bestAttemptContent.body = ciphertext
            bestAttemptContent.userInfo = [Params.aps.name: [Params.alert.name: [
                Params.body.name: bestAttemptContent.body,
                Params.title.name: bestAttemptContent.title,
            ]]]
            throw ProcessoError.error(content: bestAttemptContent)
        }
    }

    // MARK: 解密

    func decrypt(ciphertext: String, number: Int = 0) throws -> [AnyHashable: Any] {
        let cryptoConfig = Defaults[.cryptoConfigs].config(number)

        guard let json = CryptoManager(cryptoConfig).decrypt(base64: ciphertext),
              let data = json.data(using: .utf8),
              let map = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { throw NoletError("JSON parsing failed") }

        return map.reduce(into: [AnyHashable: Any]()) { $0[$1.key.lowercased()] = $1.value }
    }
}
