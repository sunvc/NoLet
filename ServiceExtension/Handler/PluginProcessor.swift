//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PluginProcessor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//

//  Description: 通知插件处理器 — 在通知服务扩展里执行用户 JS 插件脚本。
//               插件位于处理链首，命中后通过注入的原生方法接管扩展的全部
//               操作：读写通知内容、附件（图片/地图）、发送者头像、声音
//               （内置/下载/TTS）、消息落盘、角标、解密等，然后终止原生链。
//
//               脚本入口为 async function(note)，note 含通知快照；可用的
//               原生全局方法见 PluginProcessor.pluginMethods。脚本正常返回
//               即视为接管（停止后续原生处理器）；返回 { continue: true }
//               放行并保留修改，{ continue: "original" } 放行但丢弃修改、
//               在原始通知上继续；抛错则回退到原生链。
//
//  History:
//    Created by Neo on 2026/8/23 18:28.
//

import Defaults
import Foundation
import os
import UIKit
import UserNotifications

final class PluginProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        guard let name = userInfo.raw(.plugin, as: String.self),
              let code = Defaults[.scripts]
                  .first(where: { $0.name == name && $0.mode == .plugin }),
              let source = try? String(contentsOf: code.file, encoding: .utf8)
        else {
            return bestAttemptContent
        }

        // host 在副本上操作，原始 content 保留：放行时脚本可选择回到未修改的内容。
        let working = (bestAttemptContent.mutableCopy() as? UNMutableNotificationContent) ?? bestAttemptContent
        let host = PluginHost(content: working)
        let runtime = JSRuntime(
            scriptSource: source,
            namespace: code.file.deletingPathExtension().lastPathComponent,
            exceptionHandler: { logger.error("plugin \($0)") },
            methods: Self.pluginMethods(host: host)
        )

        let outcome: PluginOutcome
        do {
            let result = try await runtime.call(arguments: [Self.snapshot(bestAttemptContent)])
            outcome = Self.outcome(from: result)
        } catch {
            // 脚本出错：保留已做的修改，但交回原生链继续处理，避免投递半成品。
            logger.error("plugin \(name) failed: \(error.localizedDescription)")
            return host.snapshot()
        }

        switch outcome {
        case .takeOver:
            throw ProcessoError.stop(content: host.snapshot())
        case .continueModified:
            return host.snapshot()
        case .continueOriginal:
            return bestAttemptContent
        }
    }

    private enum PluginOutcome {
        case takeOver
        case continueModified
        case continueOriginal
    }

    /// 解析脚本返回值：
    /// - 无 `continue` → 接管，终止原生链；
    /// - `continue: true` → 放行，原生链在**插件修改后**的内容上继续；
    /// - `continue: "original"` → 放行，但丢弃修改，原生链在**原始通知**上继续。
    private static func outcome(from result: Any?) -> PluginOutcome {
        let cont = (result as? [AnyHashable: Any])?["continue"]
        if let s = cont as? String {
            return s.lowercased() == "original" ? .continueOriginal : .takeOver
        }
        if let n = cont as? NSNumber, n.boolValue {
            return .continueModified
        }
        return .takeOver
    }

    private static func snapshot(_ c: UNMutableNotificationContent) -> [String: Any] {
        [
            "id": c.targetContentIdentifier ?? "",
            Params.title.name: c.title,
            Params.subtitle.name: c.subtitle,
            Params.body.name: c.body,
            Params.group.name: c.threadIdentifier,
            Params.category.name: c.categoryIdentifier,
            Params.badge.name: c.badge ?? 0,
            Params.level.name: levelName(c.interruptionLevel),
            "userInfo": c.userInfo,
        ]
    }

    private static func pluginMethods(host: PluginHost) -> [String: Any] {
        [
            "setContent": { (args: [Any?]) -> Any? in
                host.setContent(args.first as? [AnyHashable: Any])
                return nil
            } as AsyncNativeMethod,

            "attach": { (args: [Any?]) async -> Any? in
                let d = args.first as? [AnyHashable: Any]
                let type = (d?["type"] as? String) ?? "image"
                let ref = (d?[.url] as? String) ?? (d?[.location] as? String)
                return await host.attach(type: type, ref: ref)
            } as AsyncNativeMethod,

            "setAvatar": { (args: [Any?]) async -> Any? in
                await host.avatar(args.first as? String)
            } as AsyncNativeMethod,

            "setSound": { (args: [Any?]) async -> Any? in
                await host.sound(args.first as Any?)
            } as AsyncNativeMethod,
            
            "archive": { (args: [Any?]) -> Any? in
                host.archive(args.first as? [AnyHashable: Any])
            } as AsyncNativeMethod,

            "decrypt": { (args: [Any?]) throws -> Any? in
                let text = args.first as? String
                let number = args.count > 1 ? (args[1] as? NSNumber)?.intValue : nil
                return try host.decrypt(text, number: number)
            } as AsyncNativeMethod,
        ]
    }

    private static func levelName(_ l: UNNotificationInterruptionLevel) -> String {
        switch l {
        case .passive: return "passive"
        case .timeSensitive: return "timesensitive"
        case .critical: return "critical"
        default: return "active"
        }
    }
}

