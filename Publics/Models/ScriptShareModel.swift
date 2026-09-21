//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptShareModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 插件中心：用户上传到 CloudKit 公共库的 JS 脚本

//  History:
//    Created by Neo on 2026/9/9.

import CloudKit
import Foundation

struct ScriptShare: Identifiable {
    var id: String = UUID().uuidString
    /// 脚本显示名（不要求全局唯一，安装时本地重名自动改名）
    var name: String
    var summary: String
    /// ScriptData.Mode 的 rawValue：tts / processor / action / plugin
    var mode: String
    var tags: [String]
    /// 源文字节数
    var size: Int
    /// 源码 sha256，用于本地去重
    var sha256: String
    /// 上传时的作者名快照（Defaults[.member].name）
    var authorName: String
    /// 上传者的 iCloud userRecordID.recordName，用于「我的上传」过滤
    /// （不用元数据 creatorUserRecordID，避免要求手动建元数据索引）
    var ownerId: String
    /// 本地 .js 文件，仅上传时使用；反射桥接为 "data" CKAsset
    var file: URL? = nil
    /// 详情拉取后读出的源码（不参与反射）
    var source: String? = nil
    /// record.creationDate（不参与反射）
    var createdAt: Date? = nil
}

extension ScriptShare: CloudKitConvertible {
    static let recordType = "ScriptShare"

    static var skippedKeys: Set<String> { ["source", "createdAt"] }

    init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let mode = record["mode"] as? String,
              let size = record["size"] as? Int,
              let sha256 = record["sha256"] as? String
        else { return nil }
        id = record.recordID.recordName
        self.name = name
        self.mode = mode
        self.size = size
        self.sha256 = sha256
        summary = (record["summary"] as? String) ?? ""
        tags = (record["tags"] as? [String]) ?? []
        authorName = (record["authorName"] as? String) ?? ""
        ownerId = (record["ownerId"] as? String) ?? ""
        createdAt = record.creationDate
        // 列表查询用 desiredKeys 排除了 data，asset 缺失属正常；详情拉全量才有源码
        if let asset = record["data"] as? CKAsset,
           let fileURL = asset.fileURL,
           let source = try? String(contentsOf: fileURL, encoding: .utf8)
        {
            self.source = source
            self.file = fileURL
        }
    }

    /// 桥接：`file` (URL) → CKRecord 的 `"data"` (CKAsset)，同 PushIcon。
    func toRecord(existing: CKRecord? = nil, clearNilFields: Bool = false) -> CKRecord {
        let record = toRecordViaReflection(existing: existing, clearNilFields: clearNilFields)
        if let file {
            record["data"] = CKAsset(fileURL: file)
        }
        record["file"] = nil
        // 空数组无法让 CloudKit 推断 List 元素类型（首次建字段会报错），缺省即可，
        // init?(record:) 读取时把缺失字段还原为空数组。
        if tags.isEmpty {
            record["tags"] = nil
        }
        return record
    }
}

enum ScriptMarketError: LocalizedError {
    case account(String)
    case invalidScript(String?)
    case quota
    case duplicate
    case notFound
    case alreadyInstalled
    case save(String)

    var errorDescription: String? {
        switch self {
        case .account(let message): message
        case .invalidScript(let message):
            String(localized: "脚本校验未通过") + (message.map { "：\($0)" } ?? "")
        case .quota: String(localized: "上传数量已达上限（50 个）")
        case .duplicate: String(localized: "相同内容的脚本已存在，无需重复上传")
        case .notFound: String(localized: "云端脚本不存在或已被作者删除")
        case .alreadyInstalled: String(localized: "相同内容的脚本已安装")
        case .save(let message): message
        }
    }
}
