//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/3.
//

import Foundation
@preconcurrency import UserNotifications
import OSLog

let logger = Logger(subsystem: "app.wzs.logger", category: "NotificationService")


class NotificationService: UNNotificationServiceExtension {
    private var contentActor: NotificationServiceActor?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping @Sendable (UNNotificationContent) -> Void
    ) {
        guard let bestAttemptContent = request.content
            .mutableCopy() as? UNMutableNotificationContent
        else {
            contentHandler(request.content)
            return
        }
        
        contentActor = NotificationServiceActor(bestAttemptContent, contentHandler: contentHandler)

        let identifier = request.identifier

        guard let contentActor = contentActor else {
            contentHandler(request.content)
            return
        }

        Task {
            await contentActor.process(identifier: identifier)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        super.serviceExtensionTimeWillExpire()
        guard let contentActor = contentActor else { return }

        Task {
            await contentActor.completed()
        }
    }
}
