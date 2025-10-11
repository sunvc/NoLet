//
//  File name:     AudioManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/10.


import Foundation
import AVFoundation
import SwiftUI
import ActivityKit


class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate{
    
    static let shared = AudioManager()
    private var manager = FileManager.default
    
    private var mainQueue = Queue.mainQueue()
    
    private override init() {
        super.init()
        self.setFileList()
       
    }
    
    
    @Published var defaultSounds:[URL] =  []
    @Published var customSounds:[URL] =  []
    
    @Published var soundID: SystemSoundID = 0
    @Published var playingAudio:URL? = nil
    
    @Published var speakPlayer:AVAudioPlayer? = nil
    @Published var loading:Bool = false
    
    @Published var ShareURL: URL?  = nil
    
   
    
    func allSounds()-> [String] {
        let (customSounds , defaultSounds) = AudioManager.shared.getFileList()
        return (customSounds + defaultSounds).map {
            $0.deletingPathExtension().lastPathComponent
        }
    }
    
    // MARK: - Get audio folder data
    
    func getFileList()-> ([URL],[URL]) {
        // 加载 Bundle 中的默认 caf 音频资源
        let defaultSounds: [URL] = {
            // 从 App Bundle 获取所有 caf 文件
            var temurl = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
            
            // 按文件名自然排序（考虑数字顺序、人类习惯排序）
            temurl.sort { u1, u2 -> Bool in
                u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == .orderedAscending
            }
            
            return temurl
        }()
        
        // 加载 App Group 共享目录中的自定义 caf 音频资源
        let customSounds: [URL] = {
            // 获取共享目录路径
            guard let soundsDirectoryUrl = BaseConfig.getDir(.sounds) else { return [] }
            
            // 获取指定后缀（caf），排除长音前缀的文件
            var urlemp = self.getFilesInDirectory(directory: soundsDirectoryUrl.path(), suffix: "caf")
            
            // 同样进行自然排序
            urlemp.sort { u1, u2 -> Bool in
                u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == .orderedAscending
            }
            
            return urlemp
        }()
        
        
        return (customSounds, defaultSounds)
        
    }
    
    /// 加载系统默认音效和用户自定义音效文件列表
    private func setFileList() {
        Task.detached(priority: .userInitiated) {
            let (customSounds, defaultSounds) = self.getFileList()
            // 回到主线程，更新界面相关状态（如 SwiftUI 或 UIKit 列表）
            await MainActor.run {
                self.customSounds = customSounds
                self.defaultSounds = defaultSounds
            }
        }
        
    }
    
    /// 返回指定文件夹中，指定后缀且不含长音前缀的文件列表
    func getFilesInDirectory(directory: String, suffix: String) -> [URL] {
        do {
            // 获取目录下所有文件名（字符串）
            let files = try manager.contentsOfDirectory(atPath: directory)
        
            
            // 过滤符合条件的文件，并转换为完整的 URL
            return files.compactMap { file -> URL? in
                // 仅保留指定后缀，且排除带有“长音前缀”的文件
                if file.lowercased().hasSuffix(suffix.lowercased()), !file.hasPrefix(BaseConfig.longSoundPrefix) {
                    // 构造完整文件路径 URL
                    return URL(fileURLWithPath: directory).appendingPathComponent(file)
                }
                return nil
            }
        } catch {
            // 出现异常时返回空数组
            return []
        }
    }
    
    /// 通用文件保存方法
    func saveSound(
        url sourceUrl: URL,
        name lastPath: String? = nil,
        maxNameLength:Int = 13
     ) {
        // 获取 App Group 的共享铃声目录路径
        guard let groupDirectoryUrl = BaseConfig.getDir(.sounds) else { return }


        var fileName: String{
            String(
                (lastPath ?? sourceUrl.lastPathComponent).suffix(maxNameLength)
            )
        }


        // 构造目标路径：使用传入的自定义文件名（lastPath），否则使用源文件名
        let groupDestinationUrl = groupDirectoryUrl.appendingPathComponent(fileName)

        // 如果目标文件已存在，先删除旧文件
        if manager.fileExists(atPath: groupDestinationUrl.path) {
            try? manager.removeItem(at: groupDestinationUrl)
        }
        
        do {
            // 拷贝文件到共享目录（实现“保存”操作）
            try manager.copyItem(at: sourceUrl, to: groupDestinationUrl)
            
            // 弹出成功提示（使用 Toast）
            Toast.success(title: "保存成功")
        } catch {
            // 如果保存失败，弹出错误提示
            Toast.shared.present(title: error.localizedDescription, symbol: .error)
        }
        
        // 刷新铃声文件列表（用于更新 UI 或数据）
        setFileList()
    }
    
    func deleteSound(url: URL) {
        // 获取 App Group 中的共享铃声目录
        guard let soundsDirectoryUrl = BaseConfig.getDir(.sounds) else { return }
        
        // 删除本地 sounds 目录下的铃声文件
        try? manager.removeItem(at: url)
        
        // 构造共享目录下对应的长铃声文件路径（带有前缀）
        let groupSoundUrl = soundsDirectoryUrl.appendingPathComponent("\(BaseConfig.longSoundPrefix).\(url.lastPathComponent)")
        
        // 删除共享目录中的铃声文件（如果存在）
        try? manager.removeItem(at: groupSoundUrl)
        
        // 刷新文件列表（通常是为了更新 UI 或内部数据状态）
        setFileList()
    }
    
