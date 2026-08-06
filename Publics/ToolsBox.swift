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
import UIKit


@MainActor public enum Haptic {
    private static var lastImpactTime: Date?
    private static var minInterval: TimeInterval = 0.2
    private static let generator = UIImpactFeedbackGenerator(style: .medium)

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
