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

import Defaults
import Foundation
import UserNotifications

class ArchiveProcessor: NotificationContentProcessor {
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

        if let _: String = bestAttemptContent.userInfo.raw(.reply) {
            bestAttemptContent.categoryIdentifier = Identifiers.reply.rawValue
        }

        switch Identifiers(rawValue: bestAttemptContent.categoryIdentifier) {
        case .markdown, .reply:
            let plainText = PBMarkdown.plain(body).components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .joined(separator: ",")
                .replacingOccurrences(of: "\n", with: "")

            bestAttemptContent.body = plainText.markdownPre()
        default:
            bestAttemptContent.categoryIdentifier = Identifiers.myNotificationCategory.rawValue
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
        let reply: String? = userInfo.raw(.reply)
        let messageID = bestAttemptContent.targetContentIdentifier
        let level = bestAttemptContent.level.rawValue
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
            reply: reply,
            level: Int(level),
            ttl: saveDays,
            isRead: false,
            other: other
        )

        await MessagesManager.shared.add(message)
        await MessagesManager.shared.deleteExpired()

        return bestAttemptContent
    }
}
