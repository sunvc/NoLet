//
//  BaseConfig.swift
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

typealias NURL = String

extension NURL {
    var url: URL { URL(string: self)! }
}

let logger = Logger(subsystem: "app.wzs.logger", category: "main")

class NCONFIG {
    static let appSymbol = "NoLet"
    static let groupName = "group.pushback"
    static let databaseName = "pushback.sqlite"
    static let longSoundPrefix = "pb.sounds.30s"
    static let notificationName = "app.wzs.newMessage"

    #if DEBUG
    static let server = "https://wzs.app"
    #else
    static let server = "https://wzs.app"
    #endif

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
        return UserDefaults(suiteName: NCONFIG.groupName)!
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
        NCONFIG.localContainer.appendingPathComponent("Library/Preferences", isDirectory: true)
            .appendingPathComponent(NCONFIG.groupName + ".plist", conformingTo: .propertyList)
    }

    static var databasePath: URL {
        NCONFIG.localContainer.appendingPathComponent(NCONFIG.databaseName, conformingTo: .database)
    }

    static func offServer(_ from: String) -> Bool { from.hasPrefix(server) }

    enum FolderType: String, CaseIterable {
        case ptt
        case image
        case tem
        case sounds = "Library/Sounds"
        case caches = "Library/Caches"

        var name: String { rawValue }

        var path: URL { NCONFIG.getDir(self)! }

        func all(files: Bool = false) -> [URL] {
            if files {
                Self.allCases.reduce(into: [URL]()) { partialResult, data in
                    partialResult = partialResult + data.files()
                }
            } else {
                Self.allCases.compactMap { $0.path }
            }
        }

        func files() -> [URL] {
            NCONFIG.files(in: path)
        }
    }

    // Get the directory to store images in the App Group
    class func getDir(_ name: FolderType) -> URL? {
        if name == .tem {
            return FileManager.default.temporaryDirectory
        }

        let dir = NCONFIG.localContainer.appendingPathComponent(name.rawValue)

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
        return dir
    }

    class func files(in _: URL) -> [URL] {
        do {
            let items = try FileManager.default.contentsOfDirectory(
                at: NCONFIG.localContainer,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            return items.filter {
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false
            }
        } catch {
            logger.error("\(error)")
            return []
        }
    }

    static func documentURL(_ fileName: String, fileType: UTType = .image) -> URL? {
        do {
            let filePaeh = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return filePaeh.appendingPathComponent(fileName, conformingTo: fileType)
        } catch {
            logger.error("\(error)")
            return nil
        }
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
}

public func NSLocalizedString(
    _ key: String,
    tableName: String? = nil,
    bundle: Bundle = Bundle.main,
    value: String = "",
    comment: String? = nil
) -> String {
    NSLocalizedString(
        key,
        tableName: tableName,
        bundle: bundle,
        value: value,
        comment: comment ?? ""
    )
}

struct NoletError: LocalizedError {
    let message: String?
    var errorDescription: String? { message }
}
