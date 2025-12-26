//
//  CallHandler.swift
//  NotificationService
//  Created by Neo on 2024/12/1.
//

import AVFoundation
import CallKit
import Foundation
import LiveCommunicationKit
import UserNotifications

final class CallHandler: NotificationContentProcessor, Sendable {
    /// 铃声文件夹，扩展访问不到主APP中的铃声，需要先共享铃声文件
    let soundsDirectoryURL = NCONFIG.getDir(.sounds)

    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        // 如果不是来电通知，直接返回
        guard let call: Bool = bestAttemptContent.userInfo.raw(.call), call else {
            return bestAttemptContent
        }

        // 提取铃声名与类型
        let defaultSoundName = "call"
        let defaultSoundType = "caf"

        let soundComponents = bestAttemptContent.soundName?.split(separator: ".").map(String.init)
        let (soundName, soundType): (String, String) = {
            if let components = soundComponents, components.count == 2,
               components[1] == defaultSoundType
            {
                return (components[0], components[1])
            } else {
                return (defaultSoundName, defaultSoundType)
            }
        }()

        // 尝试获取延长铃声 URL
        guard let longSoundURL = await getLongSound(soundName: soundName, soundType: soundType)
        else {
            return bestAttemptContent
        }
        // Fallback on earlier versions
        // 设置铃声
        // Fallback on earlier versions
        let soundFile = UNNotificationSoundName(rawValue: longSoundURL.lastPathComponent)
        if bestAttemptContent.isCritical {
            LevelHandler.setCriticalSound(
                content: bestAttemptContent,
                soundName: soundFile.rawValue
            )
        } else {
            bestAttemptContent.sound = UNNotificationSound(named: soundFile)
        }
        return bestAttemptContent
    }
}

extension CallHandler {
    func getLongSound(soundName: String, soundType: String) async -> URL? {
        guard let soundsDirectoryURL else { return nil }

        // 已经存在处理过的长铃声，则直接返回
        let longSoundName = "\(NCONFIG.longSoundPrefix).\(soundName).\(soundType)"
        let longSoundPath = soundsDirectoryURL.appendingPathComponent(longSoundName)
        if FileManager.default.fileExists(atPath: longSoundPath.path) { return longSoundPath }

        // 原始铃声路径
        var path: String = soundsDirectoryURL.appendingPathComponent("\(soundName).\(soundType)")
            .path
        if !FileManager.default.fileExists(atPath: path) {
            path = Bundle.main.path(forResource: soundName, ofType: soundType) ?? ""
        }
        guard !path.isEmpty else { return nil }

        // 将原始铃声处理成30s的长铃声，并缓存起来
        return await mergeCAFFilesToDuration(inputFile: URL(fileURLWithPath: path))
    }

    /// - Description:将输入的音频文件重复为指定时长的音频文件
    /// - Parameters:
    ///   - inputFile: 原始铃声文件路径
    ///   - targetDuration: 重复的时长
    /// - Returns: 长铃声文件路径
    func mergeCAFFilesToDuration(inputFile: URL, targetDuration: TimeInterval = 30) async -> URL {
        guard let soundsDirectoryURL else {
            return inputFile
        }

        let longSoundPath = soundsDirectoryURL.appendingPathComponent(
            "\(NCONFIG.longSoundPrefix).\(inputFile.lastPathComponent)"
        )

        do {
            return try await AudioConversion().toCAFLong(
                inputURL: inputFile,
                outputURL: longSoundPath,
                bitrate: 128_000,
                sampleRate: 44100,
                channels: 2,
                targetSeconds: targetDuration
            )
        } catch {
            NLog.error("Error processing CAF file: \(error)")
            return inputFile
        }
    }
}