    func playAudio(url: URL? = nil, complete:(()->Void)? = nil) {
        // 先释放之前的 SystemSoundID（如果有），避免内存泄漏或重复播放
        AudioServicesDisposeSystemSoundID(self.soundID)
        
        // 如果传入的 URL 为空，或者与当前正在播放的是同一个音频，则认为是“停止播放”的操作
        guard let audio = url, playingAudio != url else {
            mainQueue.async {
                self.playingAudio = nil
                self.soundID = 0
            }
            return
        }
    
        
        // 创建 SystemSoundID，用于播放系统音效（仅支持较小的音频文件，通常小于30秒）
        mainQueue.async {
            // 设置当前正在播放的音频
            self.playingAudio = audio
            AudioServicesCreateSystemSoundID(audio as CFURL, &self.soundID)
            // 播放音频，播放完成后执行回调
            AudioServicesPlaySystemSoundWithCompletion(self.soundID) {
                // 如果回调时仍是当前音频（防止播放期间被替换）
                if self.playingAudio == url {
                    // 释放资源
                    AudioServicesDisposeSystemSoundID(self.soundID)
                    self.mainQueue.async {
                        // 重置播放状态
                        self.playingAudio = nil
                        self.soundID = 0
                        complete?()
                    }
                }
            }
        }
        
        
        
    }
    
    
    static func playNumber(number: String){
        guard let number = Int(number) else { return }
        AudioServicesPlaySystemSound(SystemSoundID(number))
    }
    
    
    
    
    func convertAudioToCAF(inputURL: URL) async -> URL?  {
        
        do{
            
            let fileName = inputURL.deletingPathExtension().lastPathComponent
            
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).caf")
            // 如果输出文件已存在，则先删除，防止导出失败
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            // 创建 AVAsset 用于处理输入音频资源
            let asset = AVAsset(url: inputURL)
            
            // 创建导出会话，使用 "Passthrough" 预设保持原始音频格式
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return nil }
            // 获取音频时长（异步加载）
            let assetDurationSeconds = try await asset.load(.duration)
            
            // 设置导出时间范围：如果音频大于 30 秒，最多只导出 29.9 秒
            // AVFoundation 的时间精度有限，设置 29.9 更保险
            let maxDurationCMTime = CMTime(seconds: 29.9, preferredTimescale: 600)
            if assetDurationSeconds > maxDurationCMTime {
                exportSession.timeRange = CMTimeRange(start: .zero, duration: maxDurationCMTime)
            }
            
            // 设置导出文件类型和输出路径
            exportSession.outputFileType = .caf
            exportSession.outputURL = outputURL
            
            // 开始异步导出
            await exportSession.export()
            
            // 根据导出状态返回结果
            return exportSession.status == .completed ? outputURL : nil
            
        }catch{
            return nil
        }
        
        
    }
    
    func speak(_ text: String, noCache:Bool = false) async -> AVAudioPlayer? {

        do{
            self.speakPlayer = nil
            let start = DispatchTime.now()
            await MainActor.run {
                withAnimation(.default) {
                    self.loading = true
                    AppManager.shared.speaking = true
                }
                
            }
            
            let client = try VoiceManager()
            let audio = try await client.createVoice(text: text,noCache: noCache)
            await MainActor.run{
                self.ShareURL = audio
            }
            
            
            let player = try AVAudioPlayer(contentsOf: audio)
            await MainActor.run {
                self.speakPlayer = player
                self.speakPlayer?.delegate = self
                self.loading = false
            }
            
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            NLog.log("运行时间：",Double(nanoTime) / 1_000_000_000)
            return self.speakPlayer
        }catch{
            await MainActor.run {
                self.speakPlayer = nil
                self.loading = false
            }
            NLog.error(error.localizedDescription)
            return nil
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task{@MainActor in
            withAnimation(.default) {
                AppManager.shared.speaking = false
                self.speakPlayer = nil
            }
        }
    }
    
}



extension AudioManager{
   static func setCategory(_ active: Bool = true,
                     _ category: AVAudioSession.Category = .playback,
                     mode: AVAudioSession.Mode = .default) {
        let session = AVAudioSession.sharedInstance()

        do {
            if active {
                if category == .playAndRecord {
                    try session.setCategory(category,
                                            mode: mode,
                                            options: [
                                                .defaultToSpeaker,
                                                .allowBluetoothHFP,
                                                .allowBluetoothA2DP,
                                            ])
                } else {
                    try session.setCategory(category,
                                            mode: mode,
                                            options: [
                                                .allowBluetoothHFP,
                                                .allowBluetoothA2DP,
                                            ])
                }
            }

            try session.setActive(active, options: .notifyOthersOnDeactivation)
            try session.overrideOutputAudioPort(.speaker)

            if let inputs = AVAudioSession.sharedInstance().availableInputs {
                if let bluetooth = inputs.first(where: { $0.portType == .bluetoothHFP }) {
                    try AVAudioSession.sharedInstance().setPreferredInput(bluetooth)
                }
            }
        } catch {
            NLog.error("设置setActive失败：", error.localizedDescription)
        }
    }

    // MARK: - OTHER
    static func tips(_ fileName: TipsSound, fileExtension: String = "aac", complete: (() -> Void)? = nil) {
        guard Defaults[.feedback] else { return }
        guard let url = Bundle.main.url(forResource: fileName.rawValue, withExtension: fileExtension) else { return }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
            // 播放音频，播放完成后执行回调
        AudioServicesPlaySystemSoundWithCompletion(soundID) {
            AudioServicesDisposeSystemSoundID(soundID)
            complete?()
        }
    }

}
