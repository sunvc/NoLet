//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ApnsInfo.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 16:50.

import CloudKit
import Foundation

struct ApnsInfo: Codable {
    var id: String
    var timestamp: Date
    var token: String
    var teamID: String
    var keyID: String
    var topic: String
    var pem: String

    init(
        id: String,
        timestamp: Date,
        token: String,
        teamID: String,
        keyID: String,
        topic: String,
        pem: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.token = token
        self.teamID = teamID
        self.keyID = keyID
        self.topic = topic
        self.pem = pem
    }

    init?(record: CKRecord) {
        // 如果 recordName 对应 id，就直接用
        id = record.recordID.recordName

        guard
            let teamID = record["teamID"] as? String,
            let keyID = record["keyID"] as? String,
            let topic = record["topic"] as? String,
            let pem = record["pem"] as? String
        else {
            return nil
        }

        timestamp = record["timestamp"] as? Date ?? Date.distantFuture

        token = record["token"] as? String ?? ""

        self.teamID = teamID
        self.keyID = keyID
        self.topic = topic
        self.pem = pem
    }

    // MARK: - 初始化 CKRecord

    func toCKRecord(type recordType: String) -> CKRecord {
        // 使用 id 作为 recordName
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["timestamp"] = timestamp as CKRecordValue
        record["token"] = token as CKRecordValue
        record["teamID"] = teamID as CKRecordValue
        record["keyID"] = keyID as CKRecordValue
        record["topic"] = topic as CKRecordValue
        record["pem"] = pem as CKRecordValue

        return record
    }
}
