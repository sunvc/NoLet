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

import ActivityKit
import AVKit
import Defaults
import Foundation
import SwiftUI
import Zip

// MARK: - 铃声界面播放铃声 Actor

final class AudioManager: NetworkManager, ObservableObject {
    static let shared = AudioManager()

    @Published var defaultSounds: [URL] = []
    @Published var customSounds: [URL] = []

    @Published var loading: Bool = false
    @Published var ShareURL: URL? = nil

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
        updateFileList()
    }

    /// 播放或暂停音频
    func togglePlay(url: URL) {
        if currentURL == url {
            //  如果是同一个文件，则切换播放状态
            if isPlaying {
                play(pause: true)
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
        playerItemStatusObserver = playerItem.observe(\.status, options: [.new]) {
            [weak self] item, _ in
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
            Task { @MainActor in
                self.currentTime = time.seconds
                if let dur = self.player?.currentItem?.duration.seconds, dur > 0 {
                    self.duration = dur
                }
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
            Task { @MainActor in
                self.cleanup()
            }
        }
    }

    /// 播放
    func play(pause: Bool = false, stop: Bool = false) {
        if stop {
            cleanup()
        } else {
            if pause {
                player?.pause()
                isPlaying = false
            } else {
                player?.play()
                isPlaying = true
            }
        }
    }

    /// 跳转到指定时间
    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
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

    @MainActor
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

extension AudioManager {
    func allSounds() -> [String] {
        let (customSounds, defaultSounds) = getFileList()
        return (customSounds + defaultSounds).map {
            $0.deletingPathExtension().lastPathComponent
        }
    }

    // MARK: - Get audio folder data

    func getFileList() -> ([URL], [URL]) {
        // 加载 Bundle 中的默认 caf 音频资源
        let defaultSounds: [URL] = {
            // 从 App Bundle 获取所有 caf 文件
            var temurl = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []

            // 按文件名自然排序（考虑数字顺序、人类习惯排序）
            temurl.sort { u1, u2 -> Bool in
                u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent)
                    == .orderedAscending
            }

            return temurl
        }()

        // 加载 App Group 共享目录中的自定义 caf 音频资源
        let customSounds: [URL] = {
            // 获取共享目录路径
            guard let soundsDirectoryURL = NCONFIG.getDir(.sounds) else { return [] }

            // 获取指定后缀（caf），排除长音前缀的文件
            var urlemp = self.getFilesInDirectory(
                directory: soundsDirectoryURL.path(), suffix: "caf"
            )

            // 同样进行自然排序
            urlemp.sort { u1, u2 -> Bool in
                u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent)
                    == .orderedAscending
            }

            return urlemp
        }()

        return (customSounds, defaultSounds)
    }

    /// 加载系统默认音效和用户自定义音效文件列表
    func updateFileList() {
        Task.detached(priority: .userInitiated) {
            let (customSounds, defaultSounds) = await self.getFileList()
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
                if file.lowercased().hasSuffix(suffix.lowercased()),
                   !file.hasPrefix(NCONFIG.longSoundPrefix)
                {
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
}

nonisolated enum Tone {
    
    static func play(_ sound: TipsSound, fileExtension: String = "aac") async {
        await play(sound.rawValue, fileExtension: fileExtension)
    }

    static func play(
        _ sound: String,
        fileExtension: String = "aac"
    ) async {
        // 1. 检查设置
        guard await Defaults[.feedbackSound] else { return }
        var localSoundID: SystemSoundID = 0

        AudioServicesDisposeSystemSoundID(localSoundID)

        if let number = Int(sound) {
            localSoundID = SystemSoundID(number)
        } else if let url = Bundle.main.url(forResource: sound, withExtension: fileExtension) {
            AudioServicesCreateSystemSoundID(url as CFURL, &localSoundID)
        }

        if localSoundID != 0 {
            AudioServicesPlaySystemSoundWithCompletion(localSoundID) {
                AudioServicesDisposeSystemSoundID(localSoundID)
            }
        }
    }

    enum TipsSound: String {
        case qrcode
        case share
    }
}
