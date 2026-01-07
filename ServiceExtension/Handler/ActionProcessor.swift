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
@preconcurrency import UserNotifications

class ActionProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        // MARK: -  回调

        if let host: String = bestAttemptContent.userInfo.raw(.host),
           let id = bestAttemptContent.targetContentIdentifier
        {
            _ = try? await NetworkManager()
                .fetch(url: host, params: ["id": id])
        }

        return bestAttemptContent
    }
}
