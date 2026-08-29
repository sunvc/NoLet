//
//  NotificationProtocol.swift
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
import os
@preconcurrency import UserNotifications

actor NotificationServiceActor {
    var bestAttemptContent: UNMutableNotificationContent
    var handler: (UNNotificationContent) -> Void

    init(
        _ content: UNMutableNotificationContent,
        contentHandler: @escaping @Sendable (UNNotificationContent) -> Void
    ) {
        bestAttemptContent = content
        handler = contentHandler
    }

    func process(identifier: String) async {
        do {
            for item in ProcessorItem.allCases {
                bestAttemptContent = try await item.processor.processor(
                    identifier: identifier,
                    content: bestAttemptContent
                )
            }
            completed()
        } catch ProcessoError.error(let errorContent) {
            self.bestAttemptContent = errorContent
            self.completed()
        } catch ProcessoError.stop(content: let content) {
            self.bestAttemptContent = content
            self.completed()
        } catch {
            completed()
        }
    }

    func completed() {
        handler(bestAttemptContent)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(NCONFIG.notificationName as CFString),
            nil,
            nil,
            true
        )
    }
}

enum ProcessorItem: CaseIterable {
    case plugin
    case decryption
    case action
    case archive
    case call
    case attachment
    case script

    var processor: NotificationContentProcessor {
        switch self {
        case .plugin: PluginProcessor()
        case .decryption: DecryptionProcessor()
        case .archive: ArchiveProcessor()
        case .action: ActionProcessor()
        case .attachment: AttachmentProcessor()
        case .call: CallProcessor()
        case .script: ScriptProcessor()
        }
    }
}

protocol NotificationContentProcessor: Sendable {
    func processor(
        identifier: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent
}

enum ProcessoError: Swift.Error {
    case error(content: UNMutableNotificationContent)
    case stop(content: UNMutableNotificationContent)
}
