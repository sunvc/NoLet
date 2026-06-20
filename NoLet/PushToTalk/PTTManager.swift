//
//  PTTManager.swift
//  NoLet
//
//  Created by lynn on 2025/8/24.
//

import AVFoundation
import Combine
import Foundation
import GRDB
import Opus
import os
import PushToTalk
import UIKit

final class PushTalkManager: ObservableObject {
    static let shared = PushTalkManager()

    @Published var powerState: Bool = false
    @Published var serverStatus: ServerState = .offline
    @Published var micLevel: Double = .zero
    @Published var elapsedTime: TimeInterval = 0
    @Published var state: State = .idle
    @Published var hasMicrophonePermission: Bool = false

    @Published var lastFile: AudioMessage? = nil
    @Published var waitPlayList: [AudioMessage] = []
    @Published var messages: [AudioMessage] = []

    @Published var currentPlayFile: AudioMessage? = nil

    @Published var currentPlayTime: Double = 0
    @Published var totalPlayTime: Double = 0
    @Published var hasPermission: Bool = false

    var channelManager: PTChannelManager?

    let audioHandler = CombinedAudioManager()

    private let database = DatabaseManager.shared
    private let network = NetworkManager()

    private var observationCancellable: AnyDatabaseCancellable?
    private var loopTask: Task<Void, Never>?

    let kGlobalPTTChannelUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func deleteAll() {
        _ = try? DatabaseManager.shared.dbQueue.write { db in
            try AudioMessage.deleteAll(db)
            if let path = NCONFIG.getDir(.ptt) {
                try FileManager.default.removeItem(at: path)
            }
        }
    }

    private init() {
        try? AudioMessage.createInit(dbQueue: DatabaseManager.shared.dbQueue)
        audioHandler.delegate = self
        startObservingUnreadCount()
        self.TaskHandler()
        self.setupNotifications()
    }

