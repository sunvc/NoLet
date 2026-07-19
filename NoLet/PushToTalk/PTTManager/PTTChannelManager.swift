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
import Defaults
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
        Task{@MainActor in
            LocManager.shared.runMonitoringSignificantLocationChanges(start: true)
        }
       
    }

    func leave() {
        self.channelManager?.leaveChannel(channelUUID: Self.ChannelUUID)
        Task{@MainActor in
            LocManager.shared.runMonitoringSignificantLocationChanges(start: false)
        }
    }



    func setActiveRemoteParticipant(name: String? = nil, avatar: UIImage? = nil) {
        let user: PTParticipant?
        if let name = name {
            user = PTParticipant(name: name, image: avatar ?? "無,ff0000".avatarImage())
        } else {
            user = nil
        }

        self.channelManager?.setActiveRemoteParticipant(
            user,
            channelUUID: Self.ChannelUUID
        )
    }

    func setTransmissionMode() {
        self.channelManager?.setTransmissionMode(.fullDuplex, channelUUID: Self.ChannelUUID)
        logger.debug("setTransmissionMode fullDuplex")
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
        let origin: PTTRecordingOrigin
        switch source {
        case .userRequest: origin = .user
        case .developerRequest: origin = .developer
        case .handsfreeButton: origin = .handsfree
        case .unknown: origin = .unknown
        @unknown default: origin = .unknown
        }
        Task { @MainActor in
            PTTManager.shared.sendAudio(.transmitBegan(origin: origin))
        }
    }

    // MARK: - End TX

    func channelManager(
        _ channelManager: PTChannelManager,
        channelUUID: UUID,
        didEndTransmittingFrom source: PTChannelTransmitRequestSource
    ) {
        logger.debug("🎤 停止发送")
        let origin: PTTRecordingOrigin
        switch source {
        case .userRequest: origin = .user
        case .developerRequest: origin = .developer
        case .handsfreeButton: origin = .handsfree
        case .unknown: origin = .unknown
        @unknown default: origin = .unknown
        }
        Task { @MainActor in
            PTTManager.shared.sendAudio(.transmitEnded(origin: origin))
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

        Defaults[.token].talk = token
        logger.debug("PTT Token: \(token)")
    }

    // MARK: - Push

    func incomingPushResult(
        channelManager: PTChannelManager,
        channelUUID: UUID,
        pushPayload: [String: Any]
    ) -> PTPushResult {
        logger.debug("收到PTT Push: \(channelUUID)\(pushPayload)")

        // Push only supplies wake-up metadata. The unified FSM decides when
        // the receiver may connect/queue/play it.
        if let sessionID = pushPayload["session_id"] as? String,
           let channel = pushPayload["channel"] as? String,
           let host = pushPayload["host"] as? String,
           !sessionID.isEmpty, !channel.isEmpty, !host.isEmpty
        {
            let from = pushPayload["from"] as? String ?? ""
            let fromName = pushPayload["from_name"] as? String
                ?? (pushPayload["name"] as? String ?? "")
            let metadata = PTTRemotePushMetadata(
                host: host,
                channel: channel,
                sessionID: sessionID,
                speakerID: from,
                speakerName: fromName
            )
            Task { @MainActor in
                PTTManager.shared.sendAudio(.remotePushReceived(metadata))
            }
        }

        var name: String{
            if let name = pushPayload["name"] as? String, name.count > 0{
                return name
            }
            if let fromName = pushPayload["from_name"] as? String, fromName.count > 0 {
                return fromName
            }
            return String(localized: "未知")
        }

        // Return .activeRemoteParticipant so PushToTalk framework shows
        // the caller name in the system UI AND activates the audio session.
        // Without this the framework treats the push as a silent wake-up and
        // never calls didActivate.
        return .activeRemoteParticipant(
            .init(
                name: name,
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
        Task { @MainActor in
            PTTManager.shared.sendAudio(.audioSessionActivated)
        }
    }

    func channelManager(
        _ channelManager: PTChannelManager,
        didDeactivate audioSession: AVAudioSession
    ) {
        logger.debug("🔇 AudioSession Deactivated")
        Task { @MainActor in
            PTTManager.shared.sendAudio(.audioSessionDeactivated)
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
