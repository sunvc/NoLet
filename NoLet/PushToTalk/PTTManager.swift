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

@MainActor
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
    private let network = NetworkManager()
    private var observationTask: Task<Void, Never>?
    private let presence = PTTPresenceStream()

    private var lastPresenceUpload: Date = .distantPast
    private var pendingPresenceUpload: Task<Void, Never>?
    private let presenceMinInterval: TimeInterval = 5

    private override init() {
        super.init()

        Task { @MainActor in
            await self.player.setDelegate(self)
            self.recorder.delegate = self
        }

        startObservingUnreadCount()
        self.setupNotifications()
        self.presence.delegate = self
 
    }

    deinit {
        observationTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }


    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationUpdated),
            name: .locationUpdated,
            object: nil
        )
    }

    @objc private func handleLocationUpdated() {
        Task { @MainActor in
            guard self.powerState else { return }
            self.scheduleJoinUpdate()
        }
    }

    private func scheduleJoinUpdate() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastPresenceUpload)
        if elapsed >= presenceMinInterval {
            lastPresenceUpload = now
            pendingPresenceUpload?.cancel()
            pendingPresenceUpload = nil
            Task { [weak self] in
                await self?.sendJoinUpdate()
            }
            return
        }
        if pendingPresenceUpload != nil { return }
        let delay = presenceMinInterval - elapsed
        pendingPresenceUpload = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self else { return }
            if Task.isCancelled { return }
            await MainActor.run {
                self.lastPresenceUpload = Date()
                self.pendingPresenceUpload = nil
            }
            await self.sendJoinUpdate()
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
            let stream = AudioMessageDBManager.shared.observeMessages()
            for await value in stream {
                guard let self = self else { break }
                await MainActor.run {
                    self.messages = value
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
                enqueuePlay(message)
            }
            beginNextIfIdle()

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
            beginNextIfIdle()

        case (.preparingPlay, .startRecord(let activity)):
            await internalStopPlay()
            await beginRecord(activity)

        case (.playing, .stopPlay):
            await internalStopPlay()
            state = .idle
            beginNextIfIdle()

        case (.playing, .playFinished):
            currentPlayFile = nil
            state = .idle
            beginNextIfIdle()

        case (.playing, .startPlay(let message)):
            guard let message else { break }
            if message == self.currentPlayFile {
                await internalStopPlay()
                currentPlayFile = nil
                state = .idle
                beginNextIfIdle()
                return
            }
            if remote {
                enqueuePlay(message)
            } else {
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
            beginNextIfIdle()

        case (.recording, .startPlay(let message)):
            if let message { enqueuePlay(message) }
            logger.info("Queue play while recording")

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
                    avatar: "伞,FF9500".avatarImage()
                )
            } else {
                self.state = .idle
                await self.internalStopPlay()
                beginNextIfIdle()
            }

        case (.interruptionEnded(let resume, let message), .resume):
            if resume {
                beginPlay(message)
            } else {
                self.state = .idle
                await self.internalStopPlay()
                beginNextIfIdle()
            }

        case (.interrupted, .stopPlay):
            self.state = .idle
            await self.internalStopPlay()
            beginNextIfIdle()

        default:
            logger.info("Ignore-STATE: \(self.state.log)")
            logger.info("Ignore-EVENT: \(event.log)")
        }
    }

    private func enqueuePlay(_ message: AudioMessage) {
        if waitPlayList.contains(where: { $0.id == message.id }) { return }
        waitPlayList.insert(message, at: 0)
    }

    private func beginNextIfIdle() {
        guard case .idle = state else { return }
        playNext()
    }

    private func playNext() {
        guard let message = waitPlayList.popLast() else {
            PTTChannelManager.shared.setActiveRemoteParticipant()
            return
        }
        if message == currentPlayFile {
            playNext()
            return
        }
        beginPlay(message)
    }

    func joinConnect() async throws {
        self.powerState = true
        self.serverStatus = .connecting(attempt: 0)

        PTTChannelManager.shared.setServerStatus(.connecting)
        if !hasPermission {
            recorder.requestAudioPermission()
        }
        recorder.setupAudio()

        await self.publicJoinConnect()

        self.presence.start(channel: Defaults[.pttChannel])

        PTTChannelManager.shared.setTransmissionMode()
        PTTChannelManager.shared.setServerStatus(.ready)
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
               // TODO: - 
            }

            applyActiveSpeaker()

            Defaults[.pttChannel] = currentChannel
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

    func setMapUserStatus(message: AudioMessage, stop: Bool = false) {
        activeSpeakerId = stop ? nil : message.from
        applyActiveSpeaker()
    }

    private func setActiveSpeaker(userId: String, active: Bool) {
        activeSpeakerId = active ? userId : nil
        applyActiveSpeaker()
    }

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
        }

        self.onlineUsers = users
    }

    private func internalStopPlay() async {
        logger.info("Stop Play")
        await self.player.stopPlay()
        setActiveSpeaker(userId: "", active: false)
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

    func incomingPushResult(channelManager: PTChannelManager, url: String?) async {
        if let voice = await self.saveVoice(remoteUrl: url) {
            await self.send(.startPlay(voice), remote: true)
        }

        if case .idle = self.state {
            PTTChannelManager.shared.setActiveRemoteParticipant()
        }
    }

    func saveVoice(remoteUrl: String?) async -> AudioMessage? {
        do {
            guard let remoteUrl,
                  let remoteFileUrl = URL(string: remoteUrl),
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

    func playTips(
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

    struct JoinParams: Codable, Sendable {
        var id: String
        var channels: [String]
        var latitude: Double
        var longitude: Double
        var token: String
        var host: String
    }

    struct JoinResponse: Codable, Sendable {
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

    func sendJoinUpdate() async {
        let channel = Defaults[.pttChannel]
        guard channel.serverOK else { return }

        do {
            let activeChannels = Defaults[.pttHisChannel].filter { $0.active }
            let channels = ([channel] + activeChannels).map { $0.hex() }
            let uniqueChannels = Array(Set(channels))

            let params = JoinParams(
                id: Defaults[.member].id,
                channels: uniqueChannels,
                latitude: LocManager.shared.location.coordinate.latitude,
                longitude: LocManager.shared.location.coordinate.longitude,
                token: Defaults[.member].talk,
                host: channel.server.url
            )
            let headers = CryptoManager.signature(
                sign: channel.server.sign,
                server: channel.server.key
            )
            let _: baseResponse<[JoinResponse]>? = try await self.network.fetch(
                url: channel.server.url,
                path: "/ptt/connect",
                method: .POST,
                params: params,
                headers: headers,
                timeout: 5
            )
        } catch {
            logger.debug("join update: \(error.localizedDescription)")
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

    enum ServerState: Equatable {
        case offline
        case connecting(attempt: Int)
        case online
        case failed

        var title: String {
            switch self {
            case .offline:
                return String(localized: "未启动监听")
            case .connecting(let attempt) where attempt > 0:
                return String(format: String(localized: "重连中(%d)"), attempt)
            case .connecting:
                return String(localized: "连接中...")
            case .online:
                return ""
            case .failed:
                return String(localized: "服务器未连接")
            }
        }
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
    nonisolated func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    ) {
        DispatchQueue.main.async {
            self.micLevel = power
            self.elapsedTime = duration
        }
    }

    nonisolated func recorderManager(
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
        didChangeConnected connected: Bool,
        attempt: Int
    ) {
        Task { @MainActor in
            if connected {
                self.serverStatus = .online
                if self.powerState {
                    await self.sendJoinUpdate()
                }
            } else {
                self.serverStatus = .connecting(attempt: attempt)
            }
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

    @MainActor
    private func apply(presenceEvent event: PresenceEvent) {
        let currentChannel = Defaults[.pttChannel]
        guard event.channel == currentChannel.hex() else { return }

        let myId = Defaults[.member].id
        var needsZoom = false

        switch event.event {
        case .snapshot:
            let previousActiveId = onlineUsers.first(where: { $0.active })?.id
            let existingById = Dictionary(uniqueKeysWithValues: onlineUsers.map { ($0.id, $0) })
            var users: [ChannelUser] = (event.users ?? []).map { u in
                var user = existingById[u.id] ?? ChannelUser(
                    id: u.id,
                    coordinate: CLLocationCoordinate2D(latitude: u.latitude, longitude: u.longitude)
                )
                user.latitude = u.latitude
                user.longitude = u.longitude
                user.active = u.id == previousActiveId
                return user
            }
            if !users.contains(where: { $0.id == myId }) {
                var selfUser = existingById[myId] ?? ChannelUser(
                    id: myId,
                    coordinate: LocManager.shared.location.coordinate
                )
                selfUser.latitude = LocManager.shared.location.coordinate.latitude
                selfUser.longitude = LocManager.shared.location.coordinate.latitude
                selfUser.active = previousActiveId == myId
                users.insert(selfUser, at: 0)
            }
            onlineUsers = users
           
            var ch = currentChannel
            ch.users = users
            Defaults[.pttChannel] = ch
            needsZoom = true

        case .join:
            guard let u = event.user, u.id != myId else { return }
            upsertUser(id: u.id, latitude: u.latitude, longitude: u.longitude)
            needsZoom = true

        case .leave:
            guard let u = event.user else { return }
            onlineUsers.removeAll { $0.id == u.id }
            needsZoom = true

        case .update:
            guard let u = event.user else { return }
            upsertUser(id: u.id, latitude: u.latitude, longitude: u.longitude)

        case .ping:
            break
        }

        if needsZoom {
            zoomToFitAllUsers(force: false)
        }
    }

    @MainActor
    private func upsertUser(id: String, latitude: Double, longitude: Double) {
        if let idx = onlineUsers.firstIndex(where: { $0.id == id }) {
            onlineUsers[idx].latitude = latitude
            onlineUsers[idx].longitude = longitude
        } else {
            onlineUsers.append(ChannelUser(
                id: id,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            ))
        }
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
