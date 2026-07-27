//
//  PTTManager.swift
//  NoLet
//
//  Created by lynn on 2025/8/24.
//

import AVFoundation
import Combine
import Foundation
import MapKit
import Opus
import os
import PushToTalk
import SwiftUI
import UIKit

final class PTTManager: NSObject, ObservableObject {
    static let shared = PTTManager()

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
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 31.2397,
            longitude: 121.4998
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.05,
            longitudeDelta: 0.05
        )
    )

    @Published var onlineUsers: [ChannelUser] = []

    private var activeSpeakerId: String?

    @Published var userMapInteracted: Bool = false

    private let recorder = PTTRecorderManager()
    private let player = PTTPlayerManager()
    private nonisolated let network = NetworkManager()
    private var observationTask: Task<Void, Never>?
    private var loopTask: Task<Void, Never>?
    private let presence = PTTPresenceStream()

    private override init() {
        super.init()

        Task { @MainActor in
            await self.player.setDelegate(self)
            self.recorder.delegate = self
        }

        startObservingUnreadCount()
        self.TaskHandler()
        self.setupNotifications()
        self.setupMemberNameCache()
        self.presence.delegate = self
    }

    deinit {
        observationTask?.cancel()
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

    /// CloudKit 昵称回填后触发 UI 刷新: `onlineUsers` 未变但 `displayName` 结果变了,
    /// 通过重新赋值 published 数组强制 SwiftUI/UIKit 层重绘 pin 标签
    private func setupMemberNameCache() {
        MemberNameCache.shared.onUpdate = { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                self.onlineUsers = self.onlineUsers
            }
        }

        Task { [weak self] in
            for await _ in Defaults.updates(.member) {
                guard let self else { break }
                await MainActor.run {
                    self.onlineUsers = self.onlineUsers
                }
            }
        }
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
            Task {
                await self.send(.interruptionBegan)
            }

        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let shouldResume = options.contains(.shouldResume)

            Task {
                await self.send(.interruptionEnded(shouldResume: shouldResume))
            }

        @unknown default:
            break
        }
    }

    private func TaskHandler() {
        self.loopTask = Task.detached(priority: .utility) { [weak self] in
            logger.info("🚀 后台常驻任务已在线程: \(Thread.current) 启动")
            while !Task.isCancelled {
                guard let self = self else { break }

                do {
                    if await self.powerState {
                        await LocManager.shared.requestLocation()
                        await self.sendPresenceHeartbeat()
                    }
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    logger.info("Task 休眠被中断，准备退出")
                    break
                }
            }

            logger.info("🛑 后台常驻任务已安全退出")
        }
    }

    func deleteAll() {
        Task.detached(priority: .userInitiated) {
            do {
                try await AudioMessageDBManager.shared.deleteAll()
            } catch {
                logger.error("AudioMessage deleteAll 失败: \(error)")
            }
            if let path = NCONFIG.getDir(.ptt) {
                try? FileManager.default.removeItem(at: path)
            }
        }
    }

    private func startObservingUnreadCount() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let stream = AudioMessageDBManager.shared.observeMessages() as AsyncStream? else {
                return
            }
            for await value in stream {
                guard let self = self else { break }
                await MainActor.run {
                    self.messages = value.recent
                    self.waitPlayList = value.unread
                }
            }
        }
    }

    func send(_ event: Event, remote: Bool = false) async {
        logger.info("STATE: \(self.state.log)")
        logger.info("EVENT: \(event.log)")

        switch (state, event) {

        case (.idle, .startPlay(let message)):
            if let message {
                beginPlay(message)
            } else {
                await self.playWaitList()
            }

        case (.idle, .startRecord(let activity)):
            await beginRecord(activity)

        case (.idle, .recordStarted):
            internalStopRecord(isCancel: true)


        case (.preparingPlay, .playStarted):
            if case .preparingPlay(let message) = state {
                state = .playing(message)
            }

        case (.preparingPlay, .stopPlay):
            state = .idle
            await internalStopPlay()

        case (.preparingPlay, .startRecord(let activity)):
            await internalStopPlay()
            await beginRecord(activity)


        case (.playing, .stopPlay):
            await internalStopPlay()
            state = .idle

        case (.playing, .playFinished):
            currentPlayFile = nil
            state = .idle
            await self.playWaitList()

        case (.playing, .startPlay(let message)):
            guard let message else { break }
            if message == self.currentPlayFile {
                await internalStopPlay()
                currentPlayFile = nil
                return
            }
            // FIXME: -  处理连续播放, 如果是远程, 忽略打断
            if !remote {
                await internalStopPlay()
                beginPlay(message)
            }

        case (.playing, .startRecord(let activity)):
            await internalStopPlay()
            currentPlayFile = nil
            await beginRecord(activity)


        case (.recording, .stopRecord(let cancel)):
            internalStopRecord(isCancel: cancel)
            state = .idle
            await self.playWaitList()

        case (.recording, .startPlay):
            logger.info("Ignore play while recording")


        case (.playing(let message), .interruptionBegan),
             (.preparingPlay(let message), .interruptionBegan):
            self.state = .interrupted(message)
            await self.internalStopPlay()

        case (.recording, .interruptionBegan):
            await self.send(.stopRecord(false))

        case (.interrupted(let message), .interruptionEnded(let shouldResume)):
            if shouldResume {
                self.state = .interruptionEnded(shouldResume, message)

                PTTChannelManager.shared.setActiveRemoteParticipant(
                    name: "恢复播放",
                    avatar: "字,FF9500".avatarImage()
                )
            } else {
                self.state = .idle
                await self.internalStopPlay()
            }

        case (.interruptionEnded(let resume, let message), .resume):
            if resume {
                beginPlay(message)
            } else {
                self.state = .idle
                await self.internalStopPlay()
            }

        case (.interrupted, .stopPlay):
            self.state = .idle
            await self.internalStopPlay()

        default:
            logger.info("Ignore-STATE: \(self.state.log)")
            logger.info("Ignore-EVENT: \(event.log)")
        }
    }

    func joinConnect() async throws {
        self.powerState = true
        self.serverStatus = .connecting

        PTTChannelManager.shared.setServerStatus(.connecting)
        if !hasPermission {
            recorder.requestAudioPermission()
        }
        recorder.setupAudio()

        await self.publicJoinConnect()

        self.presence.start(channel: Defaults[.pttChannel])

        PTTChannelManager.shared.setTransmissionMode()
        PTTChannelManager.shared
            .setServerStatus(Defaults[.pttChannel].users.count > 0 ? .ready : .unavailable)
    }

    func levelConnect() async {
        self.powerState = false
        self.serverStatus = .offline

        self.presence.stop()

        await self.publicLevelConnect(Defaults[.pttHisChannel])
        Defaults[.pttChannel].users = []
    }

    func publicLevelConnect(_ channels: [PTTChannel]) async {
        let result = await self.connect(channels: channels, join: false)

        var historyChannels = Defaults[.pttHisChannel]
        for item in channels {
            if let index = historyChannels.firstIndex(of: item) {
                historyChannels[index].active = false
                historyChannels[index].users = []
            }
        }
        Defaults[.pttHisChannel] = historyChannels

        self.onlineUsers = []
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
                historyChannels[index].users = []
            }
        }

        Defaults[.pttHisChannel] = historyChannels

        var currentChannel = Defaults[.pttChannel]
        let currentKey = "\(currentChannel.server.url)_\(currentChannel.hex())"

        if let matchedResult = resultMap[currentKey] {
            currentChannel.timestamp = .now
            currentChannel.users = matchedResult.users
            self.onlineUsers = matchedResult.users

            let userId = Defaults[.member].id

            if !self.onlineUsers.contains(where: { $0.id == userId }) {
                let selfUser = ChannelUser(
                    id: userId,
                    coordinate: LocManager.shared.location.coordinate,
                    active: false
                )
                self.onlineUsers.insert(selfUser, at: 0)
            }

            for user in self.onlineUsers where user.id != userId {
                MemberNameCache.shared.prefetch(id: user.id)
            }

            applyActiveSpeaker()

            Defaults[.pttChannel] = currentChannel
            self.serverStatus = .online
        } else {
            currentChannel.users = []
            Defaults[.pttChannel] = currentChannel
            if let firstRes = results.first,
               let matchedChannel = historyChannels.first(where: {
                   $0.hex() == firstRes.channel && $0.server.url == firstRes.host
               })
            {
                Defaults[.pttChannel] = matchedChannel
            }
            self.serverStatus = .failed
        }

        if self.powerState {
            self.presence.start(channel: Defaults[.pttChannel])
        }

        self.zoomToFitAllUsers(force: false)
    }

    @discardableResult
    func setStatus(
        message: AudioMessage,
        read: Bool? = nil,
        status: AudioMessage.Status? = nil
    ) -> Bool {
        guard read != nil || status != nil else { return false }
        Task.detached(priority: .userInitiated) {
            _ = await AudioMessageDBManager.shared.setStatus(
                id: message.id,
                read: read,
                status: status
            )
        }
        return true
    }

    func playWaitList(_ next: Bool = false) async {
        if next {
            self.state = .idle
            await self.internalStopPlay()
        }

        guard let message = waitPlayList.last else {
            await self.send(.stopPlay)
            PTTChannelManager.shared.setActiveRemoteParticipant()
            return
        }
        await self.send(.startPlay(message))
    }

    private func beginPlay(_ message: AudioMessage) {
        state = .preparingPlay(message)

        logger.info("Start Play:\(message.file)")

        currentPlayFile = message
        self.setStatus(message: message, read: true)

        Task {
            await send(.playStarted)
            if let currentUrl = message.filePath() {
                // FIXME: - 播放引擎偶发挂起或者播放失败, 延迟一下

                self.setMapUserStatus(message: message)
                try await Task.sleep(for: .milliseconds(100))
                await self.player.playAudio(currentUrl)
                self.setMapUserStatus(message: message, stop: true)
            }
            await send(.playFinished)
        }
    }

    // 设置谁在说话
    func setMapUserStatus(message: AudioMessage, stop: Bool = false) {
        activeSpeakerId = stop ? nil : message.from
        applyActiveSpeaker()
    }

    /// 标识当前说话的用户（自己 or 远程），stop 时清除
    private func setActiveSpeaker(userId: String, active: Bool) {
        activeSpeakerId = active ? userId : nil
        applyActiveSpeaker()
    }

    /// 将 activeSpeakerId 应用到 onlineUsers 列表
    /// - 录音时激活本机(name 空 → "本机"),播放远程音频时激活对应用户(name 空 → "未知")
    /// - 若 activeSpeakerId 不在 onlineUsers 里,动态插入一个占位条目,保证地图上有激活标记
    private func applyActiveSpeaker() {
        var users = onlineUsers

        for index in users.indices {
            users[index].active = false
        }

        guard let activeId = activeSpeakerId, !activeId.isEmpty else {
            self.onlineUsers = users
            return
        }

        let myId = Defaults[.member].id
        let isSelf = activeId == myId

        if let index = users.firstIndex(where: { $0.id == activeId }) {
            var existing = users[index]
            existing.active = true
            users[index] = existing
        } else {
            let coordinate: CLLocationCoordinate2D = isSelf
                ? LocManager.shared.location.coordinate
                : CLLocationCoordinate2D(latitude: 0, longitude: 0)
            users.insert(
                ChannelUser(id: activeId, coordinate: coordinate, active: true),
                at: 0
            )
            if !isSelf {
                MemberNameCache.shared.prefetch(id: activeId)
            }
        }

        self.onlineUsers = users
    }

    private func internalStopPlay() async {
        logger.info("Stop Play")
        await self.player.stopPlay()
        setActiveSpeaker(userId: "", active: false)

        if case .interrupted = state {
            PTTChannelManager.shared.setActiveRemoteParticipant()
        }

        if self.waitPlayList.isEmpty {
            PTTChannelManager.shared.setActiveRemoteParticipant()
        }
    }

    private func beginRecord(_ activity: Bool = true) async {
        state = .recording
        logger.info("Start Record")
        setActiveSpeaker(userId: Defaults[.member].id, active: true)
        recorder.startRecording(activity, pttMusicPlay: Defaults[.pttMusicPlay])
        await self.send(.recordStarted)
    }

    private func internalStopRecord(isCancel: Bool) {
        logger.info("Stop Record")
        setActiveSpeaker(userId: "", active: false)

        if let data = recorder.stopRecording(), !isCancel {
            if let file = self.saveVoice(data: data) {
                Task.detached(priority: .userInitiated) {
                    await self.sendVoice(message: file)
                }
                if !isCancel {
                    self.lastFile = file
                }
            }
        }
    }

    func saveVoice(data: Data) -> AudioMessage? {
        let id = Defaults[.member].id
        let channel = Defaults[.pttChannel]
        guard let filePath = channel.filePath(userID: id) else { return nil }

        do {
            try data.write(to: filePath)
            let voice = AudioMessage(
                channel: channel.hex(),
                from: id,
                file: filePath.lastPathComponent,
                read: true
            )
            Task.detached(priority: .userInitiated) {
                try? await AudioMessageDBManager.shared.save(voice)
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
            try await AudioMessageDBManager.shared.save(voice)
            return voice
        } catch {
            return nil
        }
    }

    func setDB(_ value: Float) async {
        await self.player.setVolume(value)
    }

    func changeEQ() async {
        await self.player.changeEQ(
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
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        )
        .map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map {
            $0 * $0
        }
        .reduce(0, +) / Float(buffer.frameLength))

        let avgPower = 20 * log10(rms)
        let meterLevel = scaledPower(power: avgPower)

        return Double(meterLevel)
    }

    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return 0.0
        }

        let minDb: Float = -80.0

        if power < minDb {
            return 0.0
        }

        if power >= 1.0 {
            return 1.0
        }

        return (abs(minDb) - abs(power)) / abs(minDb)
    }
}

