//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - PushServerModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 15:53.

import Foundation
import SwiftUI
import CloudKit


// MARK: - PushServerModel
nonisolated
struct PushServerModel: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var url: String
    var key: String = ""
    var group: String? = nil
    var status: Bool = false
    var createDate: Date = .now
    var updateDate: Date = .now
    var sign: String? = nil

    init(
        url: String,
        key: String = "",
        group: String? = nil,
        status: Bool = false,
        createDate: Date = .now,
        updateDate: Date = .now,
        sign: String? = nil
    ) {
        self.url = url
        self.key = key
        self.group = group
        self.status = status
        self.createDate = createDate
        self.updateDate = updateDate
        self.sign = sign
    }
    
    static let space = PushServerModel(url: String(localized: "无"))
    
    var name: String {
        var name = url
        if let range = url.range(of: "://") {
            name.removeSubrange(url.startIndex..<range.upperBound)
        }
        return name
    }
    
    var color: Color { status ? .green : .orange }

    var server: String { url + "/" + key }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url && lhs.key == rhs.key
    }
}


nonisolated
extension PushServerModel: Hashable{
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(key)
    }
    
    
    func toCKRecord(recordType: String) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["url"] = url as CKRecordValue
        record["key"] = key as CKRecordValue
        record["group"] = group as? CKRecordValue
        record["sign"] = sign as? CKRecordValue
        return record
    }
    
    init?(from record: CKRecord) {
        self.id = record.recordID.recordName
        guard let url = record["url"] as? String,
              let key = record["key"] as? String else { return nil }
        self.url = url
        self.key = key
        self.group = record["group"] as? String
        self.sign = record["sign"] as? String
        self.createDate = record.creationDate ?? .now
        self.updateDate = record.modificationDate ?? .now
        self.status = false
    }
    
}
