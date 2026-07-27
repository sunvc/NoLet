//
//  AttachmentProcessor.swift
//  NotificationServiceExtension
//
//  History:
//    Created by Neo 2024/8/8.
//

import Defaults
import UIKit
import UniformTypeIdentifiers

class AttachmentProcessor: NotificationContentProcessor {
    func processor(
        identifier _: String,
        content bestAttemptContent: UNMutableNotificationContent
    ) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo

        let days = await MainActor.run { Defaults[.imageSaveDays].days }

        if let location: String = userInfo.raw(.location),
           let localPath = await ImageManager.generateMapSnapshot(
               from: location,
               mapSize: CGSize(width: 500, height: 500)
           )
        {
            let attachment = try genAttachment(localPath: localPath)
            bestAttemptContent.attachments = [attachment]
        }

        if let imageURL: String = userInfo.raw(.image) {
            guard let localPath = await ImageManager.downloadImage(
                imageURL,
                expiration: .days(days)
            ) else { return bestAttemptContent }

            if let uiimage = UIImage(contentsOfFile: localPath),
               let sha256 = uiimage.pngData()?.sha256()
            {
                if let saveAlbum: String = bestAttemptContent.userInfo.raw(.saveAlbum) {
                    if saveAlbum == "1" {
                        UIImageWriteToSavedPhotosAlbum(uiimage, self, nil, nil)
                    }
                } else {
                    if Defaults[.autoSaveToAlbum],
                       Defaults[.imageSaves].first(where: { $0 == sha256 }) == nil
                    {
                        Defaults[.imageSaves].append(sha256)
                        UIImageWriteToSavedPhotosAlbum(uiimage, self, nil, nil)
                    }
                }
            }

            let attachment = try genAttachment(localPath: localPath)

            bestAttemptContent.attachments = [attachment]
        }

        return bestAttemptContent
    }

    func genAttachment(localPath: String) throws -> UNNotificationAttachment {
        let copyDestURL = URL(fileURLWithPath: localPath).appendingPathExtension(".tmp")
        try? FileManager.default.copyItem(
            at: URL(fileURLWithPath: localPath),
            to: copyDestURL
        )

        // MARK: - 此处提示按照下面修改


        return try UNNotificationAttachment(
            identifier: Params.image.name,
            url: copyDestURL,
            options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier]
        )
    }
}
