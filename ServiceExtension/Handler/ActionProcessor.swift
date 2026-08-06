//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ActionProcessor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/7 12:40.

import Defaults
import UIKit
import UniformTypeIdentifiers

final class ActionProcessor: NotificationContentProcessor {
    
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        
        let userInfo = bestAttemptContent.userInfo
        
        bestAttemptContent.interruptionLevel = bestAttemptContent.level
        
        // badge
        if let badge = userInfo.raw(.badge, as: Int64.self) {
            bestAttemptContent.badge = NSNumber(value: badge)
            if badge <= 0 {
                // Server says clear: reset the shared counter; the app marks all read on drain.
                Defaults[.sharedUnreadCount] = 0
            } else {
                // Server authoritative badge.
                Defaults[.sharedUnreadCount] = Int(badge)
            }
        } else {
            bestAttemptContent.badge = NSNumber(value: Defaults[.sharedUnreadCount])
        }
        
        // MARK: - 静音分组

        for setting in Defaults[.muteSetting] {
            if setting.value < Date() {
                Defaults[.muteSetting].removeValue(forKey: setting.key)
            }
        }

        if let date = Defaults[.muteSetting][bestAttemptContent.threadIdentifier], date > Date() {
            bestAttemptContent.interruptionLevel = .passive
        }
        
        return bestAttemptContent
    }
}