    deinit {
        observationCancellable?.cancel()
        loopTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            self.send(.interruptionBegan)

        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let shouldResume = options.contains(.shouldResume)

            self.send(.interruptionEnded(shouldResume: shouldResume))

        @unknown default:
            break
        }
    }

    private func TaskHandler() {
        self.loopTask = Task(priority: .utility) { [weak self] in
            logger.info("🚀 后台常驻任务已在线程: \(Thread.current) 启动")
            while !Task.isCancelled {
                guard let self = self else { break }
                if self.powerState {
                    await self.publicJoinConnect()
                }

                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    logger.info("Task 休眠被中断，准备退出")
                    break
                }
            }

            logger.info("🛑 后台常驻任务已安全退出")
        }
    }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (
            [AudioMessage],
            [AudioMessage]
        ) in
            let messages = try AudioMessage
                .order(AudioMessage.Columns.timestamp.desc)
                .limit(50)
                .fetchAll(db)
            let unreadMessages = try AudioMessage
                .order(AudioMessage.Columns.timestamp.desc)
                .filter { !$0.read }
                .fetchAll(db)
            return (messages, unreadMessages)
        }

        observationCancellable = observation.start(
            in: database.dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                logger.error("Failed to observe unread count: \(error)")
            },
            onChange: { [weak self] newMessages, unReadMessages in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.messages = newMessages
                    self.waitPlayList = unReadMessages
                }
            }
        )
    }

    func send(_ event: Event, remote: Bool = false) {
        logger.info("STATE: \(self.state.log)")
        logger.info("EVENT: \(event.log)")

        switch (state, event) {
           //==================================================
           // Idle
           //==================================================

        case (.idle, .startPlay(let message)):
            if let message {
                beginPlay(message)
            } else {
                self.playWaitList()
            }

        case (.idle, .startRecord(let activity)):
            beginRecord(activity)

        case (.idle, .recordStarted):
            internalStopRecord(isCancel: true)

           //==================================================
           // Preparing Play
           //==================================================

        case (.preparingPlay, .playStarted):
            if case .preparingPlay(let message) = state {
                state = .playing(message)
            }

        case (.preparingPlay, .stopPlay):
            state = .idle
            internalStopPlay()

        case (.preparingPlay, .startRecord(let activity)):
            internalStopPlay()
            beginRecord(activity)

           //==================================================
           // Playing
           //==================================================

        case (.playing, .stopPlay):
            internalStopPlay()
            state = .idle

        case (.playing, .playFinished):
            currentPlayFile = nil
            state = .idle
            self.playWaitList()

        case (.playing, .startPlay(let message)):
            guard let message else { break }
            if message == self.currentPlayFile {
                internalStopPlay()
                currentPlayFile = nil
                return
            }
            // FIXME: -  处理连续播放, 如果是远程, 忽略打断
            if !remote {
                internalStopPlay()
                beginPlay(message)
            }

        case (.playing, .startRecord(let activity)):
            internalStopPlay()
            currentPlayFile = nil
            beginRecord(activity)

           //==================================================
           // Recording
           //==================================================

        case (.recording, .stopRecord(let cancel)):
            internalStopRecord(isCancel: cancel)
            state = .idle
            self.playWaitList()

        // 录音期间禁止播放
        case (.recording, .startPlay):
            logger.info("Ignore play while recording")

            //==================================================
            // interruptionBegan
            //==================================================

        case (.playing(let message), .interruptionBegan),
             (.preparingPlay(let message), .interruptionBegan):
            self.state = .interrupted(message)
            self.internalStopPlay()

        case (.recording, .interruptionBegan):
            self.send(.stopRecord(false))

        case (.interrupted(let message), .interruptionEnded(let shouldResume)):
            if shouldResume {
                self.state = .interruptionEnded(shouldResume, message)
                self.channelManager?.setActiveRemoteParticipant(
                    PTParticipant(name: "恢复播放", image: "字,FF9500".avatarImage()),
                    channelUUID: self.kGlobalPTTChannelUUID
                )
            } else {
                // 系统不建议恢复，直接回到空闲
                self.state = .idle
                self.internalStopPlay()
            }

        case (.interruptionEnded(let resume, let message), .resume):
            if resume {
                beginPlay(message)
            } else {
                self.state = .idle
                self.internalStopPlay()
            }

        case (.interrupted, .stopPlay):
            self.state = .idle
            self.internalStopPlay()
           //==================================================
           // Ignore
           //==================================================

        default:
            break
        }
    }

    func joinConnect() async throws {
        // 1. 状态前置
        self.powerState = true
        self.serverStatus = .connecting
        self.setServerStatus(.connecting, id: self.kGlobalPTTChannelUUID)

        // 2. ✨ 音频权限与初始化（注意：确保你的音频初始化有正确的容错）
        if !hasPermission {
            audioHandler.requestAudioPermission()
        }
        audioHandler.setupAudio()

        await self.publicJoinConnect()

        self.serverStatus = Defaults[.pttChannel].users > 0 ? .online : .offline
        try await channelManager?.setTransmissionMode(
            .fullDuplex,
            channelUUID: kGlobalPTTChannelUUID
        )

        self.setServerStatus(
            Defaults[.pttChannel].users > 0 ? .ready : .unavailable,
            id: kGlobalPTTChannelUUID
        )
    }

    func levelConnect() async {
        self.powerState = false
        self.serverStatus = .offline

        await self.publicLevelConnect(Defaults[.pttHisChannel])
        Defaults[.pttChannel].users = 0
    }

    func publicLevelConnect(_ channels: [PTTChannel]) async {
        let result = await self.connect(channels: channels, join: false)

        var historyChannels = Defaults[.pttHisChannel]
        for item in channels {
            if let index = historyChannels.firstIndex(of: item) {
                historyChannels[index].active = false
                historyChannels[index].users = 0
            }
        }
        Defaults[.pttHisChannel] = historyChannels

        logger.log("LEVEL: \(result.count)")
    }

    func publicJoinConnect() async {
        Defaults[.pttHisChannel].set(Defaults[.pttChannel], active: true)

        var historyChannels = Defaults[.pttHisChannel]

        let activeChannels = historyChannels.filter { $0.active }

        let results = await self.connect(channels: activeChannels, join: true)

        let resultMap = Dictionary(uniqueKeysWithValues: results.map {
            ("\($0.host)_\($0.channel)", $0)
        })

        for index in historyChannels.indices {
            let channel = historyChannels[index]
            let cacheKey = "\(channel.server.url)_\(channel.hex())"

            if let matchedResult = resultMap[cacheKey] {
                historyChannels[index].users = matchedResult.users
                historyChannels[index].timestamp = .now
            } else if channel.active {
                historyChannels[index].users = 0
            }
        }

        Defaults[.pttHisChannel] = historyChannels

        var currentChannel = Defaults[.pttChannel]
        let currentKey = "\(currentChannel.server.url)_\(currentChannel.hex())"

        if let matchedResult = resultMap[currentKey] {
            currentChannel.timestamp = .now
            currentChannel.users = matchedResult.users

            Defaults[.pttChannel] = currentChannel
            self.serverStatus = .online
        } else {
            currentChannel.users = 0
            Defaults[.pttChannel] = currentChannel
            if let firstRes = results.first,
               let matchedChannel = historyChannels.first(where: {
                   $0.hex() == firstRes.channel && $0.server.url == firstRes.host
               })
            {
                Defaults[.pttChannel] = matchedChannel
            }
        }
    }

    private func setServerStatus(_ status: PTServiceStatus, id: UUID) {
        Task {
            try? await channelManager?.setServiceStatus(status, channelUUID: id)
        }
    }

    @discardableResult
    private func read(message: AudioMessage) -> Bool {
        return (try? DatabaseManager.shared.dbQueue.write { db in
            do {
                if var message = try AudioMessage.fetchOne(db, id: message.id) {
                    message.read = true
                    try message.save(db)
                }
                return true
            } catch {
                return false
            }

        }) ?? false
    }

    func playWaitList() {
        guard let message = waitPlayList.last else {
            self.send(.stopPlay)
            self.setRemoteOver()
            return
        }
        self.send(.startPlay(message))
    }

    private func beginPlay(_ message: AudioMessage) {
        state = .preparingPlay(message)

        logger.info("Start Play:\(message.file)")

        currentPlayFile = message
        self.read(message: message)

        Task {
            // 实际接入你的播放器
            send(.playStarted)
            if let currentUrl = message.filePath() {
                await self.audioHandler.playAudio(currentUrl)
            }
            // 播放结束回调
            send(.playFinished)
        }
    }

    private func internalStopPlay() {
        logger.info("Stop Play")
        self.audioHandler.stopPlay()

        if case .interrupted = state {
            self.setRemoteOver()
        }

        if self.waitPlayList.isEmpty {
            self.setRemoteOver()
        }
    }

    private func beginRecord(_ activity: Bool = true) {
        state = .recording
        logger.info("Start Record")
        audioHandler.startRecording(activity, pttMusicPlay: Defaults[.pttMusicPlay])
        send(.recordStarted)
    }

    private func internalStopRecord(isCancel: Bool) {
        logger.info("Stop Record")

        if let data = audioHandler.stopRecording(), !isCancel {
            if let file = self.saveVoice(data: data) {
                Task {
                    await self.sendVoice(message: file)
                }
                if !isCancel {
                    self.lastFile = file
                }
            }
        }
    }

    private func setRemoteOver() {
        self.channelManager?.setActiveRemoteParticipant(
            nil,
            channelUUID: kGlobalPTTChannelUUID
        )
    }

    func saveVoice(data: Data) -> AudioMessage? {
        let id = Defaults[.id]
        let channel = Defaults[.pttChannel]
        guard let filePath = channel.filePath(userID: id) else { return nil }

        do {
            try data.write(to: filePath)
            let voice = try self.database.dbQueue.write { db in
                let voice = AudioMessage(
                    channel: channel.hex(),
                    from: id,
                    file: filePath.lastPathComponent,
                    read: true
                )
                try voice.save(db)
                return voice
            }
            return voice
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }

    func saveVoice(remoteUrl: String) async -> AudioMessage? {
        do {
            guard let remoteFileUrl = URL(string: remoteUrl),
                  let voice = AudioMessage(remote: remoteFileUrl),
                  let filePath = NCONFIG.getDir(.ptt)?.appendingPathComponent(voice.file),
                  let data = await self.getVoice(remote: remoteFileUrl, decode: voice.sign)
            else {
                return nil
            }

            try data.write(to: filePath)

            return try await self.database.dbQueue.write { db in
                try voice.save(db)
                return voice
            }

        } catch {
            return nil
        }
    }

    func setDB(_ value: Float) {
        self.audioHandler.setVolume(value)
    }

    func changeEQ() {
        self.audioHandler.changeEQ(
            bands: Defaults[.eqBands],
            globalGain: Float(Defaults[.globalGain])
        )
    }

    // MARK: - OTHER

    nonisolated func playTips(
        _ fileName: TipsSound,
        fileExtension: String = "aac",
        complete: (() -> Void)? = nil
    ) {
        guard let url = Bundle.main
            .url(forResource: fileName.rawValue, withExtension: fileExtension) else { return }

        var soundID: SystemSoundID = 0

        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    private func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }

        let channelDataValue = channelData.pointee
        // 4
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        )
        .map { channelDataValue[$0] }

        // 5
        let rms = sqrt(channelDataValueArray.map {
            $0 * $0
        }
        .reduce(0, +) / Float(buffer.frameLength))

        // 6
        let avgPower = 20 * log10(rms)
        // 7
        let meterLevel = scaledPower(power: avgPower)

        return Double(meterLevel)
    }

    private func scaledPower(power: Float) -> Float {
        // 1. 避免 NaN 或 Inf
        guard power.isFinite else {
            return 0.0
        }

        // 参考的最小分贝值（静音阈值）
        let minDb: Float = -80.0

        // 2. 小于阈值直接当作静音
        if power < minDb {
            return 0.0
        }

        // 3. 如果超过 1.0（非常大声），直接归一化到 1.0
        if power >= 1.0 {
            return 1.0
        }

        // 4. 按比例线性映射到 0~1
        return (abs(minDb) - abs(power)) / abs(minDb)
    }
}

