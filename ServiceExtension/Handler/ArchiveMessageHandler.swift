//
//  ArchiveMessageHandler.swift
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

import UserNotifications
import Defaults
import Foundation


final class ArchiveMessageHandler: NotificationContentProcessor,Sendable {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        let body: String = {
            if let body: String = userInfo.raw(.body) {
                /// 解决换行符渲染问题
                return MessagesManager.ensureMarkdownLineBreaks(body)
            }
            return ""
        }()

        // MARK: - markdownbody body 显示
        if bestAttemptContent.categoryIdentifier == Identifiers.markdown.rawValue {
            let plainText = PBMarkdown.plain(body).components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .joined(separator: ",")
                .replacingOccurrences(of: "\n", with: "")

            bestAttemptContent.body = plainText
                .count > 15 ? String(plainText.prefix(15)) + "..." : plainText
        }

        let group: String = userInfo.raw(.group) ?? String(localized: "默认")
        bestAttemptContent.threadIdentifier = group

        let ttl: String? = userInfo.raw(.ttl)
        let title: String? = userInfo.raw(.title)
        let subtitle: String? = userInfo.raw(.subtitle)
        let url: String? = userInfo.raw(.url)
        let icon: String? = userInfo.raw(.icon)
        let image: String? = userInfo.raw(.image)
        let host: String? = userInfo.raw(.host)
        let messageID = bestAttemptContent.targetContentIdentifier
        let level = bestAttemptContent.getLevel()
        let other = userInfo.toJSONString(excluding: Params.allCases.allString())

        //  获取保存时间
        var saveDays: Int {
            if let isArchive = ttl, let saveDaysTem = Int(isArchive) {
                return saveDaysTem
            } else {
                return Defaults[.messageExpiration].days
            }
        }

        Defaults[.allMessagecount] += 1

        guard title != nil || subtitle != nil || !body.isEmpty else {
            bestAttemptContent.interruptionLevel = .passive
            return bestAttemptContent
        }
        
        guard saveDays > 0 else { return bestAttemptContent }

        //  保存数据到数据库
        let message = Message(
            id: messageID ?? UUID().uuidString,
            createDate: .now,
            group: group,
            title: title,
            subtitle: subtitle,
            body: body,
            icon: icon,
            url: url,
            image: image,
            host: host,
            level: Int(level),
            ttl: saveDays,
            isRead: false,
            other: other
        )

        Task.detached(priority: .userInitiated) {
            await MessagesManager.shared.add(message)
        }

        return bestAttemptContent
    }
}
