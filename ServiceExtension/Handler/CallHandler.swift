//
//  CallHandler.swift
//  NotificationService
//  Changed by uuneo 2024/8/8.
//

import Foundation
import AVFAudio
import AudioToolbox
import UserNotifications
import CallKit
import LiveCommunicationKit

class CallHandler: NotificationContentHandler {
    /// 铃声文件夹，扩展访问不到主APP中的铃声，需要先共享铃声文件
    let soundsDirectoryUrl = BaseConfig.getDir(.sounds)
    
    
    func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        // 如果不是来电通知，直接返回
        guard let call:Bool = bestAttemptContent.userInfo.raw(.call), call else {
            return bestAttemptContent
        }
        

        // 提取铃声名与类型
        let defaultSoundName = "call"
        let defaultSoundType = "caf"
        
        let soundComponents = bestAttemptContent.soundName?.split(separator: ".").map(String.init)
        let (soundName, soundType): (String, String) = {
            if let components = soundComponents, components.count == 2, components[1] == defaultSoundType {
                return (components[0], components[1])
            } else {
                return (defaultSoundName, defaultSoundType)
            }
        }()
        
        // 尝试获取延长铃声 URL
        guard let longSoundUrl = getLongSound(soundName: soundName, soundType: soundType) else {
            return bestAttemptContent
        }
        // Fallback on earlier versions
        // 设置铃声
        // Fallback on earlier versions
        let soundFile = UNNotificationSoundName(rawValue: longSoundUrl.lastPathComponent)
        if bestAttemptContent.isCritical {
            LevelHandler.setCriticalSound(content: bestAttemptContent, soundName: soundFile.rawValue)
        } else {
            bestAttemptContent.sound = UNNotificationSound(named: soundFile)
        }
        return bestAttemptContent
    }
}


extension CallHandler{

    func getLongSound(soundName: String, soundType: String) -> URL? {
        guard let soundsDirectoryUrl else { return nil }
        
        // 已经存在处理过的长铃声，则直接返回
        let longSoundName = "\(BaseConfig.longSoundPrefix).\(soundName).\(soundType)"
        let longSoundPath = soundsDirectoryUrl.appendingPathComponent(longSoundName)
        if FileManager.default.fileExists(atPath: longSoundPath.path) { return longSoundPath }
        
        // 原始铃声路径
        var path: String = soundsDirectoryUrl.appendingPathComponent("\(soundName).\(soundType)").path
        if !FileManager.default.fileExists(atPath: path) {
            path = Bundle.main.path(forResource: soundName, ofType: soundType) ?? ""
        }
        guard !path.isEmpty else {  return nil }
        
        // 将原始铃声处理成30s的长铃声，并缓存起来
        return mergeCAFFilesToDuration(inputFile: URL(fileURLWithPath: path))
    }

    /// - Description:将输入的音频文件重复为指定时长的音频文件
    /// - Parameters:
    ///   - inputFile: 原始铃声文件路径
    ///   - targetDuration: 重复的时长
    /// - Returns: 长铃声文件路径
    func mergeCAFFilesToDuration(inputFile: URL, targetDuration: TimeInterval = 30) -> URL? {
        guard let soundsDirectoryUrl else {
            return nil
        }
        let longSoundName = "\(BaseConfig.longSoundPrefix).\(inputFile.lastPathComponent)"
        let longSoundPath = soundsDirectoryUrl.appendingPathComponent(longSoundName)
        
        do {
            // 打开输入文件并获取音频格式
            let audioFile = try AVAudioFile(forReading: inputFile)
            let audioFormat = audioFile.processingFormat
            let sampleRate = audioFormat.sampleRate

            // 计算目标帧数
            let targetFrames = AVAudioFramePosition(targetDuration * sampleRate)
            var currentFrames: AVAudioFramePosition = 0
            // 创建输出音频文件
            let outputAudioFile = try AVAudioFile(forWriting: longSoundPath, settings: audioFormat.settings)
            
            // 循环读取文件数据，拼接到目标时长
            while currentFrames < targetFrames {
                // 每次读取整个文件的音频数据
                guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                    // 出错了就终止，避免死循环
                    return nil
                }
                
                try audioFile.read(into: buffer)

                // 计算剩余所需帧数
                let remainingFrames = targetFrames - currentFrames
                if AVAudioFramePosition(buffer.frameLength) > remainingFrames {
                    // 如果当前缓冲区帧数超出所需，截取剩余部分
                    let truncatedBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(remainingFrames))!
                    let channelCount = Int(buffer.format.channelCount)
                    for channel in 0..<channelCount {
                        let sourcePointer = buffer.floatChannelData![channel]
                        let destinationPointer = truncatedBuffer.floatChannelData![channel]
                        memcpy(destinationPointer, sourcePointer, Int(remainingFrames) * MemoryLayout<Float>.size)
                    }
                    truncatedBuffer.frameLength = AVAudioFrameCount(remainingFrames)
                    try outputAudioFile.write(from: truncatedBuffer)
                    break
                } else {
                    // 否则写入整个缓冲区
                    try outputAudioFile.write(from: buffer)
                    currentFrames += AVAudioFramePosition(buffer.frameLength)
                }
                
                // 重置输入文件读取位置
                audioFile.framePosition = 0
            }
            return longSoundPath
        } catch {
            NLog.error("Error processing CAF file: \(error)")
            return nil
        }
    }
}