final class PluginHost: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock()
    private var content: UNMutableNotificationContent

    init(content: UNMutableNotificationContent) { self.content = content }

    func snapshot() -> UNMutableNotificationContent {
        lock.lock(); defer { lock.unlock() }
        return content
    }

    private func currentContent() -> UNMutableNotificationContent {
        lock.lock(); defer { lock.unlock() }
        return content
    }

    private func setAttachment(_ attachment: UNNotificationAttachment) {
        lock.lock(); defer { lock.unlock() }
        content.attachments = [attachment]
    }

    private func replaceContent(_ c: UNMutableNotificationContent) {
        lock.lock(); defer { lock.unlock() }
        content = c
    }

    private func applySoundName(_ name: String) {
        lock.lock(); defer { lock.unlock() }
        content.setSound(soundName: name)
    }

    func setContent(_ patch: [AnyHashable: Any]?) {
        guard let p = patch else { return }
        lock.lock(); defer { lock.unlock() }
        if let v = p[.title] as? String { content.title = v }
        if let v = p[.subtitle] as? String { content.subtitle = v }
        if let v = p[.body] as? String { content.body = v }
        if let v = p[.group] as? String { content.threadIdentifier = v }
        if let v = p[.category] as? String { content.categoryIdentifier = v }
        if let v = p["id"] as? String { content.targetContentIdentifier = v }
        if let v = p[.level] as? String { content.interruptionLevel = Self.level(v) }
        if let n = (p[.badge] as? NSNumber)?.int64Value {
            content.badge = NSNumber(value: n)
            Defaults[.sharedUnreadCount] = n <= 0 ? 0 : Int(n)
        }
    }

    func attach(type: String, ref: String?) async -> Bool {
        guard let ref, !ref.isEmpty else { return false }
        let localPath: String?
        if type == "map" {
            localPath = await ImageManager.generateMapSnapshot(
                from: ref, mapSize: CGSize(width: 500, height: 500)
            )
        } else {
            let ex = Defaults[.imageSaveDays]
            localPath = await ImageManager.downloadImage(
                ref, expiration: ex.isPermanent ? .never : .seconds(ex.seconds)
            )
        }
        guard let localPath,
              let attachment = try? AttachmentProcessor().genAttachment(localPath: localPath)
        else { return false }
        setAttachment(attachment)
        return true
    }

    func avatar(_ ref: String?) async -> Bool {
        guard let ref, !ref.isEmpty else { return false }
        let updated = await AttachmentProcessor.applyAvatar(
            to: currentContent(), pngURL: ref
        )
        replaceContent(updated)
        return true
    }

    func sound(_ spec: Any?) async -> Bool {
        let soundName: String?
        if let s = spec as? String {
            soundName = s.hasSuffix(".\(Params.caf.name)") ? s : "\(s).\(Params.caf.name)"
        } else if let d = spec as? [AnyHashable: Any] {
            if let url = d[.url] as? String, let u = URL(remote: url) {
                soundName = await CallProcessor().downloadSound(u)?.lastPathComponent
            } else if let tts = d["tts"] as? String {
                // 复用 TTS 脚本链路：把待朗读文本作为 call 参数交给语音脚本合成。
                soundName = await ScriptProcessor
                    .ttsHandler([Params.call.name: tts] as [AnyHashable: Any])
            } else {
                soundName = nil
            }
        } else {
            soundName = nil
        }
        guard let soundName else { return false }
        applySoundName(soundName)
        return true
    }

    func archive(_ msg: [AnyHashable: Any]?) -> Bool {
        guard var msg, !msg.isEmpty else { return false }
        let current = currentContent()
        let id = current.targetContentIdentifier
        let group = current.threadIdentifier

        if (msg["id"] as? String)?.isEmpty != false {
            msg["id"] = id ?? UUID().uuidString
        }
        if msg[.createDate] == nil {
            msg[.createDate] = Int64(Date().timeIntervalSince1970)
        }
        if msg[.read] == nil { msg[.read] = false }
        if (msg[.group] as? String)?.isEmpty != false, !group.isEmpty {
            msg[.group] = group
        }
        let isNew = PendingMessageStore().write(msg)
        if isNew { Defaults[.sharedUnreadCount] += 1 }
        return isNew
    }

    func decrypt(_ text: String?, number: Int?) throws -> [AnyHashable: Any] {
        guard let text, !text.isEmpty else { return [:] }
        return try DecryptionProcessor().decrypt(ciphertext: text, number: number ?? 0)
    }

    private static func level(_ raw: String) -> UNNotificationInterruptionLevel {
        switch raw.lowercased() {
        case "passive": return .passive
        case "timesensitive", "time-sensitive": return .timeSensitive
        case "critical": return .critical
        default: return .active
        }
    }
}
