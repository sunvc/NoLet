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
    let soundsDirectoryURL = NCONFIG.getDir(.sounds)

    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        
        bestAttemptContent.interruptionLevel = bestAttemptContent.level
        
        guard let call: Bool = bestAttemptContent.userInfo.raw(.call), call else {
            bestAttemptContent.setSound()
            return bestAttemptContent
        }

        let soundName = bestAttemptContent.soundName?.split(separator: ".", maxSplits: 1).first
            .map(String.init) ?? "call"

        guard let longSoundURL = await getLongSound(soundName: soundName)
        else {
            bestAttemptContent.setSound(soundName: "call.caf")
            return bestAttemptContent
        }
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
        let longSoundName = "\(NCONFIG.longSoundPrefix).\(soundName).\(soundType)"
        let longSoundPath = soundsDirectoryURL.appendingPathComponent(longSoundName)
        if FileManager.default.fileExists(atPath: longSoundPath.path) { return longSoundPath }

        var path: String = soundsDirectoryURL.appendingPathComponent("\(soundName).\(soundType)")
            .path
        if !FileManager.default.fileExists(atPath: path) {
            path = Bundle.main.path(forResource: soundName, ofType: soundType) ?? ""
        }
        guard !path.isEmpty else { return nil }

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
            logger.error("Error processing CAF file: \(error)")
            return inputFile
        }
    }
}


extension UNMutableNotificationContent {
    var isCritical: Bool { levelNumber > 2 }

    var soundName: String? {
        if let sound: String = userInfo.raw(.sound), sound.count > 0 {
            let soundName = sound.hasSuffix(".caf") ? sound : "\(sound).caf"
            return soundName
        }
        return nil
    }

    var levelNumber: Int {
        let level: String? = userInfo.raw(.level)
        guard let level = level, let number = Int(level) else {
            return Int(self.level.rawValue)
        }
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
