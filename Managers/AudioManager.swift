//
//  File name:     AudioManager.swift
//  NoLet
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://wzs.app
//  E-mail:        to@wzs.app
//
//
//  Description:
//
//  History:
//    Created by Neo on 2024/12/10.


import Foundation
import AVFoundation
import SwiftUI
import ActivityKit
import Defaults
import Zip



// MARK: - 铃声界面播放铃声 Actor
final class AudioManager: NSObject,  ObservableObject{
    
    static let shared = AudioManager()
    
    @Published var defaultSounds:[URL] =  []
    @Published var customSounds:[URL] =  []
   
    @Published var loading:Bool = false
    @Published var ShareURL: URL?  = nil
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var currentURL: URL? = nil
    
    private var manager = FileManager.default
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playerItemStatusObserver: NSKeyValueObservation?
    
    private var endObserver: NSObjectProtocol?
    
    private override init() {
        super.init()
        self.updateFileList()
    }
    
    /// 播放或暂停音频
    func togglePlay(url: URL) {
        if currentURL == url {
            //  如果是同一个文件，则切换播放状态
            if isPlaying {
                pause()
            } else {
                play()
            }
        } else {
            //  如果是不同文件，则重新播放
            playNewURL(url)
        }
    }
    
    /// 开始播放新音频
    private func playNewURL(_ url: URL) {
        cleanup()
        currentURL = url
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // 监听播放状态
        playerItemStatusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                Task { @MainActor in
                    self.duration = item.duration.seconds
                    self.play()
                }
            }
        }
        
        // 实时监听播放进度
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let dur = self.player?.currentItem?.duration.seconds, dur > 0 {
                self.duration = dur
            }
        }
        
        //  监听播放结束
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // 停止并清理
            self.cleanup()
        }
    }
    
    /// 播放
    private func play() {
        player?.play()
        isPlaying = true
    }
    
    /// 暂停
    private func pause() {
        player?.pause()
        isPlaying = false
    }
    
    /// 跳转到指定时间
    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    func stop(){
        self.cleanup()
    }
    
    /// 清理资源（切歌时）
    private func cleanup() {
        if let token = timeObserver {
            player?.removeTimeObserver(token)
            timeObserver = nil
        }
        playerItemStatusObserver = nil
        player = nil
        currentTime = 0
        duration = 0
        currentURL = nil
        isPlaying = false
    }
    
    deinit {
        cleanup()
    }
    
    // 定义一个异步函数来加载audio的持续时间
    func loadVideoDuration(fromURL audioURL: URL) async throws -> Double {
        return try AVAudioPlayer(contentsOf: audioURL).duration
    }
    
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: duration)) ?? ""
    }
}

extension AudioManager{
    
    
    
