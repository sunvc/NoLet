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
@preconcurrency import CoreLocation
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

    private let remotePlay = OSAllocatedUnfairLock(initialState: false)
    private let localRecord = OSAllocatedUnfairLock(initialState: false)

    static let ChannelUUID = UUID(uuidString: "10000001-1001-1001-1001-100000000001")!

    private let channelManagerLock = OSAllocatedUnfairLock<PTChannelManager?>(initialState: nil)

    var channelManager: PTChannelManager? {
        channelManagerLock.withLock { $0 }
    }

    func start() async throws {
        let channelManager = try await PTChannelManager.channelManager(
            delegate: self,
            restorationDelegate: self
        )
        channelManagerLock.withLock { $0 = channelManager }
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
        logger.debug("开始录音: ")
        localRecord.withLock { $0 = true }
    }

    // MARK: - End TX

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didEndTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        logger.debug("🎤 停止发送")
        Task {
            await PTTManager.shared.send(.stopRecord(false))
        }
    }

    // MARK: - Push Token

    func channelManager(
        _ channelManager: PTChannelManager,
        receivedEphemeralPushToken pushToken: Data
    ) {
        let token = pushToken.map {
            String(format: "%02x", $0)
        }.joined()

        Defaults[.member].talk = token
        logger.debug("PTT Token: \(token)")
    }

    // MARK: - Push

    func incomingPushResult(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any]
    ) -> PTPushResult {
        logger.debug("收到PTT Push: \(pushPayload)")

        remotePlay.withLock { $0 = true }

        let remote = pushPayload["url"] as? String
        Task.detached {
            await PTTManager.shared.incomingPushResult(channelManager: channelManager, url: remote)
        }

        var name: String {
            if let name = pushPayload["name"] as? String, !name.isEmpty {
                return name
            }
            return String(localized: "未知")
        }

        return .activeRemoteParticipant(
            .init(
                name: name,
                image: "\(name.first ?? "伞"),ff0000".avatarImage()
            )
        )
    }

    // MARK: - Audio Session

    func channelManager(
        _ channelManager: PTChannelManager,
        didActivate audioSession: AVAudioSession
    ) {
        logger.debug("🔊 AudioSession Activated")
        Task {
            if localRecord.withLock({ $0 }) {
                await PTTManager.shared.send(.startRecord(false))
            } else if !remotePlay.withLock({ $0 }) {
                await PTTManager.shared.send(.startPlay(nil))
            }
        }
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        didDeactivate audioSession: AVAudioSession
    ) {
        logger.debug("🔇 AudioSession Deactivated")
        remotePlay.withLock { $0 = false }
        localRecord.withLock { $0 = false }
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
            image: "伞".avatarImage()
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
