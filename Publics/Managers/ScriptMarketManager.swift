//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptMarketManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 插件中心 CloudKit 公共库读写（ScriptShare 记录）

//  History:
//    Created by Neo on 2026/9/9.

import CloudKit
import Defaults
import Foundation

final class ScriptMarketManager: @unchecked Sendable {
    static let shared = ScriptMarketManager()
    private init() {}

    typealias Cursor = CKQueryOperation.Cursor

    /// Record Type 在当前环境（开发/生产）还没创建：第一次上传保存记录前查询会报这个
    static func isMissingRecordType(_ error: Error) -> Bool {
        if let ckError = error as? CKError, ckError.code == .unknownItem {
            return true
        }
        let message = error.localizedDescription.lowercased()
        return message.contains("recordtype") || message.contains("record type")
    }

    /// 查询引用了 schema 中尚不存在的字段（新字段要等第一次保存记录后才自动创建）
    static func isUnknownField(_ error: Error) -> Bool {
        error.localizedDescription.lowercased().contains("unknown field")
    }

    /// 每用户上传上限（纯客户端约束，同云图标额度模式）
    let uploadLimit = 50
    private let pageLimit = 30

    /// 列表查询字段：排除 data(CKAsset)，不下载 JS 本体
    private let listKeys = ["name", "summary", "mode", "tags", "size", "sha256", "authorName"]

    // MARK: 浏览 / 搜索

    func list(
        mode: ScriptData.Mode? = nil,
        search: String = "",
        cursor: Cursor? = nil
    ) async throws -> (items: [ScriptShare], cursor: Cursor?) {
        let db = NCONFIG.publicCloudDatabase
        let result: (
            matchResults: [(CKRecord.ID, Result<CKRecord, Error>)],
            queryCursor: Cursor?
        )
        if let cursor {
            result = try await db.records(
                continuingMatchFrom: cursor,
                desiredKeys: listKeys,
                resultsLimit: pageLimit
            )
        } else {
            do {
                let query = CKQuery(recordType: ScriptShare.recordType, predicate: predicate(mode: mode, search: search))
                query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                result = try await db.records(
                    matching: query,
                    desiredKeys: listKeys,
                    resultsLimit: pageLimit
                )
            } catch {
                // 类型/字段尚未创建（从未上传过、或新版字段还没有记录）：按空列表处理
                if Self.isMissingRecordType(error) || Self.isUnknownField(error) {
                    return ([], nil)
                }
                throw error
            }
        }
        let items = result.matchResults
            .compactMap { try? $0.1.get() }
            .compactMap(ScriptShare.init(record:))
        return (items, result.queryCursor)
    }

    private func predicate(mode: ScriptData.Mode?, search: String) -> NSPredicate {
        var subs: [NSPredicate] = []
        if let mode {
            subs.append(NSPredicate(format: "mode == %@", mode.rawValue))
        }
        let keyword = search.trimmingCharacters(in: .whitespaces)
        if !keyword.isEmpty {
            subs.append(NSPredicate(
                format: "name CONTAINS[c] %@ OR summary CONTAINS[c] %@ OR ANY tags CONTAINS[c] %@",
                keyword, keyword, keyword
            ))
        }
        switch subs.count {
        case 0: return NSPredicate(value: true)
        case 1: return subs[0]
        default: return NSCompoundPredicate(andPredicateWithSubpredicates: subs)
        }
    }

    // MARK: 我的上传

    func mine() async throws -> [ScriptShare] {
        let userID = try await NCONFIG.container.userRecordID().recordName
        do {
            return try await ScriptShare.query(
                NSPredicate(format: "ownerId == %@", userID),
                limit: uploadLimit,
                from: NCONFIG.publicCloudDatabase
            )
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        } catch {
            if Self.isMissingRecordType(error) || Self.isUnknownField(error) { return [] }
            throw error
        }
    }

