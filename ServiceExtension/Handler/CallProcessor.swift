//
//  CallProcessor.swift
//  NotificationService
//  Created by Neo on 2024/12/1.
//

import AVFoundation
import CallKit
import Foundation
import LiveCommunicationKit
import UserNotifications

final class CallProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        var soundName: String?

        if let call = userInfo.raw(.call, as: Bool.self) {
            if call {
                let soundNameTem = bestAttemptContent.soundName ?? "call.caf"

                if let url = await mergeCAFFilesToDuration(soundName: soundNameTem) {
                    soundName = url.lastPathComponent
                } else {
                    soundName = "call.caf"
                }
            }
        } else if let call = userInfo.raw(.call, as: String.self) {
            if let url = URL(remote: call) {
                soundName = await self.downloadSound(url)?.lastPathComponent
            } else {
                soundName = await ScriptProcessor.ttsHandler(userInfo)
            }
        }

        bestAttemptContent.setSound(soundName: soundName)

        return bestAttemptContent
    }

    func downloadSound(_ url: URL) async -> URL? {
        guard let soundPath = NCONFIG.SoundName.speak
            .path("\(url.absoluteString.sha256()).caf") else { return nil }

        do {
            let localPath = try await NetworkManager().download(from: url)
            let path = try await AudioConversion().toCAFLong(
                inputURL: localPath,
                outputURL: soundPath,
                targetSeconds: 30
            )
            return path
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }

    /// - Description:将输入的音频文件重复为指定时长的音频文件
    /// - Parameters:
    ///   - inputFile: 原始铃声文件路径
    ///   - targetDuration: 重复的时长
    /// - Returns: 长铃声文件路径
    func mergeCAFFilesToDuration(
        soundName: String,
        targetDuration: TimeInterval = 30
    ) async -> URL? {
        guard let inputFile = NCONFIG.SoundName.check(soundName),
              let longSoundPath = NCONFIG.SoundName.long.path(inputFile.lastPathComponent)
        else {
            logger.error("\(soundName)")
            return nil
        }

        if let url = NCONFIG.SoundName.check(longSoundPath.lastPathComponent) {
            return url
        }

        do {
            return try await AudioConversion().toCAFLong(
                inputURL: inputFile,
                outputURL: longSoundPath,
                targetSeconds: targetDuration
            )
        } catch {
            logger.error("Error processing CAF file: \(error)")
            return nil
        }
    }
}

extension UNMutableNotificationContent {
    var soundName: String? {
        if let sound = userInfo.raw(.sound, as: String.self), sound.count > 0 {
            let soundName = sound.hasSuffix(".caf") ? sound : "\(sound).caf"
            return soundName
        }
        return nil
    }

    var levelNumber: Int {
        guard let number = userInfo.raw(.level, as: Int64.self) else {
            return Int(self.level.rawValue)
        }
        return Int(number)
    }

    var volume: Float {
        if let volume = userInfo.raw(.volume, as: Int64.self) {
            return max(0.0, min(10.0, Float(volume) / 10.0))
        }
        return 5.0
    }

    var level: UNNotificationInterruptionLevel {
        if let rawValue = userInfo.raw(.level, as: Int64.self) {
            switch rawValue {
            case ...0: return .passive
            case 1: return .active
            case 2: return .timeSensitive
            default: return .critical
            }
        } else if let rawValue = userInfo.raw(.level, as: String.self) {
            switch rawValue {
            case "passive": return .passive
            case "active": return .active
            case "timesensitive": return .timeSensitive
            case "critical": return .critical
            default: return .active
            }
        } else {
            return .active
        }
    }

    func setSound(soundName: String? = nil) {
        let sound = soundName ?? self.soundName ?? "\(Defaults[.sound]).caf"
        if level == .critical {
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
