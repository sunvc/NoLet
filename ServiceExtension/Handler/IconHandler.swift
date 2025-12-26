//
//  IconHandler.swift
//  NotificationServiceExtension
//
//  History:
//    Created by Neo 2024/8/8.
//

import Defaults
import Foundation
import Intents
import UIKit
import UserNotifications

final class IconHandler: NotificationContentProcessor,Sendable {
    
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        guard let imageURL: String = userInfo.raw(.icon) else { return bestAttemptContent }

        var localPath = await ImageManager.downloadImage(imageURL)

        /// 获取icon 云图标
        if localPath == nil {
            let images = await CloudManager.shared.queryIcons(name: imageURL)

            if let image = images.first, let icon = PushIcon(from: image),
               let previewImage = icon.previewImage, let data = previewImage.pngData()
            {
                let days = await MainActor.run{ Defaults[.imageSaveDays].days }
                await ImageManager.storeImage(
                    data: data,
                    key: imageURL,
                    expiration: .days(days)
                )

                localPath = await ImageManager.downloadImage(imageURL)
            }
        }

        var imageData: Data? {
            if let localPath = localPath,
               let localImageData = NSData(contentsOfFile: localPath) as? Data
            {
                return localImageData
            } else {
                return imageURL.avatarImage()?.pngData()
            }
        }

        guard let imageData = imageData else { return bestAttemptContent }

        let avatar = INImage(imageData: imageData)
        var personNameComponents = PersonNameComponents()
        personNameComponents.nickname = bestAttemptContent.title

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
            content: bestAttemptContent.body,
            speakableGroupName: INSpeakableString(spokenPhrase: bestAttemptContent.subtitle),
            conversationIdentifier: bestAttemptContent.threadIdentifier,
            serviceName: nil,
            sender: senderPerson,
            attachments: nil
        )

        intent.setImage(avatar, forParameterNamed: \.speakableGroupName)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming

        do {
            try await interaction.donate()
            return try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
        } catch {
            return bestAttemptContent
        }
    }
}
