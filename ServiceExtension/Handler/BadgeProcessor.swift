//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - BadgeProcessor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/7 12:39.

import Defaults
import UIKit
import UniformTypeIdentifiers

class BadgeProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        // MARK: - 处理 badge

        if let badgeStr: String = bestAttemptContent.userInfo.raw(.badge),
           let badge = Int(badgeStr)
        {
            if badge <= 0 {
                await MessagesManager.shared.markAllRead()
            }
            bestAttemptContent.badge = NSNumber(value: badge)
        }else{
            let badge = await MessagesManager.shared.unreadCount()
            bestAttemptContent.badge = NSNumber(value: badge)
        }

        return bestAttemptContent
    }
}