extension PushTalkManager: AudioHardwareDelegate {
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    ) {
        DispatchQueue.main.async {
            self.totalPlayTime = duration
            self.currentPlayTime = currentTime
        }
    }

    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    ) {
        DispatchQueue.main.async {
            self.micLevel = power
            self.elapsedTime = duration
        }
    }

    // MARK: - 麦克风权限

    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateMicrophonePermission hasPermission: Bool
    ) {
        DispatchQueue.main.async {
            self.hasPermission = hasPermission
        }
    }
}

extension PushTalkManager {
    func connect(channels: [PTTChannel], join: Bool) async -> [JoinResponse] {
        let groupedChannels = Dictionary(grouping: channels, by: { $0.server.url })

        return await withTaskGroup(of: [JoinResponse]?.self) { group in
            for (_, serverChannels) in groupedChannels {
                group.addTask {
                    if let data = await self._connect(channels: serverChannels, join: join) {
                        return data.data
                    }
                    return nil
                }
            }
            var allResponses: [JoinResponse] = []
            for await response in group {
                if let response = response {
                    allResponses += response
                }
            }

            return allResponses
        }
    }

    nonisolated struct JoinParams: Codable, Sendable {
        var id: String
        var channels: [String]
        var token: String
        var host: String
    }

    nonisolated struct JoinResponse: Codable, Sendable {
        var host: String
        var channel: String
        var users: Int
    }

