//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - BadgeProcessor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/7 12:39.

import Defaults
import UIKit
import UniformTypeIdentifiers

final class BadgeProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        // MARK: - 处理 badge
        //
        // Extensions must not touch the database. The unread counter lives in the
        // App Group UserDefaults (Default[.sharedUnreadCount]); the main app syncs
        // it when it drains the pending-message inbox.

        if let badgeStr: String = bestAttemptContent.userInfo.raw(.badge),
           let badge = Int(badgeStr)
        {
            bestAttemptContent.badge = NSNumber(value: badge)
            if badge <= 0 {
                // Server says clear: reset the shared counter; the app marks all read on drain.
                Defaults[.sharedUnreadCount] = 0
            } else {
                // Server authoritative badge.
                Defaults[.sharedUnreadCount] = badge
            }
        } else {
            bestAttemptContent.badge = NSNumber(value: Defaults[.sharedUnreadCount])
        }

        return bestAttemptContent
    }
}
