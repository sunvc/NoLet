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
final nonisolated class PTTChannelDelegate: NSObject,
    PTChannelManagerDelegate,
    PTChannelRestorationDelegate, @unchecked Sendable
{
    static let shared = PTTChannelDelegate()

    private override init() {}

    private let isRemotePushIncoming = OSAllocatedUnfairLock(initialState: false)
    @MainActor
    private var pttManager: PTTManager { PTTManager.shared }

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

        if let remote = pushPayload["url"] as? String {
            Task {
                if let voice = await pttManager.saveVoice(remoteUrl: remote) {
                    await pttManager.send(.startPlay(voice), remote: true)
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
                await pttManager.send(.startRecord(false))
            } else {
                if case .interruptionEnded = await pttManager.state {
                    await self.pttManager.send(.resume)
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
                await pttManager.send(.stopRecord(false))
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
        debugPrint(error.localizedDescription)
        Toast.error(title: "系统资源被占用")
    }
}
