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

public protocol NotificationContentProcessor: Sendable {
    /// 处理 UNMutableNotificationContent
    /// - Parameters:
    ///   - identifier: request.identifier
    ///   - bestAttemptContent: 需要处理的 UNMutableNotificationContent
    /// - Returns: 处理成功后的 UNMutableNotificationContent
    /// - Throws: 处理失败后，应该中断处理
    func processor(
        identifier: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent

    /// serviceExtension 即将终止，不管 processor 是否处理完成，最好立即调用 contentHandler 交付已完成的部分，否则会原样展示服务器传递过来的推送
    func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void)
}

extension NotificationContentProcessor {
    func serviceExtensionTimeWillExpire(contentHandler _: (UNNotificationContent) -> Void) {}
}

// enum 遵循 CaseIterable 所以所有的 handler， 按顺序从上往下对推送进行处理
// ciphertext 需要放在最前面，有可能所有的推送数据都在密文里

enum NotificationContentHandlerItem: CaseIterable {
    case ciphertext
    case archive
    case icon
    case media
    case level
    case action
    case call

    var processor: NotificationContentProcessor {
        switch self {
        case .ciphertext:
            return CiphertextHandler()
        case .archive:
            return ArchiveMessageHandler()
        case .level:
            return LevelHandler()
        case .icon:
            return IconHandler()
        case .media:
            return MediaHandler()
        case .action:
            return ActionHandler()
        case .call:
            return CallHandler()
        }
    }
}

enum NotificationContentHandlerError: Swift.Error {
    case error(content: UNMutableNotificationContent)
    case call
}
