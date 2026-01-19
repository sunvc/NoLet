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

import Foundation
import UIKit
import UniformTypeIdentifiers

nonisolated let CONTAINER = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: NCONFIG.groupName)!

typealias NURL = String

extension NURL {
    nonisolated var url: URL { URL(string: self)! }
}

nonisolated class NCONFIG {
    static let appSymbol = "NoLet"
    static let groupName = "group.pushback"
    static let icloudName = "iCloud.pushback"
    static let databaseName = "pushback.sqlite"
    static let longSoundPrefix = "pb.sounds.30s"

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
    static let soundsRemoteURL: NURL = "http://s3.wzs.app/cafs.zip"
    static let logoImage: NURL = "https://s3.wzs.app/avatar.png"
    static let ogImage: NURL = "https://s3.wzs.app/og.png"

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "me.uuneo.Meoworld"
    }

    static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? appSymbol
    }

    static var configPath: URL {
        CONTAINER.appendingPathComponent("Library/Preferences", isDirectory: true)
            .appendingPathComponent(NCONFIG.groupName + ".plist", conformingTo: .propertyList)
    }

    static var databasePath: URL {
        CONTAINER.appendingPathComponent(NCONFIG.databaseName)
    }

    static func offServer(_ from: String) -> Bool {  from.hasPrefix(server) }

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

        let dir = CONTAINER.appendingPathComponent(name.rawValue)

        // If the directory doesn't exist, create it
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
                at: CONTAINER,
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
}

enum NoletError: Error {
    case basic(_ msg: String)
}
