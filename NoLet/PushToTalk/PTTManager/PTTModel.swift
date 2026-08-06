
//  PTTMessage.swift
//  NoLet
//
//  Created by lynn on 2025/8/7.
//

import Defaults
import Foundation
import SwiftUI
import UIKit
import CryptoKit

// AudioMessage is the Core Data entity AudioMessageEntity; see
// AudioMessageDBManager for its Status enum, filePath(), and remote-URL parser.

struct PttMessageRequest: Codable {
    var id: String
    var channel: String
    var key: String
}

struct PttPlayInfo: Codable {
    var id: UUID = .init()
    var name: String
    var image: String
    var file: URL

    var avatar: UIImage? {
        if !image.isEmpty {
            return UIImage(contentsOfFile: image)
        }
        return UIImage(named: "logo0")
    }
}


enum InterruptedType {
    case begin
    case end
    case resume
    case other
}

enum TipsSound: String {
    case pttconnect
    case pttnotifyend
    case cbegin
    case bottle
    case qrcode
    case share
    case toolSent
    case pull
    case refresh
    case tabSelection
}

enum TalkButtonType: String, CaseIterable {
    case mhz
    case khz
    case call
}

struct PTTChannel: Identifiable, Equatable, Codable {
    var id: String { "\(channel)\(server.url)".toUUID() }
    var timestamp: Date = .now
    var mhz: Int = 98
    var khz: Int = 100
    var server: PushServerModel = .noServer
    var users: [ChannelUser] = []
    var active: Bool = false

    var channel: Int { mhz * 1000 + khz }

    var serverOK: Bool { server != .noServer }

    static func == (lhs: PTTChannel, rhs: PTTChannel) -> Bool {
        return lhs.channel == rhs.channel && lhs.server.url == rhs.server.url
    }

    func fileName(userID: String) -> String {
        let bb = Int64(Date().timeIntervalSince1970 * 1000)
        return hex() + "-" + userID + "-" + String(bb, radix: 32) + ".opus"
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

extension PTTChannel: Defaults.Serializable {}

extension [PTTChannel] {
    mutating func set(_ channel: PTTChannel, active: Bool) {
        if let index = self.firstIndex(of: channel) {
            self[index].active = active
        } else {
            var channel = channel
            channel.active = active
            self.append(channel)
        }

        self.sort { $0.timestamp > $1.timestamp }
    }
}

extension Defaults.Keys {
    static let pttChannel = Key<PTTChannel>("pushTalkInteger", default: PTTChannel())
    static let pttHisChannel = Key<[PTTChannel]>("pttHisChannels", default: [])
    static let pttVibration = Key<Bool>("pttVibration", default: true)
    static let pttMusicPlay = Key<Bool>("pttMusicPlay", default: true)
    static let pttSignature = Key<Bool>("pttSignature", default: false)
    static let pttVoiceVolume = Key<CGFloat>("pttVoiceVolume", default: 1)
    static let pttBitrate = Key<Int>("pttBitrate", default: 32_000)
    static let server = Key<String>("pttServer", default: "")
}

enum PTTBitrate: Int, CaseIterable, Identifiable {
    case low = 16_000
    case standard = 24_000
    case normal = 32_000
    case high = 48_000
    case max = 64_000

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue / 1_000) kbps"
    }

    var subtitle: String {
        switch self {
        case .low:      return String(localized: "省流量,音质一般")
        case .standard: return String(localized: "轻度压缩,人声清晰")
        case .normal:   return String(localized: "默认,平衡")
        case .high:     return String(localized: "音质更好,包更大")
        case .max:      return String(localized: "最高音质,占用最大")
        }
    }
}

extension Font {
    static func numberStyle(size: CGFloat = 32, textStyle: Font.TextStyle? = nil) -> Self {
        custom("Digital-7 Mono", size: size)
    }
}

struct EQBand: Identifiable, Codable, Equatable {
    var id: Int { index }
    var frequency: String
    var min: Float
    var max: Float
    var value: Float
    let index: Int
}

extension EQBand: Defaults.Serializable {}

enum EqualizerPreset: String, CaseIterable, Codable {
    case flat
    case bass
    case vocal
    case rock
    case pop
    case custom

    static let bandFrequencies: [Float] = [60, 230, 910, 2400, 4000, 14000]
    static let minGain: Float = -12
    static let maxGain: Float = 12

    var displayName: String {
        switch self {
        case .flat: String(localized: "原声")
        case .bass: String(localized: "低音增强")
        case .vocal: String(localized: "人声增强")
        case .rock: String(localized: "摇滚")
        case .pop: String(localized: "流行")
        case .custom: String(localized: "自定义")
        }
    }

    var gains: [Float]? {
        switch self {
        case .flat: return [0, 0, 0, 0, 0, 0]
        case .bass: return [6, 4, 0, -1, -2, -3]
        case .vocal: return [-2, 0, 4, 5, 5, 2]
        case .rock: return [4, 2, -1, 1, 3, 5]
        case .pop: return [2, 4, 3, 2, 0, 2]
        case .custom: return nil
        }
    }

    var bands: [EQBand] {
        guard let currentGains = self.gains else { return [] }

        return zip(Self.bandFrequencies, currentGains).enumerated().map { index, element in
            let (frequencyValue, gainValue) = element

            let frequencyStr: String
            if frequencyValue >= 1000 {
                let khz = frequencyValue / 1000
                frequencyStr = khz
                    .truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(khz))K" : String(
                        format: "%.1fK",
                        khz
                    )
            } else {
                frequencyStr = String(Int(frequencyValue))
            }

            return EQBand(
                frequency: frequencyStr,
                min: Self.minGain,
                max: Self.maxGain,
                value: gainValue,
                index: index
            )
        }
    }

    var iconName: String {
        switch self {
        case .flat: return "slider.horizontal.3"
        case .bass: return "speaker.wave.3.fill"
        case .vocal: return "mic.fill"
        case .rock: return "guitars.fill"
        case .pop: return "music.note"
        case .custom: return "slider.vertical.3"
        }
    }
}

extension EqualizerPreset: Defaults.Serializable {}

extension Defaults.Keys {
    static let eqBands = Key<[EQBand]>("EQBands", default: EqualizerPreset.flat.bands)
    static let eqPreset = Key<EqualizerPreset>("EqualizerPreset", default: .flat)
    static let globalGain = Key<Double>("EqualizerGlobalGain", default: 0.0)
}

extension Int {
    func KHZ() -> String {
        formatted(.number.precision(.integerLength(3)))
    }
}

fileprivate extension String {
    
    
    /// 把当前字符串 MD5 后转为标准 UUID 格式
    func toUUID() -> String {
        guard let data = self.data(using: .utf8) else {
            return ""
        }
        let md5Digest = Insecure.MD5.hash(data: data)
        
        let md5Hex = md5Digest.map { String(format: "%02hhx", $0) }.joined()
        
        let start8 = md5Hex.prefix(8)
        let part2 = md5Hex.dropFirst(8).prefix(4)
        let part3 = md5Hex.dropFirst(12).prefix(4)
        let part4 = md5Hex.dropFirst(16).prefix(4)
        let last12 = md5Hex.dropFirst(20).prefix(12)
        
        return "\(start8)-\(part2)-\(part3)-\(part4)-\(last12)"
    }
}

