//
//  AttachmentProcessor.swift
//  NotificationServiceExtension
//
//  History:
//    Created by Neo 2024/8/8.
//

import Defaults
import Intents
import UIKit
import UniformTypeIdentifiers

final class AttachmentProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        if let location = userInfo.raw(.location, as: String.self),
           let localPath = await ImageManager.generateMapSnapshot(
               from: location,
               mapSize: CGSize(width: 500, height: 500)
           )
        {
            let attachment = try genAttachment(localPath: localPath)
            bestAttemptContent.attachments = [attachment]
        }

        if let imageURL = userInfo.raw(.image, as: String.self) {
            let ex = Defaults[.imageSaveDays]
            guard let localPath = await ImageManager.downloadImage(
                imageURL,
                expiration: ex.isPermanent ? .never : .seconds(ex.seconds)
            ) else { return bestAttemptContent }

            if let uiimage = UIImage(contentsOfFile: localPath) {
                if let saveAlbum = bestAttemptContent.userInfo.raw(.saveAlbum, as: Bool.self), saveAlbum {
                    UIImageWriteToSavedPhotosAlbum(uiimage, self, nil, nil)
                } else {
                    if Defaults[.autoSaveToAlbum] {
                        UIImageWriteToSavedPhotosAlbum(uiimage, self, nil, nil)
                    }
                }
            }

            let attachment = try genAttachment(localPath: localPath)

            bestAttemptContent.attachments = [attachment]
        }

        // 图标处理------------------------------------------------------------
        guard let icon = userInfo.raw(.icon, as: String.self) else { return bestAttemptContent }
        return await Self.applyAvatar(to: bestAttemptContent, pngURL: icon)
    }

    /// 用 INSendMessageIntent 给通知设置发送者头像；donate 成功后返回
    /// `updating(from:)` 产出的新 content，失败则原样返回。
    /// 原生附件流程与插件脚本（setAvatar）共用。
    static func applyAvatar(
        to content: UNMutableNotificationContent,
        pngURL: String
    ) async -> UNMutableNotificationContent {
        guard let imageData = await getPngData(pngURL: pngURL) else { return content }

        let avatar = INImage(imageData: imageData)
        var personNameComponents = PersonNameComponents()
        personNameComponents.nickname = content.title

        let senderPerson = INPerson(
            personHandle: INPersonHandle(value: "", type: .unknown),
            nameComponents: personNameComponents,
            displayName: personNameComponents.nickname,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: false,
            suggestionType: .none
        )
        let mePerson = INPerson(
            personHandle: INPersonHandle(value: "", type: .unknown),
            nameComponents: nil,
            displayName: nil,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: true,
            suggestionType: .none
        )

        let placeholderPerson = INPerson(
            personHandle: INPersonHandle(value: "", type: .unknown),
            nameComponents: personNameComponents,
            displayName: personNameComponents.nickname,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil
        )

        let intent = INSendMessageIntent(
            recipients: [mePerson, placeholderPerson],
            outgoingMessageType: .outgoingMessageText,
            content: content.body,
            speakableGroupName: INSpeakableString(spokenPhrase: content.subtitle),
            conversationIdentifier: content.threadIdentifier,
            serviceName: nil,
            sender: senderPerson,
            attachments: nil
        )

        intent.setImage(avatar, forParameterNamed: \.speakableGroupName)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming

        do {
            try await interaction.donate()
            return try content.updating(from: intent) as! UNMutableNotificationContent
        } catch {
            return content
        }
    }

    func genAttachment(localPath: String) throws -> UNNotificationAttachment {
        let copyDestURL = URL(fileURLWithPath: localPath).appendingPathExtension(".tmp")
        try? FileManager.default.copyItem(
            at: URL(fileURLWithPath: localPath),
            to: copyDestURL
        )
        return try UNNotificationAttachment(
            identifier: Params.image.name,
            url: copyDestURL,
            options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier]
        )
    }

    static func getPngData(pngURL: String) async -> Data? {
        if URL(remote: pngURL) != nil {
            if let localPath = await ImageManager.downloadImage(pngURL) {
                return NSData(contentsOfFile: localPath) as? Data
            }
            return nil
        }

        if let icon = try? await PushIcon.query(
            NSPredicate(format: "name == %@", pngURL),
            from: NCONFIG.publicCloudDatabase
        ).first,
            let previewImage = icon.previewImage,
            let data = previewImage.pngData()
        {
            let ex = Defaults[.imageSaveDays]
            await ImageManager.storeImage(
                data: data,
                key: pngURL,
                expiration: ex == .forever ? .never : .seconds(Defaults[.imageSaveDays].seconds)
            )

            return data
        } else {
            return pngURL.avatarImage()?.pngData()
        }
    }
}
