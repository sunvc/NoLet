//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - CloudKitConvertible.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/25 20:44.

import CloudKit
import CoreLocation
import SwiftUI

/// 通过反射把 struct 序列化成 CKRecord 的协议。
///
/// 使用约定：
/// - `id` 字段作为 `CKRecord.ID` 的 `recordName`，**不会**再作为字段写入 record。
/// - 只支持扁平 struct。若字段本身是自定义 struct/class，反射不会递归到子层，
///   该字段会走 `default` 分支被静默丢弃（DEBUG 下会打印警告）。
/// - `nil` 字段默认**保留** record 中原有值（合并式更新）。若要显式清空，调用
///   `toRecord(existing:clearNilFields: true)`。
/// - 若字段类型未匹配到任一分支，DEBUG 下会打印警告；生产环境静默丢弃。
protocol CloudKitConvertible {
    var id: String { get }
    static var recordType: String { get }
    var recordID: CKRecord.ID { get }
    init?(record: CKRecord)
    func toRecord(existing: CKRecord?, clearNilFields: Bool) -> CKRecord
}

extension CloudKitConvertible {
    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: self.id)
    }

    /// 循环解包多层 Optional，直到拿到非 Optional 值或 nil。
    private func unwrap(_ any: Any) -> Any? {
        var current: Any? = any
        while let value = current {
            let mirror = Mirror(reflecting: value)
            guard mirror.displayStyle == .optional else {
                return value
            }
            current = mirror.children.first?.value
        }
        return nil
    }

    /// 把模型序列化为 CKRecord。
    ///
    /// - Parameters:
    ///   - existing: 若传入，会在此 record 上做增量更新（用于避免覆盖未反射到的字段）。
    ///   - clearNilFields: 默认 `false`。为 `true` 时，Swift 端为 `nil` 的字段会写入 `record[key] = nil`，
    ///     从而**抹掉云端已有的值**；为 `false` 时会跳过 `nil` 字段以保留原值。
    func toRecord(existing: CKRecord? = nil, clearNilFields: Bool = false) -> CKRecord {

        let record = existing ??
            CKRecord(recordType: Self.recordType, recordID: recordID)

        for child in Mirror(reflecting: self).children {

            guard let key = child.label, key != "id" else { continue }

            let value = unwrap(child.value)

            if value == nil {
                if clearNilFields {
                    record[key] = nil
                }
                // 默认保留旧值：不写 nil
                continue
            }

            if let ck = ckValue(from: value, key: key) {
                record[key] = ck
            }
            // ckValue 返回 nil 说明类型不支持，DEBUG 已在内部提示；此处保留 record 原值。
        }

        return record
    }

    /// 把 Swift 原生值映射到 CKRecordValue。仅在 value 为非 nil 时调用。
    private func ckValue(from value: Any?, key: String) -> CKRecordValue? {
        guard let value else { return nil }

        switch value {
        // 标量
        case let v as String: return v as NSString
        case let v as Bool:   return NSNumber(value: v)
        case let v as Int:    return NSNumber(value: v)   // 64bit 平台 Int == Int64
        case let v as Double: return NSNumber(value: v)
        case let v as Float:  return NSNumber(value: v)
        case let v as Date:   return v as NSDate
        case let v as Data:   return v as NSData

        // URL: 本地文件 → CKAsset; 其它 → absoluteString
        case let v as URL:
            return v.isFileURL ? CKAsset(fileURL: v) : (v.absoluteString as NSString)

        // 已经是 CloudKit 原生类型
        case let v as CKAsset:            return v
        case let v as CKRecord.Reference: return v
        case let v as CLLocation:         return v

        // List 类型 —— CloudKit 支持的元素类型
        case let v as [String]:             return v as NSArray
        case let v as [Int]:                return v as NSArray
        case let v as [Double]:             return v as NSArray
        case let v as [Date]:               return v as NSArray
        case let v as [Data]:               return v as NSArray
        case let v as [CKAsset]:            return v as NSArray
        case let v as [CLLocation]:         return v as NSArray
        case let v as [CKRecord.Reference]: return v as NSArray
        case let v as [URL]:
            let mapped: [CKRecordValue] = v.map {
                $0.isFileURL ? (CKAsset(fileURL: $0) as CKRecordValue)
                             : ($0.absoluteString as NSString)
            }
            return mapped as NSArray

        default:
            // RawRepresentable 枚举兜底 (String / Int / Double raw value)
            if let raw = (value as? any RawRepresentable)?.rawValue {
                return ckValue(from: raw, key: key)
            }

            #if DEBUG
            let mirror = Mirror(reflecting: value)
            let typeName = String(describing: type(of: value))
            if mirror.displayStyle == .struct || mirror.displayStyle == .class {
                print("⚠️ [CloudKitConvertible] Nested \(mirror.displayStyle == .struct ? "struct" : "class") not supported for key \"\(key)\": \(typeName). Reflection does not recurse; flatten this field.")
            } else {
                print("⚠️ [CloudKitConvertible] Unsupported type for key \"\(key)\": \(typeName)")
            }
            #endif
            return nil
        }
    }
}

// MARK: - CloudKit 数据库便捷操作

extension CloudKitConvertible {

    /// 按 id 从 CloudKit 拉一条记录。
    ///
    /// - Returns: 找不到记录（`CKError.unknownItem`）时返回 `nil`；其它错误抛出。
    static func fetch(
        id: String,
        from database: CKDatabase
    ) async throws -> Self? {
        let recordID = CKRecord.ID(recordName: id)
        do {
            let record = try await database.record(for: recordID)
            return Self(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    /// 按 predicate 查询记录列表。
    static func query(
        _ predicate: NSPredicate = NSPredicate(value: true),
        limit: Int = 100,
        from database: CKDatabase
    ) async throws -> [Self] {
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        let (matched, _) = try await database.records(
            matching: query,
            resultsLimit: limit
        )
        return matched.compactMap { _, result -> Self? in
            switch result {
            case .success(let record):
                return Self(record: record)
            case .failure:
                return nil
            }
        }
    }

    /// 保存到 CloudKit。
    ///
    /// - Parameters:
    ///   - database: 目标数据库（public / private）
    ///   - mergeExisting: `true` 会先按 recordID 拉云端已有记录，再在其上增量写入，
    ///     避免覆盖未在本模型反射到的字段。`false` 直接用本模型生成一条新 record 保存
    ///     （其它字段会被抹掉，等价于全量覆盖）。
    ///   - clearNilFields: 传给 `toRecord`；Swift 端为 nil 的字段是否写 nil 抹掉云端值。
    /// - Returns: 保存后回读的模型；解析失败时返回 nil。
    @discardableResult
    func save(
        to database: CKDatabase,
        mergeExisting: Bool = true,
        clearNilFields: Bool = false
    ) async throws -> Self? {
        var existing: CKRecord? = nil
        if mergeExisting {
            do {
                existing = try await database.record(for: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                existing = nil
            }
        }
        let record = toRecord(existing: existing, clearNilFields: clearNilFields)
        let saved = try await database.save(record)
        return Self(record: saved)
    }

    /// 从 CloudKit 删除本条记录。
    func delete(from database: CKDatabase) async throws {
        _ = try await database.deleteRecord(withID: recordID)
    }
}
