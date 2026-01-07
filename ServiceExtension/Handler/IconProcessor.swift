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

class IconProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        guard let imageURLSttr: String = userInfo.raw(.icon),
              let imageData = await getPngData(pngURL: imageURLSttr)
        else { return bestAttemptContent }

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

    func getPngData(pngURL: String) async -> Data? {
        if pngURL.hasHttp {
            if let localPath = await ImageManager.downloadImage(pngURL) {
                return NSData(contentsOfFile: localPath) as? Data
            }
            return nil
        }

        if let image = await CloudManager.shared.queryIcons(name: pngURL).first,
           let icon = PushIcon(from: image),
           let previewImage = icon.previewImage,
           let data = previewImage.pngData()
        {
            await ImageManager.storeImage(
                data: data,
                key: pngURL,
                expiration: .days(Defaults[.imageSaveDays].days)
            )

            return data
        } else {
            return pngURL.avatarImage()?.pngData()
        }
    }
}