extension PTTManager: CLLocationManagerDelegate {
    /// - Parameter force: `true` 时忽略用户交互标记强制 zoom(点击 logo/用户数触发);
    ///   `false` 时若用户手动动过地图则跳过,避免打断查看。用户显式 zoom 会清零交互标记。
    func zoomToFitAllUsers(force: Bool = true) {
        if !force, userMapInteracted { return }
        if force { userMapInteracted = false }

        var usersToShow = Defaults[.pttChannel].users

        let userId = Defaults[.member].id

        if !usersToShow.contains(where: { $0.id == userId }) {
            let selfUser = ChannelUser(
                id: userId,
                coordinate: LocManager.shared.location.coordinate,
                active: false
            )
            usersToShow.insert(selfUser, at: 0)
        }

        let validUsers = usersToShow.filter { user in
            user.latitude != 0.0 && user.longitude != 0.0
        }

        guard !validUsers.isEmpty else {
            let userCoordinate = LocManager.shared.location.coordinate
            withAnimation(.easeInOut(duration: 0.5)) {
                region = MKCoordinateRegion(
                    center: userCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            }
            return
        }

        let latitudes = validUsers.map(\.latitude)
        let longitudes = validUsers.map(\.longitude)

        guard
            let minLat = latitudes.min(),
            let maxLat = latitudes.max(),
            let minLng = longitudes.min(),
            let maxLng = longitudes.max()
        else {
            return
        }

        let latDelta = maxLat - minLat
        let lngDelta = maxLng - minLng

        var finalLatDelta: CLLocationDegrees
        var finalLngDelta: CLLocationDegrees

        if latDelta < 0.0005, lngDelta < 0.0005 {
            finalLatDelta = 0.0015
            finalLngDelta = 0.0015
        } else {
            finalLatDelta = max(latDelta * 1.5, 0.002)
            finalLngDelta = max(lngDelta * 1.5, 0.002)
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (minLat + maxLat) / 2,
                    longitude: (minLng + maxLng) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: finalLatDelta,
                    longitudeDelta: finalLngDelta
                )
            )
        }
    }
}