    private func _connect(
        channels: [PTTChannel],
        join: Bool
    ) async -> baseResponse<[JoinResponse]>? {
        guard let channel = channels.first, channel.serverOK else {
            Toast.info(title: "语音服务器错误")
            return nil
        }

        do {
            let hzs = channels.map { $0.hex() }
            logger.log("channel:\(hzs)")

            let signHeaders = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )

            let params = JoinParams(
                id: Defaults[.id],
                channels: hzs,
                token: join ? Defaults[.pttToken] : "",
                host: channel.server.url
            )

            guard let result: baseResponse<[JoinResponse]> =
                try await self.network.fetch(
                    url: channel.server.url,
                    path: "/ptt/connect",
                    method: .POST,
                    params: params,
                    headers: signHeaders,
                    timeout: 5
                )
            else {
                throw "请求失败"
            }

            return result
        } catch {
            logger.error("\(error)")
            return nil
        }
    }

    func sendVoice(message: AudioMessage) async -> Bool {
        let channel = Defaults[.pttChannel]
        guard channel.serverOK else {
            Toast.info(title: "语音服务器错误")
            return false
        }

        guard let filePath = message.filePath() else {
            return false
        }

        do {
            var data = try Data(contentsOf: filePath)
            /// 加密
            let pttSignature = Defaults[.pttSignature]
            if pttSignature {
                guard let encryptedData = CryptoModelConfig.data.encrypt(inputData: data) else {
                    throw "encrypt error"
                }
                data = encryptedData
            }

            let signHeaders = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )
            let fileHeaders = [
                "X-PFA": "\(pttSignature ? "1" : "0")-\(message.file)",
            ]

            let response = try await self.network.uploadFile(
                data: data,
                url: channel.server.url,
                path: "/ptt/voice",
                headers: fileHeaders.merging(signHeaders) { current, _ in current }
            )

            let result = try JSONDecoder().decode(baseResponse<Int64>.self, from: response)

            return result.code == 200
        } catch {
            logger.error("\(error.localizedDescription)")
            Toast.error(title: "发送语音失败")
            return false
        }
    }

    private func getVoice(remote remoteFileURL: URL, decode: Bool = false) async -> Data? {
        do {
            let channel = Defaults[.pttChannel]

            let response = try await self.network.fetch(
                url: remoteFileURL.absoluteString,
                headers: CryptoManager.signature(
                    sign: channel.server.sign,
                    server: channel.server.key
                )
            )

            var data = response.data
            /// 解密
            if decode {
                guard let decodeData = CryptoModelConfig.data.decrypt(inputData: data)
                else { throw "decrypt error" }
                data = decodeData
            }

            return data
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }
}

