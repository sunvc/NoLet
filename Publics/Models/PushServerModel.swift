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

struct PushServerModel: Codable, Identifiable, Equatable {
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

    static var noServer: Self {
        PushServerModel(id: "000000", url: String(localized: "无服务器"), status: -1)
    }
}

extension PushServerModel: Hashable, CloudKitConvertible {
    static let recordType = "PushServerModal"

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

// MARK: - CloudKit 订阅

extension PushServerModel {
    /// 私有数据库服务器记录变更订阅 ID（同账号其它设备增删改时唤醒本端）。
    static let changesSubscriptionID = "push-server-changes"

    /// 在私有数据库注册静默推送订阅，幂等：已存在则跳过。
    static func registerChangesSubscription(
        on database: CKDatabase = NCONFIG.privateCloudDatabase
    ) async throws {
        let existing = try await database.allSubscriptions()
        guard !existing.contains(where: { $0.subscriptionID == changesSubscriptionID }) else {
            return
        }

        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: changesSubscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        try await database.save(subscription)
    }

    static func subHandler(
        _ userInfo: [AnyHashable: Any],
        complete: @escaping @Sendable () async -> Void
    ) {
        let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        let isServerChange = ckNotification?.subscriptionID == Self.changesSubscriptionID

        if isServerChange {
            Task { await complete() }
        }
    }
}
