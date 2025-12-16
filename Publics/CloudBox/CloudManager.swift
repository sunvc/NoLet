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

struct PushIcon: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var description: [String]
    var size: Int
    var sha256: String
    var file: URL?
    var previewImage: UIImage?

    func toRecord(recordType: String) -> CKRecord? {
        guard let file = file else { return nil }

        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["name"] = name as CKRecordValue
        record["description"] = description as CKRecordValue
        record["data"] = CKAsset(fileURL: file)
        record["size"] = size as CKRecordValue
        record["sha256"] = sha256 as CKRecordValue

        return record
    }
}

enum PushIconCloudError: Error {
    case notFile(String)
    case paramsSpace(String)
    case saveError(String)
    case nameRepeat(String)
    case iconRepeat(String)
    case success(String)
    case authority(String)

    var tips: String {
        switch self {
        case .notFile(let msg), .paramsSpace(let msg), .saveError(let msg), .nameRepeat(let msg),
             .iconRepeat(let msg), .success(let msg), .authority(let msg):
            return msg
        }
    }
}

extension CKRecord {
    func toPushIcon() -> PushIcon? {
        guard let name = self["name"] as? String,
              let description = self["description"] as? [String],
              let asset = self["data"] as? CKAsset,
              let fileURL = asset.fileURL,
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData),
              let size = self["size"] as? Int,
              let sha256 = self["sha256"] as? String else { return nil }

        return PushIcon(
            id: recordID.recordName,
            name: name,
            description: description,
            size: size,
            sha256: sha256,
            file: fileURL,
            previewImage: image
        )
    }
}

class CloudManager {
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

    private let recordType = "PushIcon"
    private let deviceToken = "DeviceToken"

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
            NLog.log(message)
        } catch {
            message = (false, String(localized: "检查 iCloud 账户状态出错: \(error.localizedDescription)"))
            NLog.error(message)
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
                    NLog.error("获取单个记录失败: \(error.localizedDescription)")
                    return nil
                }
            }
        } catch {
            NLog.error("查询失败: \(error.localizedDescription)")
            return [] // 查询失败返回空数组
        }
    }

    func queryIconsForMe() async -> [CKRecord] {
        do {
            let userID = try await container.userRecordID()
            let datas = await fetchRecords(
                recordType,
                for: NSPredicate(format: "creatorUserRecordID == %@", userID),
                in: database
            )

            return datas
        } catch {
            NLog.error(error.localizedDescription)
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
        let records = await fetchRecords(recordType, for: predicate, in: database)

        // **去重**
        var uniqueRecords: [CKRecord] = []
        var seenRecordIDs: Set<CKRecord.ID> = []
        for record in records {
            if !seenRecordIDs.contains(record.recordID) {
                uniqueRecords.append(record)
                seenRecordIDs.insert(record.recordID)
            }
        }

        NLog.log("查询到 \(uniqueRecords.count) 条记录")

        return uniqueRecords
    }

    // MARK: - 保存记录到 CloudKit（检查  name 是否重复）

    func savePushIconModel(_ model: PushIcon) async -> PushIconCloudError {
        let (success, message) = await checkAccount()

        guard success else { return .authority(message) }

        NLog.log(model.name, model.description)

        if model.name.isEmpty {
            return .paramsSpace(String(localized: "参数不全"))
        }

        let records = await queryIcons(name: model.name)

        guard records.count == 0 else { return .nameRepeat(String(localized: "图片key重复")) }

        guard let record = model.toRecord(recordType: recordType)
        else { return PushIconCloudError.notFile(String(localized: "没有文件")) }

        do {
            let recordRes = try await database.save(record)
            NLog.error(recordRes)
            return .success(String(localized: "保存成功"))
        } catch {
            NLog.error(error.localizedDescription)
            return .saveError(String(localized: "保存失败") + "：\(error.localizedDescription)")
        }
    }

    // 删除指定的 PushIcon
    func delete(_ serverID: String) async -> Bool {
        do {
            // 创建 CKRecord.ID 对象
            let recordID = CKRecord.ID(recordName: serverID)
            // 调用数据库的 delete 方法删除记录
            _ = try await database.deleteRecord(withID: recordID)
            return true
        } catch {
            return false
        }
    }

    // MARK: - LOGIN

    func queryOrUpdateDeviceToken(_ userID: String, token: String? = nil) async -> String? {
        do {
            let predicate = NSPredicate(format: "device == %@", userID)
            guard let record = await fetchRecords(deviceToken, for: predicate, in: database).first
            else {
                if let token {
                    let record = CKRecord(recordType: deviceToken)
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
            NLog.error(error.localizedDescription)
            return nil
        }
    }

    func pushToken(update: @escaping (ApnsInfo) throws -> ApnsInfo) async throws -> ApnsInfo {
        let predicate = NSPredicate(value: true)

        guard let record = await fetchRecords(ApnsInfo.recordType, for: predicate, in: database)
            .first
        else {
            throw "No Data!!!"
        }

        guard let apnsInfoOld = ApnsInfo(record: record) else {
            throw "No Data!!!"
        }

        // 如果未过期且有 token，直接返回
        if apnsInfoOld.timestamp > Date() {
            return apnsInfoOld
        }

        // 调用 update 获取新 token
        let apnsInfo = try update(apnsInfoOld)
        
        record["token"] = apnsInfo.token as CKRecordValue
        record["timestamp"] = apnsInfo.timestamp as CKRecordValue
        // 保存到 CloudKit
        _ = try await database.save(record)

        return apnsInfo
    }
}

struct ApnsInfo: Codable {
    static let recordType = "ApnsInfo"
    var id: String
    var timestamp: Date
    var token: String
    var teamID: String
    var keyID: String
    var topic: String
    var pem: String

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

        self.timestamp = record["timestamp"] as? Date ?? Date.distantFuture

        self.token = record["token"] as? String ?? ""

        self.teamID = teamID
        self.keyID = keyID
        self.topic = topic
        self.pem = pem
    }

    // MARK: - 初始化 CKRecord

    func toCKRecord() -> CKRecord {
        // 使用 id 作为 recordName
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: ApnsInfo.recordType, recordID: recordID)

        record["timestamp"] = timestamp as CKRecordValue
        record["token"] = token as CKRecordValue
        record["teamID"] = teamID as CKRecordValue
        record["keyID"] = keyID as CKRecordValue
        record["topic"] = topic as CKRecordValue
        record["pem"] = pem as CKRecordValue

        return record
    }
}
