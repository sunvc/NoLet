
//  PTTMessage.swift
//  NoLet
//
//  Created by lynn on 2025/8/7.
//

import Foundation
import GRDB
import SwiftUI
import UIKit

struct PttMessageModel: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable,
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

extension PttMessageModel {
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

extension PttMessageModel {
    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "PttMessageModel", ifNotExists: true) { t in
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

extension View {
    var windowSize: CGSize {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return UIScreen.main.bounds.size
        }
        return windowScene.screen.bounds.size
    }

    var minSize: CGFloat {
        min(windowSize.width, windowSize.height)
    }

    var windowWidth: CGFloat {
        windowSize.width
    }

    var windowHeight: CGFloat {
        windowSize.height
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
