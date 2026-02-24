//
//  CloudKitManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/3/15.
//
import CloudKit
import Defaults
import Foundation
import SwiftUI

final class CloudManager {
    static let shared = CloudManager()

    private init() {
        Task {
            await checkAccount()
        }
    }

    private let container = CKContainer(identifier: NCONFIG.icloudName)

    private var database: CKDatabase {
        container.publicCloudDatabase
    }

    private var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }

    static let pushIconName = "PushIcon"
    static let deviceTokenName = "DeviceToken"
    static let apnsInfoName = "ApnsInfo"
    static let serverName = "PushServerModal"
    static let weChatInfo = "WeChatInfo"

    func checkAccount() async -> (Bool, String) {
        var message = (false, String(localized: "未知 iCloud 状态"))
        do {
            let status = try await container.accountStatus()

            switch status {
            case .available:
                message = (true, String(localized: "iCloud 账户可用"))
            case .couldNotDetermine:
                message = (false, String(localized: "无法确定 iCloud 账户状态，可能是网络问题"))
            case .restricted:
                message = (false, String(localized: "iCloud 访问受限，可能由家长控制或 MDM 设备管理策略导致"))
            case .noAccount:
                message = (false, String(localized: "未登录 iCloud，请登录 iCloud 账户"))
            case .temporarilyUnavailable:
                message = (false, String(localized: "iCloud 服务暂时不可用，请稍后再试"))
            @unknown default:
                message = (false, String(localized: "未知 iCloud 状态"))
            }
            logger.info("\(message.0),\(message.1)")
        } catch {
            message = (false, String(localized: "检查 iCloud 账户状态出错"))
            logger.error("\(error) - \(message.1)")
        }

        return message
    }

    func fetchRecords(
        _ recordType: String,
        for predicate: NSPredicate,
        in database: CKDatabase,
        limit: Int = 100
    ) async -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        do {
            let (records, _) = try await database.records(matching: query, resultsLimit: limit)

            return records.compactMap { _, result -> CKRecord? in
                switch result {
                case .success(let record):
                    return record
                case .failure(let error):
                    logger.error("获取单个记录失败: \(error)")
                    return nil
                }
            }
        } catch {
            logger.error("查询失败: \(error)")
            return [] // 查询失败返回空数组
        }
    }

    func queryIconsForMe() async -> [CKRecord] {
        do {
            let userID = try await container.userRecordID()
            let datas = await fetchRecords(
                Self.pushIconName,
                for: NSPredicate(format: "creatorUserRecordID == %@", userID),
                in: database
            )

            return datas
        } catch {
            logger.error("\(error)")
            return []
        }
    }

    func queryIcons(name: String? = nil, descriptions: [String]? = nil) async -> [CKRecord] {
        var predicates: [NSPredicate] = []

        // **查询 Name**
        if let name = name {
            predicates.append(NSPredicate(format: "name == %@", name))
        }

        // **查询 Descriptions（多个值）**
        if let descriptions = descriptions, !descriptions.isEmpty {
            predicates.append(NSPredicate(format: "ANY description IN %@", descriptions))
        }

        // **合并所有查询条件**
        let predicate: NSPredicate
        if predicates.isEmpty {
            predicate = NSPredicate(value: true) // 查询所有数据
        } else if predicates.count == 1 {
            predicate = predicates.first!
        } else {
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }

        // **执行查询**
        let records = await fetchRecords(Self.pushIconName, for: predicate, in: database)

        // **去重**
        var uniqueRecords: [CKRecord] = []
        var seenRecordIDs: Set<CKRecord.ID> = []
        for record in records {
            if !seenRecordIDs.contains(record.recordID) {
                uniqueRecords.append(record)
                seenRecordIDs.insert(record.recordID)
            }
        }

        logger.info("查询到 \(uniqueRecords.count) 条记录")

        return uniqueRecords
    }

    // MARK: - 保存记录到 CloudKit（检查  name 是否重复）

    func savePushIconModel(_ record: CKRecord?) async -> (Bool, String) {
        guard let record = record else { return (false, String(localized: "没有文件")) }

        let (success, message) = await checkAccount()

        guard success else { return (false, message) }

        guard let name = record["name"] as? String,
              !name.isEmpty else { return (false, String(localized: "参数不全")) }

        let description = record["description"] as? [String]

        logger.info("\(name)-\(String(describing: description))")

        let records = await queryIcons(name: name)

        guard records.count == 0 else { return (false, String(localized: "图片key重复")) }

        do {
            let recordRes = try await database.save(record)
            logger.error("\(recordRes)")
            return (true, String(localized: "保存成功"))
        } catch {
            logger.error("\(error)")
            return (false, String(localized: "保存失败") + "：\(error)")
        }
    }

    // 删除指定的 PushIcon
    func delete(_ serverID: String, pub: Bool = true) async -> Bool {
        let database = pub ? database : privateDatabase
        do {
            // 创建 CKRecord.ID 对象
            let recordID = CKRecord.ID(recordName: serverID)
            // 调用数据库的 delete 方法删除记录
            _ = try await database.deleteRecord(withID: recordID)
            return true
        } catch {
            logger.fault("\(error)")
            return false
        }
    }

    // MARK: - LOGIN

    func queryOrUpdateDeviceToken(_ userID: String, token: String? = nil) async -> String? {
        do {
            let predicate = NSPredicate(format: "device == %@", userID)
            guard let record = await fetchRecords(
                Self.deviceTokenName,
                for: predicate,
                in: database
            )
            .first
            else {
                if let token {
                    let record = CKRecord(recordType: Self.deviceTokenName)
                    record["device"] = userID as CKRecordValue
                    record["token"] = token as CKRecordValue
                    let recordRes = try await database.save(record)
                    return recordRes["token"] as? String
                }
                return nil
            }

            if let token {
                record["device"] = userID as CKRecordValue
                record["token"] = token as CKRecordValue
                let recordRes = try await database.save(record)
                return recordRes["token"] as? String
            }

            return record["token"] as? String

        } catch {
            logger.error("\(error)")
            return nil
        }
    }

    func pushToken(update: @escaping (CKRecord) throws -> (String, Date)) async throws -> CKRecord {
        let predicate = NSPredicate(value: true)

        guard let record = await fetchRecords(Self.apnsInfoName, for: predicate, in: database).first
        else {
            throw "No Data!!!"
        }

        guard let timestamp = record["timestamp"] as? Date else {
            throw "No Data!!!"
        }

        // 如果未过期且有 token，直接返回
        if timestamp > Date() { return record }

        // 调用 update 获取新 token
        let (token, date) = try update(record)
        
        record["token"] = token
        record["timestamp"] = date

        // 保存到 CloudKit
        _ = try await database.save(record)

        return record
    }

    func synchronousServers(from records: [CKRecord]) async -> [CKRecord] {
        let cloudRecords = await fetchRecords(
            Self.serverName,
            for: NSPredicate(value: true),
            in: privateDatabase
        )

        var cloudIndex: [String: CKRecord] = [:]

        for record in cloudRecords {
            guard
                let url = record["url"] as? String,
                let key = record["key"] as? String
            else { continue }

            cloudIndex["\(url)|\(key)"] = record
        }

        var waitRecords: [CKRecord] = []

        for record in records {
            guard
                record["group"] == nil,
                let url = record["url"] as? String,
                let key = record["key"] as? String
            else {
                continue
            }

            let compositeKey = "\(url)|\(key)"

            if cloudIndex[compositeKey] == nil {
                waitRecords.append(record)
            }
        }

        guard !waitRecords.isEmpty else { return cloudRecords }

        do {
            let results = try await privateDatabase.modifyRecords(
                saving: waitRecords,
                deleting: [],
                savePolicy: .ifServerRecordUnchanged
            )
            let uploadDatas = results.saveResults.values.compactMap { try? $0.get() }
            logger.info("\(uploadDatas)")

            return cloudRecords + uploadDatas

        } catch {
            logger.error("Failed to upload records:\(error)")
            return cloudRecords
        }
    }
    
    func downloadWeChatInfo() async {
        
    }
}
