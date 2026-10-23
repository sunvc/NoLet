//
//  CloudModels.swift
//  NoLet
//
//  手机与手表(iOS / watchOS)共享的 CloudKit 私有库模型。
//  只允许依赖 Foundation / CloudKit / CryptoKit:
//  手机端由主 target 默认编译,手表端通过 Publics 同步组的
//  membershipExceptions 编译,因此不得引用 NCONFIG / Defaults / UIKit。
//

import CloudKit
import CryptoKit
import Foundation
import OSLog

// MARK: - Schema

enum CloudSchema {
    /// 与 NCONFIG.container 同一个容器;watch target 不编译 NCONFIG,这里重复常量。
    static let containerID = "iCloud.pushback"
    static let container = CKContainer(identifier: containerID)
    static var privateDB: CKDatabase { container.privateCloudDatabase }

    enum RecordType {
        static let message = "CloudMessage"
        /// 已废弃:加密密钥不允许上云。仅用于一次性清理早期测试写入的记录。
        static let deprecatedCrypto = "CloudCryptoConfig"
        // 服务器复用既有 recordType(PushServerModel.recordType):"PushServerModal"
    }

    enum SubscriptionID {
        static let messageChanges = "cloud-message-changes"
    }

    /// 私有库保留策略:超出条数或天数的消息由手机端清理。
    static let messageKeepCount = 200
    static let messageKeepDays: TimeInterval = 90 * 24 * 60 * 60
    static let queryPageSize = 400

    /// 拼 title/body 身份时的分隔符(Unit Separator),防拼接碰撞。
    static let dedupSeparator = "\u{001F}"

    static let cloudLog = Logger(subsystem: "app.wzs.logger", category: "CloudSync")
}

// MARK: - CloudMessage

/// 跨设备同步的一条消息。
///
/// 身份与本地 Core Data 的 UUID 无关:`recordName = SHA256(title + 分隔符 + body)`,
/// 因此两端收到 title+body 完全相同的推送会落在同一条 CKRecord 上(天然去重)。
struct CloudMessage: Sendable, Codable, Identifiable {
    var id: String
    var title: String?
    var body: String
    var subtitle: String?
    var group: String?
    var url: String?
    var style: String?
    var createDate: Date
    var read: Bool
    /// "phone" / "watch"
    var source: String?

    var recordID: CKRecord.ID { CKRecord.ID(recordName: id) }

    /// 从 ArchiveProcessor 写出的 JSON(手机 drain)或手表收到的 userInfo 构造。
    /// title/body 读取优先取 aps.alert(复用 PushParams 的 raw 助手,与扩展一致)。
    /// 标题与正文同时为空时返回 nil(与 ArchiveProcessor 的归档门槛一致)。
    init?(json: [AnyHashable: Any], source: String) {
        let title = json.raw(.title, as: String.self)
        let body = json.raw(.body, as: String.self) ?? ""
        let subtitle = json.raw(.subtitle, as: String.self)

        guard (title.map { !$0.isEmpty } ?? false) || !body.isEmpty else { return nil }

        self.id = Self.identityID(title: title, body: body)
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.group = json.raw(.group, as: String.self)
        self.url = json.raw(.url, as: String.self)
        self.style = json.raw(.style, as: String.self)
        if let seconds = json[.createDate] as? NSNumber {
            self.createDate = Date(timeIntervalSince1970: seconds.doubleValue)
        } else {
            self.createDate = .now
        }
        self.read = json[.read] as? Bool ?? false
        self.source = source
    }

    init?(record: CKRecord) {
        id = record.recordID.recordName
        title = record["title"] as? String
        body = record["body"] as? String ?? ""
        subtitle = record["subtitle"] as? String
        group = record["group"] as? String
        url = record["url"] as? String
        style = record["style"] as? String
        createDate = (record["createDate"] as? Date) ?? record.creationDate ?? .now
        read = (record["read"] as? NSNumber)?.boolValue ?? false
        source = record["source"] as? String
    }

