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

@preconcurrency import UserNotifications

nonisolated class NotificationService: UNNotificationServiceExtension {
    private let processor = NotificationProcessor()

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping @Sendable (UNNotificationContent) -> Void
    ) {
        // 【关键修复】通过局部变量捕获处理器和闭包，消除对 self 的依赖
        let processor = self.processor
        let safeHandler = contentHandler

        Task {
            // 此时闭包只捕获了 Sendable 的 actor 引用和 safeHandler，不再捕获 self
            await processor.process(request, contentHandler: safeHandler)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        super.serviceExtensionTimeWillExpire()
        let processor = self.processor
        Task {
            await processor.expire()
        }
    }
}

// 将处理逻辑封装到 actor 中以解决并发竞争
actor NotificationProcessor {
    private var currentNotificationHandler: NotificationContentProcessor?
    private var currentContentHandler: (@Sendable (UNNotificationContent) -> Void)?

    func process(
        _ request: UNNotificationRequest,
        contentHandler: @escaping @Sendable (UNNotificationContent) -> Void
    ) async {
        guard var bestAttemptContent = (request.content
            .mutableCopy() as? UNMutableNotificationContent)
        else {
            contentHandler(request.content)
            return
        }

        currentContentHandler = contentHandler

        // 依次执行 handler
        for item in NotificationContentHandlerItem.allCases {
            let handler = await item.processor
            currentNotificationHandler = handler
            do {
                bestAttemptContent = try await handler.processor(
                    identifier: request.identifier,
                    content: bestAttemptContent
                )
            } catch NotificationContentHandlerError.error(let content) {
                contentHandler(content)
                return
            } catch {
                // 【新增】处理所有其他未定义的错误（必须包含这一块）
                print("捕获到未定义错误: \(error)")
                contentHandler(bestAttemptContent)
                return
            }
        }
        contentHandler(bestAttemptContent)
    }

    func expire() async {
        if let handler = currentContentHandler,
           let currentNotificationHandler = currentNotificationHandler
        {
            await currentNotificationHandler.serviceExtensionTimeWillExpire(contentHandler: handler)
        }
    }
}
