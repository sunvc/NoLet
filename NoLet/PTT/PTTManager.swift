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
import os

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

/// AudioHardwareDelegate
/// 
/// 
nonisolated protocol AudioHardwareDelegate: AnyObject {
    /// 实时回调播放进度
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    )

    /// 实时回调录音音量和已录制时长 👈 【修改这里】
    /// - Parameters:
    ///   - power: 平均分贝值
    ///   - duration: 当前已录制的总时长（秒数）
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    )

    /// 麦克风权限状态变化
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateMicrophonePermission hasPermission: Bool
    )
}

final nonisolated class CombinedAudioManager: @unchecked Sendable {
    var delegate: AudioHardwareDelegate?
    /// walkie-talkie
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    private var recordedAudioData = Data()
    private var oggWriter = OggOpusWriter()
    private var dataItem = DataItem()
    private var timer: DispatchSourceTimer?
    // 跳过提示音的样本数
    private var skippedSamplesCount: UInt32 = 0
    // play
    private var playbackAudioEngine: AVAudioEngine?
    private var playbackPlayerNode: AVAudioPlayerNode?
    private(set) var audioUnitEQ: AVAudioUnitEQ?

    private var hasMicrophonePermission: Bool = false

    var currentPlaybackTime: Double {
        // 1. 安全守护：拿到 playerNode
        guard let playerNode = playbackPlayerNode else { return 0 }

        // 2. 核心修复：检查当前节点是否依然和有效的引擎绑定，且引擎正在运行
        // 如果引擎已经 stop 或者节点被 detach，直接安全返回 0
        guard let engine = playerNode.engine, engine.isRunning else {
            return 0
        }

        // 3. 此时访问 lastRenderTime 才是绝对安全的
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else {
            return 0
        }

        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    func startTimer(total: Double) {
        stopTimer()

        let timer = DispatchSource.makeTimerSource()

        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(100)
        )

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }

            self.delegate?.audioManager(
                self,
                didUpdateCurrentTime: self.currentPlaybackTime,
                duration: total
            )
        }

        timer.resume()

        self.timer = timer
    }

    private func stopTimer() {
        self.delegate?.audioManager(self, didUpdateCurrentTime: 0, duration: 0)
        timer?.cancel()
        timer = nil
    }

    func setVolume(_ value: Float? = nil) {
        if let value {
            playbackPlayerNode?.volume = value
        } else {
            Task {
                let volume = await Defaults[.pttVoiceVolume]
                playbackPlayerNode?.volume = Float(volume)
            }
        }
    }

    func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            self.hasMicrophonePermission = granted
            logger.debug("Permesso microfono: \(granted ? "concesso" : "negato")")
            self.delegate?.audioManager(self, didUpdateMicrophonePermission: granted)
        }
    }

    func setupAudio() {
        logger.debug("Inizializzazione sistema audio...")

        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )

            try audioSession.setPreferredSampleRate(48000.0)
            try audioSession.setPreferredIOBufferDuration(0.06)

            try audioSession.setActive(true)
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else {
                logger.debug("ERROR:  Inizializzazione audio engine")
                return
            }

            // Configura input node
            let inputNode = audioEngine.inputNode
            self.inputNode = inputNode

            // Usa il formato nativo dell'input node direttamente
            let nativeFormat = inputNode.outputFormat(forBus: 0)

            // Usa il formato nativo per evitare problemi di conversione
            audioFormat = nativeFormat

            guard audioFormat != nil else {
                logger.debug("ERROR: Configurazione formato audio")
                return
            }

            logger.debug("Sistema audio inizializzato correttamente")

        } catch {
            logger.debug("Setup audio:\(error)")
        }
    }

    func startRecording(_ activity: Bool = true, pttMusicPlay: Bool) {
        logger.debug("Avvio trasmissione audio...")

        guard self.hasMicrophonePermission else {
            self.requestAudioPermission()
            return
        }

        // Ferma e resetta l'audio engine se già attivo
        if let audioEngine = audioEngine, audioEngine.isRunning {
            inputNode?.removeTap(onBus: 0)
            audioEngine.stop()
        }

        setupAudio()

        self.delegate?.audioManager(
            self,
            didUpdateRecordingPower: 0,
            duration: 0
        )

        guard let audioEngine = audioEngine, let inputNode = inputNode,
              let audioFormat = audioFormat
        else {
            return
        }

        do {
            oggWriter = OggOpusWriter()
            dataItem = DataItem()
            oggWriter.inputSampleRate = Int32(audioFormat.sampleRate)
            oggWriter.begin(with: dataItem)

            recordedAudioData = Data()

            // Validazione formato prima di installare tap
            guard audioFormat.sampleRate > 0, audioFormat.channelCount > 0 else {
                logger
                    .debug(
                        "Formato audio non valido: SR=\(audioFormat.sampleRate), CH=\(audioFormat.channelCount)"
                    )
                return
            }
            self.skippedSamplesCount = 0
            let targetSampleCount = UInt32(audioFormat.sampleRate * 0.26)

            inputNode
                .installTap(
                    onBus: 0,
                    bufferSize: 1024,
                    format: audioFormat
                ) { buffer, _ in
                    let elapsedTime = self.oggWriter.encodedDuration()

                    // 切除提示音
                    if activity, pttMusicPlay, self.skippedSamplesCount < targetSampleCount {
                        self.skippedSamplesCount += buffer.frameLength // 累加当前帧的样本数
                        return
                    }

                    if elapsedTime > 60 { return }

                    self.processAndDisposeAudioBuffer(buffer)

                    let mic = self.calculateLevelPercentage(from: buffer)
                    self.delegate?.audioManager(
                        self,
                        didUpdateRecordingPower: mic,
                        duration: elapsedTime
                    )
                }
            audioEngine.prepare()
            try audioEngine.start()

            logger.debug("Trasmissione audio avviata.")
        } catch {
            debugPrint(error.localizedDescription)
            _ = self.stopRecording()
        }
    }

    func stopRecording() -> Data? {
        logger.debug("Arresto trasmissione audio...")

        guard let audioEngine = audioEngine, let inputNode = inputNode else { return nil }

        inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        self.inputNode = nil
        self.audioEngine = nil

        if oggWriter.writeFrame(nil, frameByteCount: 0),
           oggWriter.encodedDuration() > 0.2
        {
            return dataItem.data()
        }

        logger.debug("Trasmissione audio arrestata.")
        return nil
    }

    func playAudio(_ filePath: URL) async {
        // Ferma riproduzione precedente se in corso
        stopPlay()

        playbackAudioEngine = AVAudioEngine()
        playbackPlayerNode = AVAudioPlayerNode()

        guard let audioEngine = playbackAudioEngine,
              let playerNode = playbackPlayerNode
        else {
            logger.debug("ERROR: Inizializzazione playback")
            return
        }

        do {
            // Configura il formato audio usando la frequenza di campionamento nativa del sistema
            let audioFormat = playerNode.outputFormat(forBus: 0)
            guard let audioFile = try? AVAudioFile(forReading: filePath) else {
                return
            }
            print("sampleRate: ", audioFile.processingFormat.sampleRate)

            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate

            self.startTimer(total: duration)

            // Configura audio engine — inserisce l'Equalizer Pro in catena se presente.
            audioEngine.attach(playerNode)
            self.eqAttach(
                to: audioEngine,
                bands: await Defaults[.eqBands],
                globalGain: await Defaults[.globalGain]
            )

            if let eq = self.audioUnitEQ {
                audioEngine.connect(playerNode, to: eq, format: audioFormat)
                audioEngine.connect(eq, to: audioEngine.mainMixerNode, format: audioFormat)
            } else {
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
            }

            self.setVolume()
            try audioEngine.start()

            playerNode.play()

            _ = await playerNode.scheduleFile(
                audioFile,
                at: nil,
                completionCallbackType: .dataPlayedBack
            )
            
            logger.debug("Avviata riproduzione audio PCM: frames")

        } catch {
            logger.debug("ERROR: Riproduzione audio PCM")
            self.stopPlay()
        }
    }

    func stopPlay() {
        playbackPlayerNode?.stop()
        playbackAudioEngine?.stop()
        playbackAudioEngine = nil
        playbackPlayerNode = nil
        audioUnitEQ = nil

        self.stopTimer()
    }

    private func eqAttach(to engine: AVAudioEngine, bands: [EQBand], globalGain: Double) {
        let eq = AVAudioUnitEQ(numberOfBands:
            EqualizerPreset.bandFrequencies.count
        )
        self.audioUnitEQ = eq
        self.changeEQ(bands: bands, globalGain: Float(globalGain))
        engine.attach(eq)
    }

    func changeEQ(bands: [EQBand], globalGain: Float = 0) {
        guard let eq = audioUnitEQ else { return }
        eq.globalGain = globalGain
        for (index, frequency) in EqualizerPreset.bandFrequencies.enumerated() {
            let eqBands = eq.bands[index]
            eqBands.filterType = .parametric
            eqBands.frequency = frequency
            eqBands.bandwidth = 2.5
            eqBands.bypass = false
            eqBands.gain = bands[index].value
        }
    }

    private func processAndDisposeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let bufferData = conversionFloat32ToInt16Buffer(buffer) else { return }
        let buffer = bufferData.audioBufferList.pointee.mBuffers

        let sampleRate = 16000
        let frameDurationMs = 60
        let bytesPerSample = 2
        let encoderPacketSizeInBytes = sampleRate * frameDurationMs / 1000 * bytesPerSample

        let currentEncoderPacket = malloc(encoderPacketSizeInBytes)!
        defer { free(currentEncoderPacket) }

        var bufferOffset = 0

        while true {
            var currentEncoderPacketSize = 0

            while currentEncoderPacketSize < encoderPacketSizeInBytes {
                if recordedAudioData.count != 0 {
                    let takenBytes = min(
                        recordedAudioData.count,
                        encoderPacketSizeInBytes - currentEncoderPacketSize
                    )
                    if takenBytes != 0 {
                        recordedAudioData.withUnsafeBytes { rawBytes in
                            let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)

                            memcpy(
                                currentEncoderPacket.advanced(by: currentEncoderPacketSize),
                                bytes,
                                takenBytes
                            )
                        }
                        recordedAudioData.replaceSubrange(0..<takenBytes, with: Data())
                        currentEncoderPacketSize += takenBytes
                    }
                } else if bufferOffset < Int(buffer.mDataByteSize) {
                    let takenBytes = min(
                        Int(buffer.mDataByteSize) - bufferOffset,
                        encoderPacketSizeInBytes - currentEncoderPacketSize
                    )
                    if takenBytes != 0 {
                        memcpy(
                            currentEncoderPacket.advanced(by: currentEncoderPacketSize),
                            buffer.mData?.advanced(by: bufferOffset),
                            takenBytes
                        )

                        bufferOffset += takenBytes
                        currentEncoderPacketSize += takenBytes
                    }
                } else {
                    break
                }
            }

            if currentEncoderPacketSize < encoderPacketSizeInBytes {
                recordedAudioData.append(
                    currentEncoderPacket.assumingMemoryBound(to: UInt8.self),
                    count: currentEncoderPacketSize
                )
                break
            } else {
                oggWriter.writeFrame(
                    currentEncoderPacket.assumingMemoryBound(to: UInt8.self),
                    frameByteCount: UInt(currentEncoderPacketSize)
                )
            }
        }
    }

    private func conversionFloat32ToInt16Buffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: buffer.format.sampleRate,
            channels: buffer.format.channelCount,
            interleaved: true
        ) else {
            return nil
        }

        let frameLength = buffer.frameLength
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength)
        else {
            return nil
        }
        convertedBuffer.frameLength = frameLength

        // 获取输入 float32 样本指针
        guard let sourcePointer = buffer.floatChannelData?[0] else {
            return nil
        }

        // 获取目标 int16 样本指针
        guard let destinationPointer = convertedBuffer.int16ChannelData?[0] else {
            return nil
        }

        for index in 0..<Int(frameLength) {
            let floatSample = min(max(sourcePointer[index], -1.0), 1.0)
            destinationPointer[index] = Int16(clamping: Int(floatSample * 32767.0))
        }

        return convertedBuffer
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
        let meterLevel = normalizedAudioLevel(from: avgPower)

        return Double(meterLevel)
    }

    private func normalizedAudioLevel(from decibels: Float) -> Float {
        guard decibels.isFinite else {
            return 0
        }

        let minDb: Float = -80

        guard decibels > minDb else {
            return 0
        }

        let normalized = (decibels - minDb) / -minDb

        return pow(normalized, 1.5)
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

/// PTTChannelDelegate
/// 
/// 
final nonisolated class PTTChannelDelegate: NSObject,
    PTChannelManagerDelegate,
    PTChannelRestorationDelegate, @unchecked Sendable
{
    static let shared = PTTChannelDelegate()

    private override init() {}

    private let isRemotePushIncoming = OSAllocatedUnfairLock(initialState: false)
    @MainActor
    private var pttManager: PushTalkManager { PushTalkManager.shared }

    // MARK: - Join

    func channelManager(
        _ channelManager: PTChannelManager,
        didJoinChannel channelUUID: UUID,
        reason: PTChannelJoinReason
    ) {
        logger.debug("Joined channel: \(channelUUID)")
        Task {
            try await pttManager.joinConnect()
        }
    }

    // MARK: - Leave

    func channelManager(
        _ channelManager: PTChannelManager,
        didLeaveChannel channelUUID: UUID,
        reason: PTChannelLeaveReason
    ) {
        logger.debug("Left channel: \(channelUUID)")
        Task {
            await pttManager.levelConnect()
        }
    }

    // MARK: - Begin TX

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didBeginTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        let message: String

        switch source {
        case .unknown:
            message = "未知来源"

        case .userRequest:
            message = "用户发起"

        case .developerRequest:
            message = "应用发起"

        case .handsfreeButton:
            message = "耳机按钮发起"

        @unknown default:
            message = "未知来源"
        }

        logger.debug("🎤\(message): 开始发送 ")

        isRemotePushIncoming.withLock { $0 = false }
    }

    // MARK: - End TX

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didEndTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        logger.debug("🎤 停止发送")
    }

    // MARK: - Push Token

    func channelManager(
        _ channelManager: PTChannelManager,
        receivedEphemeralPushToken pushToken: Data
    ) {
        let token = pushToken.map {
            String(format: "%02x", $0)
        }.joined()

        Task {
            await Defaults[.pttToken] = token
        }

        logger.debug("PTT Token: \(token)")
    }

    // MARK: - Push

    func incomingPushResult(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any]
    ) -> PTPushResult {
        logger.debug("收到PTT Push: \(channelUUID)\(pushPayload)")

        isRemotePushIncoming.withLock { $0 = true }

        if let remote = pushPayload["remote"] as? String {
            Task {
                if let voice = await pttManager.saveVoice(remoteUrl: remote) {
                    await pttManager.send(.startPlay(voice))
                }
            }
        }

        return .activeRemoteParticipant(
            .init(
                name: String(localized: "未知"),
                image: "無,ff0000".avatarImage()
            )
        )
    }

    // MARK: - Audio Session

    func channelManager(
        _ channelManager: PTChannelManager,
        didActivate audioSession: AVAudioSession
    ) {
        logger.debug("🔊 AudioSession Activated")
        let remote = isRemotePushIncoming.withLock { $0 }
        if !remote {
            Task {
                await pttManager.send(.startRecord(false))
            }
        }
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        didDeactivate audioSession: AVAudioSession
    ) {
        logger.debug("🔇 AudioSession Deactivated")
        let remote = isRemotePushIncoming.withLock { $0 }
        if !remote {
            Task {
                await pttManager.send(.stopRecord(false))
            }
        }
    }

    // MARK: - Restoration

    func channelDescriptor(
        restoredChannelUUID channelUUID: UUID
    ) -> PTChannelDescriptor {
        Task {
            try await PushTalkManager.shared.joinConnect()
        }

        return PTChannelDescriptor(
            name: NCONFIG.AppName,
            image: "書".avatarImage()
        )
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        failedToJoinChannel channelUUID: UUID,
        error: any Error
    ) {
        debugPrint(error.localizedDescription)
        Toast.error(title: "系统资源被占用")
    }
}
