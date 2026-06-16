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
    case mhz
    case khz
    case call
}

struct PTTChannel: Identifiable, Equatable, Codable {
    var id: String { "\(channel)".toUUID() }
    var timestamp: Date = .now
    var mhz: Int = 98
    var khz: Int = 1
    var server: PushServerModel = .noServer

    var channel: Int { mhz * 1000 + khz }

    var serverOK: Bool { server != .noServer }

    var channelID: UUID {
        UUID(uuidString: id) ?? UUID()
    }

    static func == (lhs: PTTChannel, rhs: PTTChannel) -> Bool {
        return lhs.channel == rhs.channel
    }

    func fileName(userID: String) -> String {
        let bb = Int64(Date().timeIntervalSince1970 * 1000)

        return hex() + "-" + userID + "-" + String(bb, radix: 32) + ".ogg"
    }

    func filePath(userID: String) -> URL? {
        NCONFIG.getDir(.ptt)?.appendingPathComponent(fileName(userID: userID))
    }

    func hex() -> String { String(channel, radix: 32) }

    static func from(_ channel: String) -> (Int, Int)? {
        guard let channel = Int(channel, radix: 32) else { return nil }
        let mhz = channel / 1000
        let khz = channel % 1000
        return (mhz, khz)
    }

    static func decimal(_ channel: String) -> Self? {
        guard let channel = self.from(channel) else { return nil }
        return Self(mhz: channel.0, khz: channel.1)
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
