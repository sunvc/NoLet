//
//  enum.swift
//  pushme
//
//  Created by lynn on 2025/7/30.
//

import Foundation
import Defaults
import SwiftUI

enum TalkieState {
    case idle
    case ready
    case recording
    case playing
    
    
    var title:String{
        switch self {
        case .idle:
            String(localized: "空闲中")
        case .ready:
            String(localized: "等待硬件")
        case .recording:
            String(localized: "正在说话...")
        case .playing:
            String(localized: "正在播放...")
        }
    }
    
    var show:Bool{
        self == .playing || self == .recording
    }
    
}


enum TalkButtonType: String, CaseIterable{
    case prefix
    case suffix
    case call
    case password
}

struct PTTChannel:Identifiable,Equatable, Codable{
    var id:String = UUID().uuidString
    var timestamp:Date = .now
    var prefix:Int = 50
    var suffix:Int = 1
    var password:String = ""
    var server:PushServerModel? = nil
    var isActive:Bool = false
    
    static func ==(lhs: PTTChannel, rhs: PTTChannel) -> Bool {
        return lhs.prefix == rhs.prefix &&
        lhs.suffix == rhs.suffix &&
        lhs.password == rhs.password
    }
    
    func fileName(userID: String) -> String{
        let bb = Int64(Date().timeIntervalSince1970 * 1000)
        
        return  hex() + "-" + userID + "-" + String(bb, radix: 32) + ".ogg"
    }
    
    func filePath(userID: String) -> URL?{
        BaseConfig.getDir(.ptt)?.appendingPathComponent(fileName(userID: userID))
    }
    
    func hex() -> String{
        return (String(prefix, radix: 32) + "-" +
        String(suffix, radix: 32) + "-" +
        String( Int(password) ?? 0, radix: 32)).uppercased()
    }
    
    static func decimal(hexString: String) -> Self?{
        let parts = hexString.lowercased().split(separator: "-")
        guard parts.count == 3,
              let prefix = Int(parts[0], radix: 32),
              let suffix = Int(parts[1], radix: 32),
              let passwordInt = Int(parts[2], radix: 32) else { return nil }
        var data = Self()
        data.prefix = prefix
        data.suffix = suffix
        if passwordInt > 9999 {
            data.password = String(passwordInt)
        }
        return data
        
    }
}

extension PTTChannel: Defaults.Serializable{ }

extension Defaults.Keys{
    static let pttChannel = Key<PTTChannel>("pushTalkInteger", default: PTTChannel())
    static let pttHisChannel = Key<[PTTChannel]>("pttHisChannels", default: [])
    static let pttVibration = Key<Bool>("pttVibration", default: true)
    static let pttMusicPlay = Key<Bool>("pttMusicPlay", default: true)
    static let pttNoiseEngine = Key<Bool>("pttNoiseEngine", default: false)
    static let pttVoiceVolume = Key<CGFloat>("pttVoiceVolume", default: 0.5)
    
    static let pttToken = Key<String>("pttToken", default: "")
    static let server = Key<String>("pttServer", default: "")
}


extension [PTTChannel]{
    mutating func set(_ data: PTTChannel){
        var data = data
        if let index = self.firstIndex(of: data){
            self[index].timestamp = .now
        }else{
            data.id = UUID().uuidString
            data.timestamp = .now
            self.insert(data, at: 0)
        }
    }
    
    mutating func setActive(_ data: PTTChannel? = nil){
        for item in self{
            if let index = self.firstIndex(of: item){
                if item == data{
                    self[index].timestamp = .now
                    self[index].isActive = true
                }else{
                    self[index].isActive = false
                }
            }
        }
    }
    
    
}
