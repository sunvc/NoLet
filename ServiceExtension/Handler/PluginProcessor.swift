//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PluginProcessor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//

//  Description: 通知插件处理器 — 在通知服务扩展里执行用户 JS 脚本，
//               脚本通过注入的原生方法修改通知内容（附件、声音、角标、
//               interruptionLevel、头像、分类等），或把消息落盘供主程序入库。

//  History:
//    Created by Neo on 2026/8/23 18:28.
//

import AVFAudio
import Defaults
import Foundation
import Intents
@preconcurrency import JavaScriptCore
import UIKit
import UniformTypeIdentifiers
import UserNotifications

final class PluginProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        
        // TODO: - 下次更新时添加
        if let name = bestAttemptContent.userInfo.raw(.plugin, as: String.self),
           let code = Defaults[.scripts].first(where: { $0.name == name })
        {
            debugPrint(code.name)
            throw ProcessoError.stop(content: bestAttemptContent)
        }
        return bestAttemptContent
    }


}

/// 类型擦除盒子，供 @convention(block) 闭包共享可变 content。
final private class PluginBox: @unchecked Sendable {
    var content: UNMutableNotificationContent
    init(_ c: UNMutableNotificationContent) { content = c }
}
