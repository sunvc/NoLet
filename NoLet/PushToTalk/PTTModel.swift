
//  PTTMessage.swift
//  NoLet
//
//  Created by lynn on 2025/8/7.
//

import Foundation
import GRDB
import SwiftUI
import UIKit

struct AudioMessage: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable,
    Equatable
{
    var id: String = UUID().uuidString
    var timestamp: Date = .now
    var channel: String
    var from: String
    var file: String
    var remote: String = ""
    var read: Bool = false
    var sign: Bool = false

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let channel = Column(CodingKeys.channel)
        static let from = Column(CodingKeys.from)
        static let file = Column(CodingKeys.file)
        static let remote = Column(CodingKeys.remote)
        static let read = Column(CodingKeys.read)
        static let sign = Column(CodingKeys.sign)
    }

    func filePath() -> URL? {
        NCONFIG.getDir(.ptt)?.appendingPathComponent(file)
    }
}

extension AudioMessage {
    init?(remote address: URL) {
        let fileName = address.deletingPathExtension().lastPathComponent
        let params = fileName.split(separator: "-").compactMap { String($0) }
        guard params.count == 4, let times = Int(params[3], radix: 32)
        else { return nil }

        self.timestamp = Date(timeIntervalSince1970: TimeInterval(times) / 1000)
        self.sign = params.first == "1"
        self.from = params[2]
        self.channel = params[1]
        self.remote = address.absoluteString
        self.file = params[1...].joined(separator: "-") + "." + address.pathExtension
    }
}

extension AudioMessage {
    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "AudioMessage", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .datetime).notNull()
                t.column("channel", .text).notNull()
                t.column("from", .text).notNull()
                t.column("file", .text).notNull() // URL存为字符串
                t.column("remote", .text).notNull() // URL存为字符串
                t.column("read", .boolean).notNull()
                t.column("sign", .boolean).notNull()
            }
        }
    }
}

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
        return UIImage(named: "logo2")
    }
}

extension Bool {
    static var ISPAD: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
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
    var id: String { "\(channel)".toUUID() }
    var timestamp: Date = .now
    var mhz: Int = 98
    var khz: Int = 100
    var server: PushServerModel = .noServer
    var users: Int = 0
    var active: Bool = false

    var channel: Int { mhz * 1000 + khz }

    var serverOK: Bool { server != .noServer }

    static func == (lhs: PTTChannel, rhs: PTTChannel) -> Bool {
        return lhs.channel == rhs.channel && lhs.server.url == rhs.server.url
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

    static let pttToken = Key<String>("pttToken", default: "")
    static let server = Key<String>("pttServer", default: "")
}

extension Font {
    static func numberStyle(size: CGFloat = 32, textStyle: Font.TextStyle? = nil) -> Self {
        custom("Digital-7 Mono", size: size)
    }
}

nonisolated struct EQBand: Identifiable, Codable, Equatable {
    var id: Int { index }
    var frequency: String
    var min: Float
    var max: Float
    var value: Float
    let index: Int
}

nonisolated extension EQBand: Defaults.Serializable {}

nonisolated enum EqualizerPreset: String, CaseIterable, Codable {
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

    // 1. 将 gains 改为返回可选型，明确表达 .custom 没有固定的 gains
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
        // 2. 使用 guard let 安全解包，优雅地避开了越界风险和硬编码判断
        guard let currentGains = self.gains else { return [] }

        // 3. 使用 zip 将频率和增益合并，天然防御两个数组长度不一致的问题
        return zip(Self.bandFrequencies, currentGains).enumerated().map { index, element in
            let (frequencyValue, gainValue) = element

            // 4. 优化频率字符转换，支持 2.4K 这种带小数的表现形式
            let frequencyStr: String
            if frequencyValue >= 1000 {
                let khz = frequencyValue / 1000
                // 如果能被 1 整除（如 4000 -> 4），就显示 4K；否则显示 2.4K
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

nonisolated extension EqualizerPreset: Defaults.Serializable {}

nonisolated extension Defaults.Keys {
    static let eqBands = Key<[EQBand]>("EQBands", default: EqualizerPreset.flat.bands)
    static let eqPreset = Key<EqualizerPreset>("EqualizerPreset", default: .flat)
    static let globalGain = Key<Double>("EqualizerGlobalGain", default: 0.0)
}

extension Int {
    func KHZ() -> String {
        formatted(.number.precision(.integerLength(3)))
    }
}


