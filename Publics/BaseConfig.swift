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

import Foundation
import UIKit
import UniformTypeIdentifiers


let CONTAINER = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: NCONFIG.groupName)!

typealias NURL = String

extension NURL{
    var url:URL{  URL(string: self)! }
}

class NCONFIG {


    static let appSymbol       = "NoLet"
    static let groupName       = "group.pushback"
    static let icloudName      = "iCloud.pushback"
    static let databaseName    = "pushback.sqlite"
    static let longSoundPrefix = "pb.sounds.30s"

#if DEBUG
    static let server = "https://wzs.app"
#else
    static let server = "https://wzs.app"
#endif
    
    private static let wikiServer: NURL = "https://wiki.wzs.app"
  
    static let delpoydoc: NURL          = docServer + "deploy"
    static let privacyURL: NURL         = docServer + "policy"
    static let tutorialURL: NURL        = docServer + "tutorial"
    static let encryURL: NURL           = docServer + "encryption"
    static let pushHelp: NURL           = docServer + "tutorial"
    
    static var docServer: NURL {
        wikiServer + String(localized: "NoletLanguageLocalCode")
    }
    
    static let userAgreement: NURL   = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let appSource: NURL       = "https://github.com/sunvc/NoLet"
    static let serverSource: NURL    = "https://github.com/sunvc/NoLets"
    static let telegram: NURL        = "https://t.me/PushToMe"
    static let appStore: NURL        = "https://apps.apple.com/app/id6615073345"
    static let soundsUrl: NURL       = "http://s3.wzs.app/cafs.zip"
    static let logoImage: NURL       = "https://s3.wzs.app/avatar.png"
    static let ogImage: NURL         = "https://s3.wzs.app/og.png"
    
    
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "me.uuneo.Meoworld"
    }

    static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? Self.appSymbol
    }

    static var configPath: URL{
        CONTAINER.appendingPathComponent("Library/Preferences", isDirectory: true)
            .appendingPathComponent( NCONFIG.groupName + ".plist", conformingTo: .propertyList )
    }

    static var databasePath: URL{
        CONTAINER.appendingPathComponent(NCONFIG.databaseName)
    }

    static var testData:String{
        "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"typewriter\"}"
    }
    
    static var customUserAgent: String {
        let info = Bundle.main.infoDictionary
        
        let appName     = NCONFIG.appSymbol
        let appVersion  = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let buildNumber = info?["CFBundleVersion"] as? String ?? "0"
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
       
        let systemVer   = UIDevice.current.systemVersion
        let locale      = Locale.current
        let regionCode  = locale.region?.identifier ?? "CN"   // e.g. CN
        let language    = locale.language.languageCode?.identifier ?? "en" // e.g. zh
        
        return "\(appName)/\(appVersion) (Build \(buildNumber); \(deviceModel); iOS \(systemVer); \(regionCode)-\(language))"
    }

    
    enum FolderType: String, CaseIterable{
        case voice
        case ptt
        case image
        case tem
        case sounds = "Library/Sounds"
        case caches = "Library/Caches"
        
        var name:String{  self.rawValue }
        
        var path: URL{  NCONFIG.getDir(self)! }
        
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
            NCONFIG.files(in: self.path)
        }
    }
    
    // Get the directory to store images in the App Group
    class func getDir(_ name:FolderType) -> URL? {
        if name == .tem{
            return FileManager.default.temporaryDirectory
        }
        
        let voicesDirectory = CONTAINER.appendingPathComponent(name.rawValue)
        
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
        

        do {
            let items = try FileManager.default.contentsOfDirectory(at: CONTAINER,
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

