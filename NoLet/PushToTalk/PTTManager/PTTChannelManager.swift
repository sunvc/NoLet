//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PTTChannelDelegate.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/19 20:25.

import AVFoundation
import os
import PushToTalk
import SwiftUI

/// PTTChannelDelegate
///
///
final nonisolated class PTTChannelManager: NSObject,
    PTChannelManagerDelegate,
    PTChannelRestorationDelegate, Sendable
{
    static let shared = PTTChannelManager()

    private override init() {}

    private let isRemotePushIncoming = OSAllocatedUnfairLock(initialState: false)

    static let ChannelUUID = UUID(uuidString: "10000001-1001-1001-1001-100000000001")!
//    var channelManager: PTChannelManager?

    private let channelManagerLock = OSAllocatedUnfairLock<PTChannelManager?>(initialState: nil)

    var channelManager: PTChannelManager? {
        channelManagerLock.withLock { $0 }
    }

    func start() async throws {
        let channelManager = try await PTChannelManager.channelManager(
            delegate: self,
            restorationDelegate: self
        )

        channelManagerLock.withLock { value in
            value = channelManager
        }
    }

    func join() {
        self.channelManager?.requestJoinChannel(
            channelUUID: Self.ChannelUUID,
            descriptor: PTChannelDescriptor(
                name: NCONFIG.AppName,
                image: "書".avatarImage()
            )
        )
    }

    func leave() {
        self.channelManager?.leaveChannel(channelUUID: Self.ChannelUUID)
    }

    func setActiveRemoteParticipant(name: String? = nil, avatar: UIImage? = nil) {
        var user: PTParticipant? {
            if let name = name, let avatar = avatar {
                return PTParticipant(name: name, image: avatar)
            }
            return nil
        }

        self.channelManager?.setActiveRemoteParticipant(
            user,
            channelUUID: Self.ChannelUUID
        )
    }

    func setTransmissionMode() {
        self.channelManager?.setTransmissionMode(.fullDuplex, channelUUID: Self.ChannelUUID)
    }

    func setServerStatus(_ status: PTServiceStatus) {
        self.channelManager?.setServiceStatus(status, channelUUID: Self.ChannelUUID)
    }

    // MARK: - Join

    func channelManager(
        _ channelManager: PTChannelManager,
        didJoinChannel channelUUID: UUID,
        reason: PTChannelJoinReason
    ) {
        logger.debug("Joined channel: \(channelUUID)")
        Task {
            try await PTTManager.shared.joinConnect()
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
            await PTTManager.shared.levelConnect()
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

        Defaults[.pttToken] = token
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

        if let remote = pushPayload["url"] as? String {
            Task {
                if let voice = await PTTManager.shared.saveVoice(remoteUrl: remote) {
                    await PTTManager.shared.send(.startPlay(voice), remote: true)
                }else{
                    self.setActiveRemoteParticipant()
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
        Task {
            if !remote {
                await PTTManager.shared.send(.startRecord(false))
            } else {
                if case .interruptionEnded = await PTTManager.shared.state {
                    await PTTManager.shared.send(.resume)
                }
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
                await PTTManager.shared.send(.stopRecord(false))
            }
        }
    }

    // MARK: - Restoration

    func channelDescriptor(
        restoredChannelUUID channelUUID: UUID
    ) -> PTChannelDescriptor {
        Task {
            try await PTTManager.shared.joinConnect()
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
        logger.error("\(error.localizedDescription)")
        Toast.error(title: "系统资源被占用")
    }
}
