//
//  ToolsBox.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/28.
//

import os
import OSLog
import UIKit
import UniformTypeIdentifiers

public final class Clipboard {
    class func set(_ message: String? = nil, _ items: [String: Any]...) {
        var result: [[String: Any]] = []

        if let message { result.append([UTType.utf8PlainText.identifier: message]) }

        UIPasteboard.general.items = result + items
    }

    class func getText() -> String? {
        UIPasteboard.general.string
    }

    class func getNSAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()

        for item in UIPasteboard.general.items {
            for (type, value) in item {
                if type == "public.rtf", let data = value as? Data {
                    if let attrStr = try? NSAttributedString(data: data, options: [
                        .documentType: NSAttributedString.DocumentType.rtf,
                    ], documentAttributes: nil) {
                        result.append(attrStr)
                    }
                } else if type == "public.html", let htmlString = value as? String {
                    if let data = htmlString.data(using: .utf8),
                       let attrStr = try? NSAttributedString(data: data, options: [
                           .documentType: NSAttributedString.DocumentType.html,
                           .characterEncoding: String.Encoding.utf8.rawValue,
                       ], documentAttributes: nil)
                    {
                        result.append(attrStr)
                    }
                } else if type.hasPrefix("public.image"), let image = value as? UIImage {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    let imageAttrStr = NSAttributedString(attachment: attachment)
                    result.append(imageAttrStr)
                } else if type == "public.utf8-plain-text", let text = value as? String {
                    let textAttrStr = NSAttributedString(string: text)
                    result.append(textAttrStr)
                }
            }
        }

        return result
    }
}

public enum Haptic {
    private static var lastImpactTime: Date?
    private static var minInterval: TimeInterval = 0.2 // 最小震动间隔

    static func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        limitFrequency: Bool = false
    ) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(
        _ type: UINotificationFeedbackGenerator.FeedbackType,
        limitFrequency: Bool = false
    ) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection(limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    private static func canTrigger(limitFrequency: Bool) -> Bool {
        guard limitFrequency else { return true }
        let now = Date()
        if let last = lastImpactTime, now.timeIntervalSince(last) < minInterval {
            return false
        }
        lastImpactTime = now
        return true
    }
}

nonisolated let logger = Logger(subsystem: "app.wzs.logger", category: "main")
