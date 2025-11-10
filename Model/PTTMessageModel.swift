
//  PTTMessage.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/8/7.
//

import Foundation
import UIKit
import GRDB


struct PttMessageModel: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Equatable{
    var id:String = UUID().uuidString
    var timestamp:Date = .now
    var channel:String
    var from:String
    var file:String
    var status: Status
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let channel = Column(CodingKeys.channel)
        static let from = Column(CodingKeys.from)
        static let file = Column(CodingKeys.file)
        static let status = Column(CodingKeys.status)
    }
    
    enum Status: Int, Codable{
        case sending
        case loading
        case success
        case unread
        case read
        case sendError
        case loadError
        case none
    }
    
    func filePath() -> URL?{
        NCONFIG.getDir(.ptt)?.appendingPathComponent(file)
    }
    
}


extension PttMessageModel{
    static func createInit(dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try db.create(table: "PttMessageModel", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("timestamp", .datetime).notNull()
                t.column("channel", .text).notNull()
                t.column("from", .text).notNull()
                t.column("file", .text).notNull() // URL存为字符串
                t.column("status", .integer).notNull()
            }
        }
    }
}


struct PttMessageRequest: Codable{
    var id: String
    var channel: String
    var key:String
}


struct PttPlayInfo: Codable{
    var id:UUID = UUID()
    var name: String
    var image: String
    var file: URL
    
    
    var avatar: UIImage?{
        if !image.isEmpty{
            return UIImage(contentsOfFile: image)
        }
        return UIImage(named: "logo2")
    }
}