    func allSounds()-> [String] {
        let (customSounds , defaultSounds) = self.getFileList()
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
            guard let soundsDirectoryUrl = NCONFIG.getDir(.sounds) else { return [] }
            
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
    func updateFileList() {
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
                if file.lowercased().hasSuffix(suffix.lowercased()), !file.hasPrefix(NCONFIG.longSoundPrefix) {
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
    func saveSound(  url sourceUrl: URL, name lastPath: String? = nil,  maxNameLength:Int = 13 ) {
        // 获取 App Group 的共享铃声目录路径
        guard let groupDirectoryUrl = NCONFIG.getDir(.sounds) else { return }


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
         self.updateFileList()
    }
    
    func deleteSound(url: URL) {
        // 获取 App Group 中的共享铃声目录
        guard let soundsDirectoryUrl = NCONFIG.getDir(.sounds) else { return }
        
        // 删除本地 sounds 目录下的铃声文件
        try? manager.removeItem(at: url)
        
        // 构造共享目录下对应的长铃声文件路径（带有前缀）
        let groupSoundUrl = soundsDirectoryUrl.appendingPathComponent("\(NCONFIG.longSoundPrefix).\(url.lastPathComponent)")
        
        // 删除共享目录中的铃声文件（如果存在）
        try? manager.removeItem(at: groupSoundUrl)
        
        // 刷新文件列表（通常是为了更新 UI 或内部数据状态）
        self.updateFileList()
    }
    
    func convertToCaf(inputURL: URL) async -> URL?  {
        
        do{
            
            let fileName = inputURL.deletingPathExtension().lastPathComponent
            
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).caf")
     
            
            return try await AudioConversion.toCAFShort(inputURL: inputURL, outputURL: outputURL,  maxSeconds: 29.9)
            
        }catch{
            return nil
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
    static func tips(_ sound: TipsSound, fileExtension: String = "aac", complete: (() -> Void)? = nil) {
        self.tips(sound.rawValue, fileExtension: fileExtension, complete: complete)
    }
  
    static func tips(_ sound: String, fileExtension: String = "aac", complete: (() -> Void)? = nil){
        guard Defaults[.feedbackSound] else { return }
        
        var soundID: SystemSoundID = 0
        
        if let number = Int(sound){
            soundID = SystemSoundID(number)
        }else if let url = Bundle.main.url(forResource: sound, withExtension: fileExtension) {
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        }
        if soundID != 0{
            AudioServicesPlaySystemSoundWithCompletion(soundID) {
                AudioServicesDisposeSystemSoundID(soundID)
                complete?()
            }
        }else{
            complete?()
        }
    }
    
    enum TipsSound: String{
        case qrcode
        case share
    }


}


extension AudioManager{
    func downloadSounds() async throws {
        
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("sounds.zip")
        
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        var request = URLRequest(url: NCONFIG.soundsUrl.url)
        request.assumesHTTP3Capable = true
        
        let (data, response) = try await session.download(for: request)
        
        guard let response = response as? HTTPURLResponse else{ throw NetworkManager.APIError.invalidURL}
        
        guard 200...299 ~= response.statusCode else{
            throw NetworkManager.APIError.invalidCode(response.statusCode)
        }
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: data, to: destinationURL)
        
        let result = try Zip.quickUnzipFile(destinationURL)
 
        if let soundsUrl = NCONFIG.getDir(.sounds){
            moveFiles(from: result, to: soundsUrl, skip: self.allSounds())
        }
        
        self.updateFileList()
        
        try? FileManager.default.removeItem(at: result)
        try? FileManager.default.removeItem(at: destinationURL)
    }
    
    func moveFiles( from sourceDir: URL,  to destinationDir: URL, skip skipFiles: [String] ) {
        
        let fileManager = FileManager.default

        // Ensure destination exists
        if !fileManager.fileExists(atPath: destinationDir.path) {
            do {
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create destination directory: \(error)")
                return
            }
        }

       

        // Enumerate source directory
        guard let enumerator = fileManager.enumerator(at: sourceDir,
                                                      includingPropertiesForKeys: [.isDirectoryKey],
                                                      options: [.skipsHiddenFiles]) else {
            print("Unable to access source directory.")
            return
        }

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.isDirectoryKey])

                // Skip folders
                if values.isDirectory == true { continue }

                let fileName = fileURL.lastPathComponent

                // ❌ If filename is in skip list → skip
                if skipFiles.contains(fileName) {
                    print("Skipped (in skip list): \(fileName)")
                    continue
                }

                // Destination path
                let destinationURL = destinationDir.appendingPathComponent(fileName)

                // Skip if destination already has same file
                if fileManager.fileExists(atPath: destinationURL.path) {
                    print("Skipped (duplicate in destination): \(fileName)")
                    continue
                }

                // Move the file
                try fileManager.moveItem(at: fileURL, to: destinationURL)
                print("Moved: \(fileName)")

            } catch {
                print("Error moving file \(fileURL.lastPathComponent): \(error)")
            }
        }
    }

}
