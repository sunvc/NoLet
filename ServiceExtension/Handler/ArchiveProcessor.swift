//
//  ArchiveMessageProcessor.swift
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

final class ArchiveProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        
        let userInfo = bestAttemptContent.userInfo

        let body = userInfo.raw(.body, as: String.self) ?? ""
        let title = userInfo.raw(.title, as: String.self)
        let subtitle = userInfo.raw(.subtitle, as: String.self)
        let url = userInfo.raw(.url, as: String.self)

        let reply = userInfo.raw(.reply, as: String.self)
        var style = userInfo.raw(.style, as: String.self)
        let group = userInfo.raw(.group, as: String.self) ?? String(localized: "默认")
        let messageID = bestAttemptContent.targetContentIdentifier ?? UUID().uuidString
        let other = userInfo.toJSONString(excluding: Params.names)

        var expiration: Int64 {
            if let ttl = userInfo.raw(.ttl, as: Int64.self) {
                return ttl < 0 ? -1 : Int64(Date.now.timeIntervalSince1970) + ttl
            } else {
                return Defaults[.messageExpiration].messageTTL()
            }
        }

        if reply != nil {
            bestAttemptContent.categoryIdentifier = Identifiers.reply.rawValue
        }

        switch Identifiers(rawValue: bestAttemptContent.categoryIdentifier) {
        case .markdown:
            style = Params.markdown.name
            let plainText = PBMarkdown.plain(body).components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .joined(separator: ",")
                .replacingOccurrences(of: "\n", with: "")

            bestAttemptContent.body = plainText.count > 15 ?
                String(plainText.prefix(15)) + "..." : plainText

        case .reply:
            style = Params.reply.name

        default:
            bestAttemptContent.categoryIdentifier = Identifiers.myNotificationCategory.rawValue
        }

        bestAttemptContent.threadIdentifier = group

        Defaults[.allMessagecount] += 1

        guard title != nil || subtitle != nil || !body.isEmpty else {
            bestAttemptContent.interruptionLevel = .passive
            return bestAttemptContent
        }

        guard expiration < 0 || expiration > Int64(Date.now.timeIntervalSince1970)
        else { return bestAttemptContent }

        var json: [AnyHashable: Any] = [:]
        json[.id] = messageID
        json[.createDate] = Int64(Date.now.timeIntervalSince1970)
        json[.group] = group
        json[.body] = body
        json[.ttl] = expiration
        json[.read] = false

        if let title { json[.title] = title }
        if let subtitle { json[.subtitle] = subtitle }
        if let url { json[.url] = url }
        if let style { json[.style] = style }
        if let other { json[.other] = other }

        let isNew = PendingMessageStore().write(json)
        if isNew {
            Defaults[.sharedUnreadCount] += 1
        }

        return bestAttemptContent
    }
}
