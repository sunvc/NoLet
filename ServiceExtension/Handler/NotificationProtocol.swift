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
@preconcurrency import UserNotifications

/// 使用 Actor 保证 Content 的并发访问安全，并封装处理逻辑
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
        } catch {
            completed()
        }
    }

    func completed() {
        handler(bestAttemptContent)
    }
}

enum ProcessorItem: CaseIterable {
    case ciphertext
    case archive
    case badge
    case mute
    case level
    case action
    case attachment
    case icon

    var processor: NotificationContentProcessor {
        switch self {
        case .ciphertext: CiphertextProcessor()
        case .archive: ArchiveProcessor()
        case .badge: BadgeProcessor()
        case .mute: MuteProcessor()
        case .icon: IconProcessor()
        case .attachment: AttachmentProcessor()
        case .action: ActionProcessor()
        case .level: LevelProcessor()
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
}