extension PTTManager {
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
        var latitude: Double
        var longitude: Double
        var token: String
        var host: String
    }

    nonisolated struct JoinResponse: Codable, Sendable {
        var host: String
        var channel: String
        var users: [ChannelUser]
    }

    private func _connect(
        channels: [PTTChannel],
        join: Bool
    ) async -> baseResponse<[JoinResponse]>? {
        guard let channel = channels.first, channel.serverOK else {
            return nil
        }

        do {
            let hzs = channels.map { $0.hex() }

            let signHeaders = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )

            let params = JoinParams(
                id: Defaults[.member].id,
                channels: hzs,
                latitude: LocManager.shared.location.coordinate.latitude,
                longitude: LocManager.shared.location.coordinate.longitude,
                token: join ? Defaults[.member].talk : "",
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
                throw NoletError(message: "Bad Request!")
            }
            return result
        } catch {
            logger.error("\(error)")
            Toast.info(title: "语音服务器错误")
            return nil
        }
    }

    /// 低频位置心跳。SSE 承载增量成员事件,但客户端自身的位置变化需要主动上报。
    /// 服务端收到后会 broadcast update 到订阅了这个频道的其它成员。
    func sendPresenceHeartbeat() async {
        let channel = Defaults[.pttChannel]
        guard channel.serverOK else { return }

        do {
            let params = JoinParams(
                id: Defaults[.member].id,
                channels: [channel.hex()],
                latitude: LocManager.shared.location.coordinate.latitude,
                longitude: LocManager.shared.location.coordinate.longitude,
                token: Defaults[.member].talk,
                host: channel.server.url
            )
            let headers = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )
            let _: baseResponse<Int>? = try await self.network.fetch(
                url: channel.server.url,
                path: "/ptt/presence",
                method: .POST,
                params: params,
                headers: headers,
                timeout: 5
            )
        } catch {
            logger.debug("presence heartbeat: \(error.localizedDescription)")
        }
    }

    func sendVoice(message: AudioMessage) async {
        self.setStatus(message: message, status: .send)

        let channel = Defaults[.pttChannel]

        guard channel.serverOK, let filePath = message.filePath() else {
            self.setStatus(message: message, status: .failed)
            return
        }

        do {
            var data = try Data(contentsOf: filePath)
            let pttSignature = Defaults[.pttSignature]
            if pttSignature {
                guard let encryptedData = CryptoModelConfig.data.encrypt(inputData: data) else {
                    throw NoletError(message: "encrypt error")
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

            self.setStatus(message: message, status: result.code == 200 ? .success : .failed)
        } catch {
            logger.error("\(error.localizedDescription)")
            Toast.error(title: "发送语音失败")
            self.setStatus(message: message, status: .failed)
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
            // FIXME: - 404存为了文件
            guard response.check() else { return nil }

            var data = response.data
            if decode {
                guard let decodeData = CryptoModelConfig.data.decrypt(inputData: data)
                else { throw NoletError(message: "decrypt error") }
                data = decodeData
            }

            return data
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }
}

extension PTTManager {
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

        case interruptionBegan
        case interruptionEnded(shouldResume: Bool)
        case resume

        var log: String {
            switch self {
            case .startPlay(let message):
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

extension PTTManager: PTTPlayerDelegate {
    nonisolated func playerManager(
        _ manager: PTTPlayerManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    ) {
        DispatchQueue.main.async {
            self.totalPlayTime = duration
            self.currentPlayTime = currentTime
        }
    }
}

extension PTTManager: PTTRecorderDelegate {
    func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    ) {
        DispatchQueue.main.async {
            self.micLevel = power
            self.elapsedTime = duration
        }
    }

    func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateMicrophonePermission hasPermission: Bool
    ) {
        DispatchQueue.main.async {
            self.hasPermission = hasPermission
        }
    }
}

// MARK: - PTTPresenceStreamDelegate

extension PTTManager: PTTPresenceStreamDelegate {
    nonisolated func presenceStream(
        _ stream: PTTPresenceStream,
        didChangeConnected connected: Bool
    ) {
        logger.debug("SSE connected=\(connected)")
        Task { @MainActor in
            self.serverStatus = connected ? .online : .offline
        }
    }

    nonisolated func presenceStream(
        _ stream: PTTPresenceStream,
        didReceive event: PresenceEvent
    ) {
        Task { @MainActor in
            self.apply(presenceEvent: event)
        }
    }

    /// 应用一条 SSE 事件到当前频道的 onlineUsers。跨频道事件直接忽略。
    @MainActor
    private func apply(presenceEvent event: PresenceEvent) {
        let currentChannel = Defaults[.pttChannel]
        guard event.channel == currentChannel.hex() else { return }

        let myId = Defaults[.member].id

        switch event.event {
        case .snapshot:
            let previousActiveId = self.onlineUsers.first(where: { $0.active })?.id
            var users: [ChannelUser] = (event.users ?? []).map { u in
                ChannelUser(
                    id: u.id,
                    coordinate: CLLocationCoordinate2D(
                        latitude: u.latitude,
                        longitude: u.longitude
                    ),
                    active: u.id == previousActiveId
                )
            }
            if !users.contains(where: { $0.id == myId }) {
                users.insert(
                    ChannelUser(
                        id: myId,
                        coordinate: LocManager.shared.location.coordinate,
                        active: previousActiveId == myId
                    ),
                    at: 0
                )
            }
            self.onlineUsers = users
            for u in users where u.id != myId {
                MemberNameCache.shared.prefetch(id: u.id)
            }
            var ch = currentChannel
            ch.users = users
            Defaults[.pttChannel] = ch

        case .join:
            guard let u = event.user, u.id != myId else { return }
            if let idx = self.onlineUsers.firstIndex(where: { $0.id == u.id }) {
                var existing = self.onlineUsers[idx]
                existing.update(coordinate: CLLocationCoordinate2D(
                    latitude: u.latitude, longitude: u.longitude))
                self.onlineUsers[idx] = existing
            } else {
                let newUser = ChannelUser(
                    id: u.id,
                    coordinate: CLLocationCoordinate2D(
                        latitude: u.latitude,
                        longitude: u.longitude
                    ),
                    active: false
                )
                self.onlineUsers.append(newUser)
                MemberNameCache.shared.prefetch(id: u.id)
            }

        case .leave:
            guard let u = event.user else { return }
            self.onlineUsers.removeAll { $0.id == u.id }

        case .update:
            guard let u = event.user else { return }
            guard let idx = self.onlineUsers.firstIndex(where: { $0.id == u.id }) else {
                return
            }
            var existing = self.onlineUsers[idx]
            existing.update(coordinate: CLLocationCoordinate2D(
                latitude: u.latitude, longitude: u.longitude))
            self.onlineUsers[idx] = existing

        case .ping:
            break
        }

        self.zoomToFitAllUsers(force: false)
    }
}

nonisolated extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
