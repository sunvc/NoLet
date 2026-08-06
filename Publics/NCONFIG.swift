//
//  NCONFIG.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/25.
//

import CloudKit
import Foundation
import OSLog
import UIKit
import UniformTypeIdentifiers

enum NCONFIG {
    typealias NURL = String
    private static let logger = Logger(subsystem: "app.wzs.logger", category: "NCONFIG")
    static let appSymbol = "NoLet"
    static let groupName = "group.pushback"
    static let databaseName = "pushback.sqlite"

    static let notificationName = "app.wzs.newMessage"
    static let server: NURL = "https://wzs.app"
    static let userAgreement: NURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let appSource: NURL = "https://github.com/sunvc/NoLet"
    static let serverSource: NURL = "https://github.com/sunvc/NoLets"
    static let telegram: NURL = "https://t.me/PushToMe"
    static let appStore: NURL = "https://apps.apple.com/app/id6615073345"
    static let soundsRemoteURL: NURL = "http://s3.wzs.app/sounds.aar"
    static let logoImage: NURL = "https://s3.wzs.app/avatar.png"
    static let ogImage: NURL = "https://s3.wzs.app/og.png"

    static let container = CKContainer(identifier: "iCloud.pushback")

    static var privateCloudDatabase: CKDatabase {
        container.privateCloudDatabase
    }

    static var publicCloudDatabase: CKDatabase {
        container.publicCloudDatabase
    }

    static let localContainer = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: NCONFIG.groupName)!

    static func defaultStore() -> UserDefaults {
        guard let manager = UserDefaults(suiteName: NCONFIG.groupName) else {
            fatalError("")
        }
        return manager
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "me.uuneo.Meoworld"
    }

    static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? appSymbol
    }

    static var configPath: URL {
        NCONFIG.localContainer.appendingPathComponent(
            FolderType.preferences.name,
            isDirectory: true
        )
        .appendingPathComponent(NCONFIG.groupName + ".plist", conformingTo: .propertyList)
    }

    static var databasePath: URL {
        NCONFIG.localContainer.appendingPathComponent(NCONFIG.databaseName, conformingTo: .database)
    }

    static func offServer(_ from: String) -> Bool { from.hasPrefix(server) }

    enum FolderType: String, CaseIterable {
        case tem
        case document
        case library
        case ptt
        case sounds
        case caches
        case scripts
        case preferences

        var name: String {
            if self == .tem || self == .document || self == .library {
                return self.capitalizedFirst
            }
            return Self.library.capitalizedFirst + "/" + self.capitalizedFirst
        }

        var capitalizedFirst: String {
            guard let first = rawValue.first else { return rawValue }
            return first.uppercased() + rawValue.dropFirst()
        }
    }

    static func soundPath(pre: String? = nil, name: String) -> URL? {
        if let pre {
            return Path(.sounds, "\(pre)\(name)")
        }
        return Path(.sounds, name)
    }

    // Get the directory to store images in the App Group
    static func Path(
        _ path: FolderType,
        _ name: String? = nil,
        contentType: UTType? = nil
    ) -> URL? {
        if path == .tem {
            let path = FileManager.default.temporaryDirectory
            if let name {
                if let contentType {
                    return path.appendingPathComponent(name, conformingTo: contentType)
                } else {
                    return path.appendingPathComponent(name)
                }
            }
            return path
        }

        if path == .document {
            do {
                let filePath = try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )

                if let name {
                    if let contentType {
                        return filePath.appendingPathComponent(name, conformingTo: contentType)
                    } else {
                        return filePath.appendingPathComponent(name)
                    }
                }
                return filePath

            } catch {
                return nil
            }
        }

        var dir = NCONFIG.localContainer.appendingPathComponent(path.name)

        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                logger.error("Failed to create images directory: \(error)")
                return nil
            }
        }

        if let name, !name.isEmpty {
            if let contentType {
                dir = dir.appendingPathComponent(name, conformingTo: contentType)
            } else {
                dir = dir.appendingPathComponent(name)
            }
        }

        return dir
    }

    static func checkAccount() async -> (Bool, String) {
        var message = (false, String(localized: "未知 iCloud 状态"))
        do {
            let status = try await container.accountStatus()

            switch status {
            case .available:
                message = (true, String(localized: "iCloud 账户可用"))
            case .couldNotDetermine:
                message = (false, String(localized: "无法确定 iCloud 账户状态，可能是网络问题"))
            case .restricted:
                message = (false, String(localized: "iCloud 访问受限，可能由家长控制或 MDM 设备管理策略导致"))
            case .noAccount:
                message = (false, String(localized: "未登录 iCloud，请登录 iCloud 账户"))
            case .temporarilyUnavailable:
                message = (false, String(localized: "iCloud 服务暂时不可用，请稍后再试"))
            @unknown default:
                message = (false, String(localized: "未知 iCloud 状态"))
            }
            logger.info("\(message.0),\(message.1)")
        } catch {
            message = (false, String(localized: "检查 iCloud 账户状态出错"))
            logger.error("\(error) - \(message.1)")
        }

        return message
    }

    static func copy(_ message: String? = nil, _ items: [String: Any]...) {
        var result: [[String: Any]] = []

        if let message { result.append([UTType.utf8PlainText.identifier: message]) }

        UIPasteboard.general.items = result + items
    }

    static func text() -> String? { UIPasteboard.general.string }

    static func attributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()

        for item in UIPasteboard.general.items {
            for (type, value) in item {
                if type == "public.rtf", let data = value as? Data {
                    if let attrStr = try? NSAttributedString(data: data, options: [
                        .documentType: NSAttributedString.DocumentType.rtf,
                    ], documentAttributes: nil) {
                        result.append(attrStr)
                    }
                } else if type == "public.html", let htmlString = value as? String {
                    if let data = htmlString.data(using: .utf8),
                       let attrStr = try? NSAttributedString(data: data, options: [
                           .documentType: NSAttributedString.DocumentType.html,
                           .characterEncoding: String.Encoding.utf8.rawValue,
                       ], documentAttributes: nil)
                    {
                        result.append(attrStr)
                    }
                } else if type.hasPrefix("public.image"), let image = value as? UIImage {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    let imageAttrStr = NSAttributedString(attachment: attachment)
                    result.append(imageAttrStr)
                } else if type == "public.utf8-plain-text", let text = value as? String {
                    let textAttrStr = NSAttributedString(string: text)
                    result.append(textAttrStr)
                }
            }
        }

        return result
    }

    enum SoundName: String {
        case long = "pb.sounds.30s"
        case speak = "pd.sounds.speak"

        static let ext = "caf"

        func name(_ name: String) -> String {
            [rawValue, name.deletingPathExtension, Self.ext].joined(separator: ".")
        }

        func path(_ name: String) -> URL? {
            return Path(.sounds, self.name(name))
        }

        static func check(_ name: String) -> URL? {
            let name = [name.deletingPathExtension, ext].joined(separator: ".")
            
            if let path = Path(.sounds, name), FileManager.default.fileExists(atPath: path.path())  {
                return path
            } 
            
            if let path = Bundle.main.path(
                forResource: name.deletingPathExtension,
                ofType: Self.ext
            ),FileManager.default.fileExists(atPath: path) {
                return URL(filePath: path)
            }
            return nil
        }
    }
}

extension NCONFIG.NURL {
    var url: URL { URL(string: self)! }
}

struct NoletError: LocalizedError {
    let message: String?
    var errorDescription: String? { message }

    init(_ message: String?) {
        self.message = message
    }
}
