//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet -  MuteProcessor.swift
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

class MuteProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
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
