//
//  CloudKitManager.swift
//  pushback
//
//  Created by lynn on 2025/3/15.
//
import Foundation
import CloudKit
import SwiftUI
import Defaults


struct PushIcon: Identifiable {
    var id:String = UUID().uuidString
    var name:String
    var description:[String]
    var size:Int
    var sha256:String
    var file: URL?
    var previewImage: UIImage?
    
    
    func toRecord(recordType: String) -> CKRecord?{
        
        guard let file = self.file else { return nil }
        
        let recordID = CKRecord.ID(recordName: self.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["name"] = self.name as CKRecordValue
        record["description"] = self.description as CKRecordValue
        record["data"] = CKAsset(fileURL: file)
        record["size"] = self.size as CKRecordValue
        record["sha256"] = self.sha256 as CKRecordValue
        
        
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
        case .notFile(let msg), .paramsSpace(let msg), .saveError(let msg), .nameRepeat(let msg), .iconRepeat(let msg), .success(let msg), .authority(let msg):
            return msg
            
        }
    }
}

extension CKRecord{
    func toPushIcon() -> PushIcon? {
        guard let name =  self["name"] as? String ,
              let description =  self["description"] as? [String] ,
              let asset = self["data"] as? CKAsset,
              let fileURL = asset.fileURL,
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) ,
              let size = self["size"] as? Int,
              let sha256 =  self["sha256"] as? String else { return nil }
        
        return PushIcon(id: self.recordID.recordName, name: name, description: description,size: size,sha256: sha256, file: fileURL, previewImage: image)
    }
}


class CloudManager {
    
    static let shared = CloudManager()
    
    private init() {}
    private let container = CKContainer(identifier: BaseConfig.icloudName)
    
    private var database: CKDatabase {
        container.publicCloudDatabase
    }
    private let recordType = "PushIcon"
    
    func checkAccount() async -> (Bool, String) {
        do {
            let status = try await container.accountStatus()
            
          
            
            switch status {
            case .available:
                return (true,  String(localized: "iCloud 账户可用"))
            case .couldNotDetermine:
                return (false,  String(localized: "无法确定 iCloud 账户状态，可能是网络问题"))
            case .restricted:
                return (false,  String(localized: "iCloud 访问受限，可能由家长控制或 MDM 设备管理策略导致"))
            case .noAccount:
                return (false,  String(localized: "未登录 iCloud，请登录 iCloud 账户"))
            case .temporarilyUnavailable:
                return (false,  String(localized: "iCloud 服务暂时不可用，请稍后再试"))
            @unknown default:
                return (false,  String(localized: "未知 iCloud 状态"))
            }
        } catch {
            return (false,  String(localized: "检查 iCloud 账户状态出错: \(error.localizedDescription)"))
        }
    }
    
    func fetchRecords(for predicate: NSPredicate, in database: CKDatabase, limit: Int = 100) async -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        do {
            // 直接使用 async 方法查询
            let (records, _) = try await database.records(matching: query, resultsLimit: limit)
            
            // 返回查询到的记录
            return records.compactMap { (_, result) -> CKRecord? in
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
            return []  // 查询失败返回空数组
        }
    }
    
    func queryIconsForMe() async -> [CKRecord] {
        do{
            let userId = try await container.userRecordID()
            let datas = await self.fetchRecords(for: NSPredicate(format: "creatorUserRecordID == %@", userId), in: database)
            
            return datas
        }catch {
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
        let records = await fetchRecords(for: predicate,in: database)

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

        let (success,message) = await self.checkAccount()
        
        guard success else { return .authority(message)}
        
        NLog.log(model.name,model.description)
        
        if model.name.isEmpty  {
            return .paramsSpace(String(localized: "参数不全"))
        }

        let records =  await self.queryIcons(name: model.name)

        guard records.count == 0 else {  return .nameRepeat(String(localized: "图片key重复")) }
        
        guard let record = model.toRecord(recordType: self.recordType) else { return PushIconCloudError.notFile(String(localized: "没有文件"))}
        
        do{
            let recordRes = try await database.save(record)
            NLog.error(recordRes)
            return .success(String(localized: "保存成功"))
        }catch{
            NLog.error(error.localizedDescription)
            return .saveError(String(localized: "保存失败：\(error.localizedDescription)"))
        }
        
    }
    
    // 删除指定的 PushIcon
    func deleteCloudIcon(_ serverID: String, completion: @escaping (Error?) -> Void) {
        // 创建 CKRecord.ID 对象
        let recordID = CKRecord.ID(recordName: serverID)
        
        // 调用数据库的 delete 方法删除记录
        database.delete(withRecordID: recordID) { (deletedRecordID, error) in
            if let error = error {
                // 删除失败时，调用 completion 回调并传递错误信息
                completion(error)
            } else {
                // 删除成功时，调用 completion 回调
                completion(nil)
            }
        }
    }
    
    // MARK: - LOGIN
    func queryUser(_ userID: String? = nil, email: String? = nil, token: String? = nil) async -> CKRecord?{
        do{
            let id = try await container.userRecordID()
            let user = try await database.record(for: id)
        
        

            if let userID{
                user["phone"] = userID as CKRecordValue
            }
            
            if let email{
                user["email"] = email as CKRecordValue
            }
            
            if let token{
                user["token"] = token as CKRecordValue
            }
           
            guard userID != nil || email != nil || token != nil else {
                return user
            }
           
            
            let recordRes = try await database.save(user)
            return recordRes
        }catch{
            NLog.error(error.localizedDescription)
            return nil
        }
    }
    
}


