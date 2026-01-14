//
//  LevelProcessor.swift
//  NotificationService
//  Created by Neo on 2024/12/1.
//

import AVFoundation
import CallKit
import Foundation
import LiveCommunicationKit
import UserNotifications

class LevelProcessor: NotificationContentProcessor {
    /// 铃声文件夹，扩展访问不到主APP中的铃声，需要先共享铃声文件
    let soundsDirectoryURL = NCONFIG.getDir(.sounds)

    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        
        // 设置通知级别
        bestAttemptContent.interruptionLevel = bestAttemptContent.level
        
        // 如果不是来电通知，直接返回
        guard let call: Bool = bestAttemptContent.userInfo.raw(.call), call else {
            bestAttemptContent.setSound()
            return bestAttemptContent
        }

        let soundName = bestAttemptContent.soundName?.split(separator: ".", maxSplits: 1).first
            .map(String.init) ?? "call"

        // 尝试获取延长铃声 URL
        guard let longSoundURL = await getLongSound(soundName: soundName)
        else {
            bestAttemptContent.setSound(soundName: "call.caf")
            return bestAttemptContent
        }
        // Fallback on earlier versions
        // 设置铃声
        // Fallback on earlier versions
        let soundFile = UNNotificationSoundName(rawValue: longSoundURL.lastPathComponent)
        if bestAttemptContent.isCritical {
            bestAttemptContent.setSound(soundName: soundFile.rawValue)
        } else {
            bestAttemptContent.sound = UNNotificationSound(named: soundFile)
        }
        return bestAttemptContent
    }
    
    
}

extension LevelProcessor{
    func getLongSound(soundName: String) async -> URL? {
        guard let soundsDirectoryURL else { return nil }

        let soundType: String = "caf"
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
            logger.error("❌ Error processing CAF file: \(error)")
            return inputFile
        }
    }
}


extension UNMutableNotificationContent {
    var isCritical: Bool { levelNumber > 2 }

    /// 声音名称
    var soundName: String? {
        if let sound: String = userInfo.raw(.sound, nesting: false), sound.count > 0 {
            return sound.hasSuffix(".caf") ? sound : "\(sound).caf"
        }
        return nil
    }

    var levelNumber: Int {
        let level: String? = userInfo.raw(.level)
        // 获取 level 字符串
        guard let level = level, let number = Int(level) else {
            // 返回标准数字
            return Int(self.level.rawValue)
        }
        //  返回非标准数字
        return number
    }

    var volume: Float {
        if let volume: String = userInfo.raw(.volume), let volume = Float(volume) {
            return max(0.0, min(10.0, volume / 10.0))
        }
        return max(0.0, min(10.0, Float(levelNumber) / 10.0))
    }

    var level: UNNotificationInterruptionLevel {
        let level: String? = userInfo.raw(.level)

        if let rawValue = level {
            if let number = Int(rawValue) {
                switch number {
                case ...0: return .passive
                case 1: return .active
                case 2: return .timeSensitive
                default: return .critical
                }

            } else {
                switch rawValue {
                case "passive": return .passive
                case "active": return .active
                case "timesensitive": return .timeSensitive
                case "critical": return .critical
                default: return .active
                }
            }
        } else {
            return .active
        }
    }

    func setSound(soundName: String? = nil) {
        // 设置重要警告 sound
        let sound = soundName ?? self.soundName ?? "\(Defaults[.sound]).caf"
        if isCritical {
            self.sound = UNNotificationSound.criticalSoundNamed(
                UNNotificationSoundName(rawValue: sound),
                withAudioVolume: volume
            )
        } else {
            self.sound = UNNotificationSound(
                named: UNNotificationSoundName(rawValue: sound)
            )
        }
    }
}