    /// 与 MessageEntity.jsonDictionary / apply(jsonDictionary:) 兼容,
    /// ttl 写 -1:云消息不参与本地 ttl 过期,寿命由云端保留策略管理。
    var jsonDictionary: [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        dict[.id] = id
        dict[.createDate] = Int(createDate.timeIntervalSince1970)
        dict[.group] = group ?? String(localized: "默认")
        dict[.body] = body
        dict[.ttl] = Int64(-1)
        dict[.read] = read
        if let title { dict[.title] = title }
        if let subtitle { dict[.subtitle] = subtitle }
        if let url { dict[.url] = url }
        if let style { dict[.style] = style }
        return dict
    }

    /// title + body 相同即同一条消息。
    nonisolated static func identityID(title: String?, body: String) -> String {
        let basis = (title ?? "") + CloudSchema.dedupSeparator + body
        return SHA256.hash(data: Data(basis.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// 合并到一条已存在的云端记录:
    /// createDate 取最早、read 取 OR、非空字段才覆盖、source 保留已有。
    @discardableResult
    func makeRecord(merging existing: CKRecord? = nil) -> CKRecord {
        guard let existing else {
            let record = CKRecord(
                recordType: CloudSchema.RecordType.message,
                recordID: recordID
            )
            record["title"] = title as NSString?
            record["body"] = body as NSString
            record["subtitle"] = subtitle as NSString?
            record["group"] = group as NSString?
            record["url"] = url as NSString?
            record["style"] = style as NSString?
            record["source"] = source as NSString?
            record["createDate"] = createDate as NSDate
            record["read"] = read as NSNumber
            return record
        }

        if let oldDate = existing["createDate"] as? Date {
            existing["createDate"] = Swift.min(oldDate, createDate) as NSDate
        } else {
            existing["createDate"] = createDate as NSDate
        }
        let oldRead = (existing["read"] as? NSNumber)?.boolValue ?? false
        existing["read"] = (oldRead || read) as NSNumber

        if let title, !title.isEmpty { existing["title"] = title as NSString }
        if !body.isEmpty { existing["body"] = body as NSString }
        if let subtitle, !subtitle.isEmpty { existing["subtitle"] = subtitle as NSString }
        if let group, !group.isEmpty { existing["group"] = group as NSString }
        if let url, !url.isEmpty { existing["url"] = url as NSString }
        if let style, !style.isEmpty { existing["style"] = style as NSString }
        if let source, !source.isEmpty, existing["source"] == nil {
            existing["source"] = source as NSString
        }
        return existing
    }
}

// MARK: - CloudKitStore

/// 唯一直接执行 CloudKit 网络操作的地方。actor 串行化所有修改,
/// 使同一份代码在 iOS(Swift 6)与 watchOS(Swift 5、MainActor 默认隔离已关闭)
/// 下都能通过并发检查。
actor CloudKitStore {
    static let shared = CloudKitStore()

    /// CKModifyRecordsOperation 的 @Sendable 回调里收集结果的线程安全盒子。
    private final class ModifyOutcome: @unchecked Sendable {
        private let lock = NSLock()
        private var conflicts: [CKRecord.ID: CKRecord] = [:]
        private var failedSaves = Set<CKRecord.ID>()

        func setConflict(_ record: CKRecord, for id: CKRecord.ID) {
            lock.lock()
            conflicts[id] = record
            lock.unlock()
        }

        func markFailed(_ id: CKRecord.ID) {
            lock.lock()
            failedSaves.insert(id)
            lock.unlock()
        }

        func take() -> (conflicts: [CKRecord.ID: CKRecord], failedSaves: Set<CKRecord.ID>) {
            lock.lock()
            let result = (conflicts, failedSaves)
            conflicts = [:]
            failedSaves = []
            lock.unlock()
            return result
        }
    }

    // MARK: Messages

    /// 批量保存消息。按确定性 recordName 幂等;服务器版本变化时合并重试一次。
    func saveMessages(_ messages: [CloudMessage]) async {
        guard !messages.isEmpty else { return }
        let db = CloudSchema.privateDB

        var records: [CKRecord] = []
        for message in messages {
            let existing: CKRecord?
            do {
                existing = try await db.record(for: message.recordID)
            } catch let error as CKError where error.code == .unknownItem {
                existing = nil
            } catch {
                existing = nil
            }
            records.append(message.makeRecord(merging: existing))
        }

        for attempt in 0..<2 where !records.isEmpty {
            let outcome = await modify(records: records, deleting: [], database: db)
            if attempt == 0, !outcome.conflicts.isEmpty {
                records = outcome.conflicts.compactMap { conflict -> CKRecord? in
                    guard let message = messages.first(where: { $0.id == conflict.key.recordName })
                    else { return nil }
                    return message.makeRecord(merging: conflict.value)
                }
            } else {
                records = []
            }
        }
    }

    /// 拉取消息,按 createDate 倒序。modifiedAfter 用系统 modificationDate 做增量。
    /// 失败(未登录/网络)返回 nil,便于调用方区分"云端为空"与"没拉到"。
    func fetchMessagesResult(
        limit: Int = CloudSchema.queryPageSize,
        modifiedAfter: Date? = nil
    ) async -> [CloudMessage]? {
        let predicate: NSPredicate
        if let modifiedAfter {
            predicate = NSPredicate(format: "modificationDate > %@", modifiedAfter as NSDate)
        } else {
            predicate = NSPredicate(value: true)
        }
        let query = CKQuery(recordType: CloudSchema.RecordType.message, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "createDate", ascending: false),
        ]

        do {
            let (matched, _) = try await CloudSchema.privateDB.records(
                matching: query,
                resultsLimit: limit
            )
            return matched.compactMap { _, result in
                switch result {
                case let .success(record): CloudMessage(record: record)
                case .failure: nil
                }
            }
        } catch {
            CloudSchema.cloudLog.error("fetchMessages failed: \(error as NSError)")
            return nil
        }
    }

    /// 便利方法:失败按空数组处理。
    func fetchMessages(
        limit: Int = CloudSchema.queryPageSize,
        modifiedAfter: Date? = nil
    ) async -> [CloudMessage] {
        await fetchMessagesResult(limit: limit, modifiedAfter: modifiedAfter) ?? []
    }

    /// 保留最近 messageKeepCount 条,并删除早于 messageKeepDays 的消息。
    /// 约定只由手机端调度,避免双端竞争删除。
    func enforceMessageRetention() async {
        let db = CloudSchema.privateDB
        let query = CKQuery(
            recordType: CloudSchema.RecordType.message,
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: true)]

        var oldest: [(CKRecord.ID, Date)] = []
        var cursor: CKQueryOperation.Cursor?

        do {
            repeat {
                let matched: [(CKRecord.ID, Result<CKRecord, Error>)]
                let nextCursor: CKQueryOperation.Cursor?
                if let cursor {
                    (matched, nextCursor) = try await db.records(continuingMatchFrom: cursor)
                } else {
                    (matched, nextCursor) = try await db.records(
                        matching: query,
                        resultsLimit: CloudSchema.queryPageSize
                    )
                }
                cursor = nextCursor
                for (id, result) in matched {
                    if case let .success(record) = result,
                       let date = record["createDate"] as? Date
                    {
                        oldest.append((id, date))
                    }
                }
            } while cursor != nil
        } catch {
            CloudSchema.cloudLog.error("retention scan failed: \(error as NSError)")
            return
        }

        guard !oldest.isEmpty else { return }
        let cutoff = Date(timeIntervalSinceNow: -CloudSchema.messageKeepDays)
        let overflowCount = max(0, oldest.count - CloudSchema.messageKeepCount)
        var toDelete = Array(oldest.prefix(overflowCount).map(\.0))
        let kept = oldest.suffix(CloudSchema.messageKeepCount)
        for (id, date) in kept where date < cutoff {
            toDelete.append(id)
        }
        guard !toDelete.isEmpty else { return }
        _ = await modify(records: [], deleting: toDelete, database: db)
    }

    // MARK: Deprecated crypto records cleanup

    /// 加密密钥已改为永不上云。删除早期测试版本写入私有库的 CloudCryptoConfig 记录。
    /// 一次性调用(调用方用 flag 保证只跑一次)。
    /// 加密密钥已改为永不上云。删除早期测试版本写入私有库的 CloudCryptoConfig 记录。
    /// 返回 true 表示已确认云端没有遗留(含该类型从不存在的情况);未登录等失败返回 false,
    /// 调用方不标记完成,下次启动重试。
    @discardableResult
    func purgeDeprecatedCryptoRecords() async -> Bool {
        let db = CloudSchema.privateDB
        let query = CKQuery(
            recordType: CloudSchema.RecordType.deprecatedCrypto,
            predicate: NSPredicate(value: true)
        )
        do {
            let (matched, _) = try await db.records(
                matching: query,
                resultsLimit: CloudSchema.queryPageSize
            )
            let ids = matched.compactMap { id, result -> CKRecord.ID? in
                if case .success = result { return id }
                return nil
            }
            if !ids.isEmpty {
                _ = await modify(records: [], deleting: ids, database: db)
                CloudSchema.cloudLog.notice("purged \(ids.count) deprecated crypto records")
            }
            return true
        } catch let error as CKError
            where error.code == .unknownItem
                || error.code == .invalidArguments
                || error.code == .operationCancelled
        {
            // 从未部署过该记录类型
            return true
        } catch {
            CloudSchema.cloudLog.error("purge crypto records failed: \(error as NSError)")
            return false
        }
    }

    // MARK: Account

    /// 私有库要求设备登录 iCloud;未登录时所有读写都会失败(Not Authenticated)。
    func isAccountAvailable() async -> Bool {
        do {
            return try await CloudSchema.container.accountStatus() == .available
        } catch {
            return false
        }
    }

    // MARK: Subscriptions

    /// 幂等注册私有库静默推送订阅(参照 PushServerModel.registerChangesSubscription)。
    func ensureSubscription(recordType: String, subscriptionID: String) async throws {
        let db = CloudSchema.privateDB
        let existing = try await db.allSubscriptions()
        guard !existing.contains(where: { $0.subscriptionID == subscriptionID }) else {
            return
        }

        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        _ = try await db.save(subscription)
    }

    /// 从静默推送 userInfo 取 CK 订阅 ID(参照 PushServerModel.subHandler)。
    static func subscriptionID(in userInfo: [AnyHashable: Any]) -> String? {
        CKNotification(fromRemoteNotificationDictionary: userInfo)?.subscriptionID
    }

    // MARK: CKModifyRecordsOperation

    /// 执行一批保存/删除。返回 serverRecordChanged 冲突的服务器当前记录,
    /// 调用方可合并后重试。其它单条错误忽略(CK 私有库同步以重试/对端覆盖兜底)。
    @discardableResult
    private func modify(
        records: [CKRecord],
        deleting recordIDs: [CKRecord.ID],
        database: CKDatabase
    ) async -> (conflicts: [CKRecord.ID: CKRecord], failedSaves: Set<CKRecord.ID>) {
        let box = ModifyOutcome()

        let operation = CKModifyRecordsOperation(
            recordsToSave: records.isEmpty ? nil : records,
            recordIDsToDelete: recordIDs.isEmpty ? nil : recordIDs
        )
        operation.savePolicy = .ifServerRecordUnchanged
        operation.isAtomic = false
        operation.qualityOfService = .utility

        operation.perRecordSaveBlock = { recordID, result in
            switch result {
            case .success:
                break
            case let .failure(error as CKError) where error.code == .serverRecordChanged:
                if let serverRecord = error.serverRecord {
                    box.setConflict(serverRecord, for: serverRecord.recordID)
                } else {
                    box.markFailed(recordID)
                }
            case .failure:
                box.markFailed(recordID)
            }
        }

        operation.perRecordDeleteBlock = { recordID, result in
            if case let .failure(error) = result {
                CloudSchema.cloudLog.error(
                    "delete record \(recordID.recordName) failed: \(error as NSError)"
                )
            }
        }

        return await withCheckedContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                if case let .failure(error) = result {
                    CloudSchema.cloudLog.error("CKModifyRecords failed: \(error as NSError)")
                }
                continuation.resume(returning: box.take())
            }
            database.add(operation)
        }
    }
}
