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

final class ArchiveProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        var body: String = {
            if let body: String = userInfo.raw(.body) {
                return ensureMarkdownLineBreaks(body)
            }
            return ""
        }()

        // MARK: - markdownbody body 显示

        let reply: String? = userInfo.raw(.reply)
        if reply != nil {
            bestAttemptContent.categoryIdentifier = Identifiers.reply.rawValue
        }

        var style: String? = userInfo.raw(.style)

        if let location: String = userInfo.raw(.location), let location = location.location() {
            let location = normalizeToLatLngGlobal(location)
            let address = await CLGeocoderManager.shared.getFormattedAddress(
                latitude: location.0,
                longitude: location.1
            )
            body += "\n[\(address)]"
            bestAttemptContent.body = body
        }

        switch Identifiers(rawValue: bestAttemptContent.categoryIdentifier) {
        case .markdown:
            if style == nil { style = "markdown" }
            let plainText = PBMarkdown.plain(body).components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .joined(separator: ",")
                .replacingOccurrences(of: "\n", with: "")

            bestAttemptContent.body = plainText.markdownPre()

        case .reply:
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

        let ttl: Int64? = userInfo.raw(.ttl)
        let title: String? = userInfo.raw(.title)
        let subtitle: String? = userInfo.raw(.subtitle)
        let url: String? = userInfo.raw(.url)
        let icon: String? = userInfo.raw(.icon)
        let image: String? = userInfo.raw(.image)
        let messageID = bestAttemptContent.targetContentIdentifier

        let other = userInfo.toJSONString(excluding: Params.names)

        var seconds: Int64 {
            if let ttl{
                return ttl
            } else {
                return Int64(Defaults[.messageExpiration].seconds)
            }
        }
        
        

        Defaults[.allMessagecount] += 1

        guard title != nil || subtitle != nil || !body.isEmpty else {
            bestAttemptContent.interruptionLevel = .passive
            return bestAttemptContent
        }

        guard seconds > 0 else { return bestAttemptContent }

        var json: [AnyHashable: Any] = [
            "id": messageID ?? UUID().uuidString,
            "createDate": Int(Date.now.timeIntervalSince1970),
            "group": group,
            "body": body,
            "ttl": seconds,
            "read": false,
        ]
        if let title { json["title"] = title }
        if let subtitle { json["subtitle"] = subtitle }
        if let icon { json["icon"] = icon }
        if let url { json["url"] = url }
        if let image { json["image"] = image }
        if let reply { json["reply"] = reply }
        if let style { json["style"] = style }
        if let other { json["other"] = other }

        let isNew = PendingMessageStore().write(json)
        if isNew {
            Defaults[.sharedUnreadCount] += 1
        }

        return bestAttemptContent
    }

    func ensureMarkdownLineBreaks(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)

        let processedLines = lines.map { line in
            if line.hasSuffix("  ") || line.isEmpty {
                return line
            } else {
                return line + "  "
            }
        }

        return processedLines.joined(separator: "\n")
    }

    func normalizeToLatLngGlobal(_ coordinates: (Double, Double)) -> (Double, Double) {
        let a = coordinates.0
        let b = coordinates.1

        let aCanBeLat = abs(a) <= 90.0
        let bCanBeLat = abs(b) <= 90.0
        let aCanBeLng = abs(a) <= 180.0
        let bCanBeLng = abs(b) <= 180.0

        if !aCanBeLat, bCanBeLat, aCanBeLng {
            return (b, a)
        }

        if !bCanBeLat, aCanBeLat, bCanBeLng {
            return (a, b)
        }

        return coordinates
    }
}

fileprivate extension String {
    func markdownPre(_ max: Int = 15) -> Self {
        count > max ? String(prefix(max)) + "..." : self
    }
}
