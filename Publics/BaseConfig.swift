//
//  BaseConfig.swift
//  pushback
//
//  Created by uuneo 2024/10/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers


let CONTAINER =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)

class BaseConfig {


    static let appSymbol = "NoLet"
    static let groupName = "group.pushback"
    static let icloudName = "iCloud.pushback"
    static let databaseName = "pushback.sqlite"

    static let signKey = "com.uuneo.pushback.xxxxxxxxxxxxxxxxxxxxxx"
#if DEBUG
    static let defaultServer = "https://dev.uuneo.com"
#else
    static let defaultServer = "https://wzs.app"
#endif

    static let docServer = "https://wiki.wzs.app"
    static let logoImage = docServer + "/_media/egglogo.png"
    static let ogImage = docServer + "/_media/og.png"
    static let delpoydoc = docServer + String(localized: "/#/deploy")
    static let privacyURL = docServer + String(localized: "/#/policy")
    static let tutorialURL = docServer + String(localized: "/#/tutorial")


    static let longSoundPrefix = "pb.sounds.30s"
    static let userAgreement = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

    static let appSource = "https://github.com/sunvc/NoLet"
    static let serverSource = "https://github.com/sunvc/NoLets"
    static let appStore = "https://apps.apple.com/app/id6615073345"
    
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "me.uuneo.Meoworld"
    }

    static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? Self.appSymbol
    }

    static var configPath: URL?{
        CONTAINER?.appendingPathComponent("Library/Preferences", isDirectory: true)
            .appendingPathComponent( BaseConfig.groupName + ".plist", conformingTo: .propertyList )
    }

    static var databasePath: URL?{
        CONTAINER?.appendingPathComponent(BaseConfig.databaseName)
    }

    static var testData:String{
        "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"typewriter\"}"
    }

    
    enum FolderType: String, CaseIterable{
        case voice
        case ptt
        case image
        case tem
        case sounds = "Library/Sounds"
        case caches = "Library/Caches"
        
        var name:String{  self.rawValue }
        
        var path: URL{  BaseConfig.getDir(self)! }
        
        func all(files: Bool = false) -> [URL] {
            if files {
                Self.allCases.reduce(into: [URL]()) { partialResult, data in
                    partialResult = partialResult + data.files()
                }
            } else {
                Self.allCases.compactMap {  $0.path }
            }
        }
        
        func files() -> [URL]{
            BaseConfig.files(in: self.path)
        }
    }
    
    
    // Get the directory to store images in the App Group
    class func getDir(_ name:FolderType) -> URL? {
        if name == .tem{
            return FileManager.default.temporaryDirectory
        }
        
        guard let containerURL = CONTAINER else { return nil }
        
        let voicesDirectory = containerURL.appendingPathComponent(name.rawValue)
        
        // If the directory doesn't exist, create it
        if !FileManager.default.fileExists(atPath: voicesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: voicesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NLog.error("Failed to create images directory: \(error.localizedDescription)")
                return nil
            }
        }
        return voicesDirectory
    }
    
    class func files(in folder: URL) -> [URL] {
        
        guard let containerURL = CONTAINER else { return [] }

        do {
            let items = try FileManager.default.contentsOfDirectory(at: containerURL,
                                                            includingPropertiesForKeys: [.isDirectoryKey],
                                                            options: [.skipsHiddenFiles])
            return items.filter {
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false
            }
        } catch {
            NLog.error(error.localizedDescription)
            return []
        }
        
    }
    
    static  func deviceInfoString() -> String {
        let deviceName = UIDevice.current.localizedModel
        let deviceModel = UIDevice.current.model
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        
        return "\(deviceName) (\(deviceModel)-\(systemName)-\(systemVersion))"
    }
    
    
    static func documentUrl(_ fileName: String, fileType: UTType = .image) -> URL?{
        do{
            let filePaeh =  try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return filePaeh.appendingPathComponent(fileName, conformingTo: fileType)
        }catch{
            NLog.error(error.localizedDescription)
            return nil
        }
        
    }
}


enum NoletError: Error{
    case basic(_ msg: String)
}
