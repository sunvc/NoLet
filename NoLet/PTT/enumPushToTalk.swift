//
//  enum.swift
//  NoLet
//
//  Created by lynn on 2025/7/30.
//

import Defaults
import Foundation
import SwiftUI

enum TalkButtonType: String, CaseIterable {
    case prefix
    case suffix
    case call
}

struct PTTChannel: Identifiable, Equatable, Codable {
    var id: String { "\(prefix)-\(suffix)".toUUID() }
    var timestamp: Date = .now
    var prefix: Int = 50
    var suffix: Int = 1
    var server: PushServerModel = .noServer
    
    var serverOK: Bool{ server != .noServer }

    var channelID: UUID {
        UUID(uuidString: id) ?? UUID()
    }

    static func == (lhs: PTTChannel, rhs: PTTChannel) -> Bool {
        return lhs.prefix == rhs.prefix &&
            lhs.suffix == rhs.suffix
    }

    func fileName(userID: String) -> String {
        let bb = Int64(Date().timeIntervalSince1970 * 1000)

        return hex() + "-" + userID + "-" + String(bb, radix: 32) + ".ogg"
    }

    func filePath(userID: String) -> URL? {
        NCONFIG.getDir(.ptt)?.appendingPathComponent(fileName(userID: userID))
    }

    func hex() -> String {
        String(prefix, radix: 32) + "-" + String(suffix, radix: 32)
    }

    static func from(_ string: String) -> (Int, Int)? {
        let parts = string.split(separator: "-", maxSplits: 1)

        guard parts.count == 2,
              let prefix = Int(parts[0], radix: 32),
              let suffix = Int(parts[1], radix: 32)
        else {
            return nil
        }

        return (prefix, suffix)
    }

    static func decimal(hexString: String) -> Self? {
        let parts = hexString.lowercased().split(separator: "-")
        guard parts.count == 2,
              let prefix = Int(parts[0], radix: 32),
              let suffix = Int(parts[1], radix: 32) else { return nil }
        var data = Self()
        data.prefix = prefix
        data.suffix = suffix
        return data
    }
}

extension PTTChannel: @MainActor Defaults.Serializable {}

extension Defaults.Keys {
    static let pttChannel = Key<PTTChannel>("pushTalkInteger", default: PTTChannel())
    static let pttHisChannel = Key<[PTTChannel]>("pttHisChannels", default: [])
    static let pttVibration = Key<Bool>("pttVibration", default: true)
    static let pttMusicPlay = Key<Bool>("pttMusicPlay", default: true)

    static let pttSignature = Key<Bool>("pttSignature", default: false)
    static let pttVoiceVolume = Key<CGFloat>("pttVoiceVolume", default: 1)

    static let pttToken = Key<String>("pttToken", default: "")
    static let server = Key<String>("pttServer", default: "")
}

extension [PTTChannel] {
    mutating func set(_ data: PTTChannel) {
        guard data.server.id != "000000"else { return }

        var data = data
        if let index = self.firstIndex(of: data) {
            self[index].timestamp = .now
        } else {
            data.timestamp = .now
            self.insert(data, at: 0)
        }
    }
}
