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

import CloudKit
import Foundation
import SwiftUI

// MARK: - PushServerModel

nonisolated struct PushServerModel: Codable, Identifiable, Equatable {
    var id: String
    var url: String
    var key: String = ""
    var group: String? = nil
    var status: Int = 0
    var createDate: Date = .now
    var updateDate: Date = .now
    var sign: String? = nil

    init(
        id: String = UUID().uuidString,
        url: String,
        key: String = "",
        group: String? = nil,
        status: Int = 0,
        createDate: Date = .now,
        updateDate: Date = .now,
        sign: String? = nil
    ) {
        self.id = id
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

    var color: Color { status > 0 ? .green : .orange }

    var server: String { url + "/" + key }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url && lhs.key == rhs.key
    }
    
    static var noServer: Self{
        PushServerModel(id: "000000", url: String(localized: "无服务器"), status: -1)
    }
}

nonisolated extension PushServerModel: Hashable, CloudKitConvertible {
    static let recordType = "PushServerModal"

    /// 本地状态字段不上传：`status` 是运行时探活结果；`createDate/updateDate` 由 CloudKit 的
    /// `creationDate/modificationDate` 提供。
    static var skippedKeys: Set<String> {
        ["status", "createDate", "updateDate"]
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(key)
    }

    /// 遗留调用点：AppManager.syncServer 传入 recordType 字符串。这里忽略参数，走协议约定的类型名。
    func toCKRecord(recordType _: String) -> CKRecord {
        toRecord()
    }

    init?(from record: CKRecord) {
        self.init(record: record)
    }

    init?(record: CKRecord) {
        self.id = record.recordID.recordName
        guard let url = record["url"] as? String,
              let key = record["key"] as? String else { return nil }
        self.url = url
        self.key = key
        self.group = record["group"] as? String
        self.sign = record["sign"] as? String
        self.createDate = record.creationDate ?? .now
        self.updateDate = record.modificationDate ?? .now
        self.status = 0
    }
}
