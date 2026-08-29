//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptProcessor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/14 21:40.

import Defaults
import Foundation
import UserNotifications

final class ScriptProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        guard let name = userInfo.raw(.script, as: String.self) else {
            return bestAttemptContent
        }

        await ScriptManager.shared.processorHandler(name, args: [userInfo])

        return bestAttemptContent
    }

    static func ttsHandler(_ userInfo: [AnyHashable: Any]) async -> String? {
        guard userInfo.raw(.call, as: Bool.self) == nil,
              let call = userInfo.raw(.call, as: String.self),
              let path = NCONFIG.Path(.tem, "speak.mp3", contentType: .mp3),
              let soundPath = NCONFIG.SoundName.speak.path(call.sha256())
        else {
            logger.error("no tts")
            return nil
        }

        defer {
            try? FileManager.default.removeItem(at: path)
        }

        do {
            let (msg, data) = await ScriptManager.shared.speak(params: userInfo)

            if let data {
                try data.write(to: path)
                let output = try await AudioConversion().toCAFShort(
                    inputURL: path,
                    outputURL: soundPath,
                    maxSeconds: 30
                )
                return output.lastPathComponent
            }

            if !msg.isEmpty {
                logger.debug("\(msg)")
            }

            return nil
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
    }
}
