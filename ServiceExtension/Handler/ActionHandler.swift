//
//  ActionHandler.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/11/14.
//

import cmark_gfm
import Defaults
import Foundation
import Intents
import SwiftUI
import UserNotifications

class ActionHandler: NotificationContentHandler {
    func handler(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        // MARK: - 处理 Ringtone

        let call: Int? = bestAttemptContent.userInfo.raw(.call)
        if call != 1, bestAttemptContent.soundName == nil, bestAttemptContent.getLevel() < 3 {
            bestAttemptContent
                .sound =
                UNNotificationSound(
                    named: UNNotificationSoundName(rawValue: "\(Defaults[.sound]).caf")
                )
        }

        // MARK: - 处理 badge

        if let badgeStr: String = bestAttemptContent.userInfo.raw(.badge),
           let badge = Int(badgeStr)
        {
            if badge <= 0 {
                await MessagesManager.shared.markAllRead()
            }
            bestAttemptContent.badge = NSNumber(value: badge)
        }

        // MARK: - 删除过期消息

        await MessagesManager.shared.deleteExpired()

        // MARK: - 静音分组

        for setting in Defaults[.muteSetting] {
            if setting.value < Date() {
                Defaults[.muteSetting].removeValue(forKey: setting.key)
            }
        }

        if let date = Defaults[.muteSetting][bestAttemptContent.threadIdentifier], date > Date() {
            bestAttemptContent.interruptionLevel = .passive
        }

        // MARK: -  回调

        if let host: String = bestAttemptContent.userInfo.raw(.host),
           let id = bestAttemptContent.targetContentIdentifier
        {
            _ = try? await NetworkManager()
                .fetch(url: host, params: ["id": id])
        }

        let mores = Defaults[.moreMessageCache]
        if mores.count > 0 {
            let oneHourAgo = Date().addingTimeInterval(-3600)
            Defaults[.moreMessageCache].removeAll { message in
                message.createDate < oneHourAgo
            }
        }

        return bestAttemptContent
    }
}
