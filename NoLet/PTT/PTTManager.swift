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
    @Published var channelUsers: Int = 0
    @Published var lastFile: PttMessageModel? = nil
    @Published var waitPlayList: [PttMessageModel] = []
    @Published var messages: [PttMessageModel] = []

    @Published var currentPlayFile: PttMessageModel? = nil

    @Published var currentPlayTime: Double = 0
    @Published var totalPlayTime: Double = 0
    @Published var hasPermission: Bool = false

    var channelManager: PTChannelManager?

    let audioHandler = CombinedAudioManager()

    private let database = DatabaseManager.shared
    private let network = NetworkManager()

    private var observationCancellable: AnyDatabaseCancellable?

    func deleteAll() {
        _ = try? DatabaseManager.shared.dbQueue.write { db in
            try PttMessageModel.deleteAll(db)
            if let path = NCONFIG.getDir(.ptt) {
                try FileManager.default.removeItem(at: path)
            }
        }
    }

    private init() {
        try? PttMessageModel.createInit(dbQueue: DatabaseManager.shared.dbQueue)
        audioHandler.delegate = self
        startObservingUnreadCount()
    }

    deinit {
        observationCancellable?.cancel()
    }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (
            [PttMessageModel],
            [PttMessageModel]
        ) in
            let messages = try PttMessageModel
                .order(PttMessageModel.Columns.timestamp.desc)
                .limit(50)
                .fetchAll(db)
            let unreadMessages = try PttMessageModel
                .order(PttMessageModel.Columns.timestamp.desc)
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

    func joinConnect() async throws {
        self.powerState = true
        self.serverStatus = .connecting

        if !hasPermission {
            audioHandler.requestAudioPermission()
        }
        audioHandler.setupAudio()

        let channel = Defaults[.pttChannel]
        self.setServerStatus(.connecting, id: channel.channelID)

        let result = await self.connect(channel: channel, join: true)

        if let data = result?.data {
            self.channelUsers = data
            logger.log("频道人数:\(data)")
        }

        let success = result?.code == 200

        self.serverStatus = success ? .online : .failed

        try await channelManager?.setTransmissionMode(
            .fullDuplex,
            channelUUID: channel.channelID
        )

        self.setServerStatus(success ? .ready : .unavailable, id: channel.channelID)
    }

    func levelConnect() async {
        self.powerState = false
        self.serverStatus = .connecting
        let data = Defaults[.pttChannel]
        let result = await self.connect(channel: data, join: false)
        self.serverStatus = result?.code == 200 ? .offline : .failed
    }

    private func setServerStatus(_ status: PTServiceStatus, id: UUID) {
        Task {
            try? await channelManager?.setServiceStatus(status, channelUUID: id)
        }
    }

    func send(_ event: Event) {
        logger.info("STATE: \(self.state.log)")
        logger.info("EVENT: \(event.log)")

        switch (state, event) {
           //==================================================
           // Idle
           //==================================================

        case (.idle, .startPlay(let message)):
            beginPlay(message)

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
            internalStopPlay()
            state = .idle

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
            if message == self.currentPlayFile {
                internalStopPlay()
                currentPlayFile = nil
                return
            }
            internalStopPlay()
            beginPlay(message)

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
           // Ignore
           //==================================================

        default:
            break
        }
    }

    @discardableResult
    private func read(message: PttMessageModel) -> Bool {
        return (try? DatabaseManager.shared.dbQueue.write { db in
            do {
                if var message = try PttMessageModel.fetchOne(db, id: message.id) {
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
        guard let message = waitPlayList.first else {
            self.send(.stopPlay)
            return
        }
        self.send(.startPlay(message))
    }

    private func beginPlay(_ message: PttMessageModel) {
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

    private func beginRecord(_ activity: Bool = true) {
        state = .recording
        logger.info("Start Record")
        audioHandler.startRecording(activity, pttMusicPlay: Defaults[.pttMusicPlay])
        send(.recordStarted)
    }

    private func internalStopPlay() {
        logger.info("Stop Play")
        self.audioHandler.stopPlay()
        self.channelManager?.setActiveRemoteParticipant(
            nil,
            channelUUID: Defaults[.pttChannel].channelID
        )
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

    func saveVoice(data: Data) -> PttMessageModel? {
        let id = Defaults[.id]
        let channel = Defaults[.pttChannel]
        guard let filePath = channel.filePath(userID: id) else { return nil }

        do {
            try data.write(to: filePath)
            let voice = try self.database.dbQueue.write { db in
                let voice = PttMessageModel(
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

    func saveVoice(remoteUrl: String) async -> PttMessageModel? {
        do {
            guard let remoteFileUrl = URL(string: remoteUrl),
                  let voice = PttMessageModel(remote: remoteFileUrl),
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
        // 先释放之前的 SystemSoundID（如果有），避免内存泄漏或重复播放
        var soundID: SystemSoundID = 0
//        AudioServicesDisposeSystemSoundID(soundID)

        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        // 播放音频，播放完成后执行回调
        AudioServicesPlaySystemSound(soundID)
//        AudioServicesPlaySystemSoundWithCompletion(soundID) {
//            // 释放资源
//            AudioServicesDisposeSystemSoundID(soundID)
//            complete?()
//        }
    }

    // MARK: - OTHER

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
    func connect(channel: PTTChannel, join: Bool) async -> baseResponse<Int>? {
        guard channel.serverOK else {
            Toast.info(title: "语音服务器错误")
            return nil
        }

        do {
            logger.log("channel:\(channel.hex())")

            guard let result: baseResponse<Int> =
                try await self.network.fetch(
                    url: channel.server.url,
                    path: "/ptt/connect",
                    method: .POST,
                    params: [
                        "id": Defaults[.id],
                        "channel": channel.hex(),
                        "token": join ? Defaults[.pttToken] : "",
                    ],
                    headers: [
                        "Authorization": Defaults[.id],
                        "channel": channel.hex(),
                    ],
                    timeout: 5
                )
            else {
                throw "请求失败"
            }

            return result
        } catch {
            logger.error("\(error)")
            Toast.error(title: "语音服务连接失败")
            return nil
        }
    }

    func sendVoice(message: PttMessageModel) async -> Bool {
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

            let response = try await self.network.uploadFile(
                data: data,
                url: channel.server.url,
                path: "/ptt/voice",
                headers: [
                    "X-PFA": "\(pttSignature ? "1" : "0")-\(message.file)",
                    "Authorization": Defaults[.id],
                    "channel": channel.hex(),
                ]
            )

            let result = try JSONDecoder().decode(baseResponse<Int64>.self, from: response)

            if let users = result.data, users >= 0 {
                self.channelUsers = Int(users)
            }

            return result.code == 200
        } catch {
            logger.error("\(error.localizedDescription)")
            Toast.error(title: "发送语音失败")
            return false
        }
    }

    private func getVoice(remote remoteFileURL: URL, decode: Bool = false) async -> Data? {
        do {
            let response = try await self.network.fetch(
                url: remoteFileURL.absoluteString,
                headers: [
                    "Authorization": Defaults[.id],
                    "channel": Defaults[.pttChannel].hex(),
                ]
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

        case preparingPlay(PttMessageModel)
        case playing(PttMessageModel)

        case recording

        var title: String {
            switch self {
            case .idle:
                return String(localized: "空闲中")

            // 如果你希望播放和录音的准备阶段都显示“等待硬件”
            case .preparingPlay:
                return String(localized: "等待硬件")

            // 带有关联值的 case，如果用不到 url，可以直接写 .playing
            case .playing:
                return String(localized: "正在播放...")

            case .recording:
                return String(localized: "正在说话...")
            }
        }

        var isPlaying: Bool {
            if case .playing = self { return true }
            return false
        }

        var isRecording: Bool {
            if case .recording = self { return true }
            return false
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
            }
        }
    }

    // MARK: - Event

    enum Event {
        case startPlay(PttMessageModel)
        case stopPlay

        case startRecord(Bool)
        case stopRecord(Bool)

        case playStarted
        case playFinished

        case recordStarted

        var log: String {
            switch self {
            case .startPlay(let model):
                // 建议打印出 model 的唯一标识（例如 id 或 msgId），方便排查具体是哪条语音
                return String(localized: "请求播放 - 消息ID: \(model.file)")

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
            }
        }
    }
}