    func delete(_ share: ScriptShare) async throws {
        try await share.delete(from: NCONFIG.publicCloudDatabase)
    }

    // MARK: 详情

    func detail(id: String) async throws -> ScriptShare {
        let record = try await NCONFIG.publicCloudDatabase.record(for: CKRecord.ID(recordName: id))
        guard let share = ScriptShare(record: record), share.source != nil else {
            throw ScriptMarketError.notFound
        }
        return share
    }

    // MARK: 上传

    @discardableResult
    func upload(
        local: ScriptData,
        displayName: String,
        summary: String,
        tags: [String]
    ) async throws -> ScriptShare {
        let (available, message) = await NCONFIG.checkAccount()
        guard available else { throw ScriptMarketError.account(message) }

        let source = try String(contentsOf: local.file, encoding: .utf8)
        let validation = await JSRuntime.validate(source, args: local.mode.args)
        guard validation.ok else {
            throw ScriptMarketError.invalidScript(validation.message)
        }

        let sourceHash = source.sha256()
        do {
            let duplicated = try await ScriptShare.query(
                NSPredicate(format: "sha256 == %@", sourceHash),
                limit: 1,
                from: NCONFIG.publicCloudDatabase
            )
            if !duplicated.isEmpty {
                throw ScriptMarketError.duplicate
            }
        } catch let error as ScriptMarketError {
            throw error
        } catch {
            // 首次上传时类型/字段还没创建，查询会报错，此时必然无重复
            if !Self.isMissingRecordType(error), !Self.isUnknownField(error) {
                throw ScriptMarketError.save(error.localizedDescription)
            }
        }

        let owned = try await mine()
        guard owned.count < uploadLimit else { throw ScriptMarketError.quota }

        let author = Defaults[.member].name
        let ownerId: String
        do {
            ownerId = try await NCONFIG.container.userRecordID().recordName
        } catch {
            throw ScriptMarketError.save(error.localizedDescription)
        }
        let share = ScriptShare(
            name: displayName,
            summary: summary,
            mode: local.mode.rawValue,
            tags: tags,
            size: source.utf8.count,
            sha256: sourceHash,
            authorName: author.isEmpty ? String(localized: "匿名用户") : author,
            ownerId: ownerId,
            file: local.file
        )
        do {
            return try await share.save(to: NCONFIG.publicCloudDatabase, mergeExisting: false) ?? share
        } catch {
            throw ScriptMarketError.save(error.localizedDescription)
        }
    }

    // MARK: 安装

    /// 下载源码经校验后入库；本地已有相同 sha256 内容抛 alreadyInstalled。
    @discardableResult
    func install(_ share: ScriptShare) async throws -> ScriptData {
        guard let source = share.source,
              let mode = ScriptData.Mode(rawValue: share.mode)
        else { throw ScriptMarketError.notFound }

        if Defaults[.scripts].contains(where: { $0.id == share.sha256 }) {
            throw ScriptMarketError.alreadyInstalled
        }

        let validation = await JSRuntime.validate(source, args: mode.args)
        guard validation.ok else {
            throw ScriptMarketError.invalidScript(validation.message)
        }

        let data = try ScriptData(name: uniqueFileName(for: share.name), content: source, mode: mode)
        Defaults[.scripts].insert(data)
        return data
    }

    /// 本地文件名全局唯一（不分模式），统一补 .js，重名追加 -2/-3
    private func uniqueFileName(for suggested: String) -> String {
        var base = suggested.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty { base = "script" }
        let illegal = CharacterSet(charactersIn: "/\\:")
        base = base.components(separatedBy: illegal).joined(separator: "_")
        if !base.hasSuffix(".js") { base += ".js" }

        let existing = Set(Defaults[.scripts].map(\.name))
        if !existing.contains(base) { return base }
        let stem = String(base.dropLast(3))
        var n = 2
        while existing.contains("\(stem)-\(n).js") { n += 1 }
        return "\(stem)-\(n).js"
    }
}