extension PushTalkManager {
    // MARK: - State

    enum ServerState {
        case offline
        case connecting
        case online
        case failed
    }

    enum State: Equatable {
        case idle

        case preparingPlay(AudioMessage)
        case playing(AudioMessage)

        case recording

        case interrupted(AudioMessage)
        case interruptionEnded(Bool, AudioMessage)

        var title: String {
            switch self {
            case .idle:
                return String(localized: "空闲中")
            case .preparingPlay:
                return String(localized: "等待硬件")
            case .playing:
                return String(localized: "正在播放...")
            case .recording:
                return String(localized: "正在说话...")
            case .interrupted:
                return String(localized: "播放已打断...")
            case .interruptionEnded:
                return String(localized: "等待恢复...")
            }
        }

        var log: String {
            switch self {
            case .idle:
                return String(localized: "空闲")
            case .preparingPlay(let value):
                return String(localized: "等待播放: \(value.file)")
            case .playing(let value):
                return String(localized: "正在播放: \(value.file)")
            case .recording:
                return String(localized: "正在录音")
            case .interrupted(let value):
                return String(localized: "播放被打断挂起: \(value.file)")
            case .interruptionEnded(let resume, let value):
                return String(localized: "播放等待恢复\(String(describing: resume)): \(value.file)")
            }
        }
    }

    // MARK: - Event

    enum Event {
        case startPlay(AudioMessage?)
        case stopPlay

        case startRecord(Bool)
        case stopRecord(Bool)

        case playStarted
        case playFinished

        case recordStarted

        // 👈 新增：打断事件
        case interruptionBegan
        /// 打断结束，携带系统是否建议自动恢复的参数
        case interruptionEnded(shouldResume: Bool)
        case resume

        var log: String {
            switch self {
            case .startPlay(let message):
                // 建议打印出 model 的唯一标识（例如 id 或 msgId），方便排查具体是哪条语音
                return String(localized: "请求播放 - 消息ID: \(message?.file ?? "nil")")

            case .stopPlay:
                return String(localized: "请求停止播放")

            case .startRecord(let isActivity):
                return String(localized: "请求开始录音: 内部-\(String(describing: isActivity))")

            case .stopRecord(let isSave):
                return String(localized: "请求停止录音 (是否保存/发送: \(String(describing: isSave)))")

            case .playStarted:
                return String(localized: "底层硬件: 播放已实际开始")

            case .playFinished:
                return String(localized: "底层硬件: 播放已正常结束")

            case .recordStarted:
                return String(localized: "底层硬件: 录音已实际开始")

            case .interruptionBegan:
                return String(localized: "底层硬件: 收到音频打断开始信号")

            case .interruptionEnded(let shouldResume):
                return String(
                    localized: "底层硬件: 收到音频打断结束信号 (建议恢复: \(String(describing: shouldResume)))"
                )

            case .resume:
                return String(localized: "恢复播放")
            }
        }
    }
}

nonisolated extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
