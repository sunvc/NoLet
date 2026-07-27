//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PushIconModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 18:03.
import CloudKit
import SwiftUI

nonisolated struct PushIcon: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var description: [String]
    var size: Int
    var sha256: String
    var file: URL? = nil
    var previewImage: UIImage? = nil
}

nonisolated extension PushIcon: CloudKitConvertible {
    // MARK: - CloudKitConvertible

    static let recordType = "PushIcon"

    static var skippedKeys: Set<String> { ["previewImage"] }

    init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let description = record["description"] as? [String],
              let asset = record["data"] as? CKAsset,
              let fileURL = asset.fileURL,
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData),
              let size = record["size"] as? Int,
              let sha256 = record["sha256"] as? String else { return nil }
        id = record.recordID.recordName
        self.name = name
        self.description = description
        self.size = size
        self.sha256 = sha256
        file = fileURL
        previewImage = image
    }

    /// 遗留调用点别名。
    init?(from record: CKRecord) { self.init(record: record) }

    /// 桥接：`file` (URL) → CKRecord 的 `"data"` (CKAsset) 字段。
    /// 反射会把 `file` 写入 `"file"` 键，这里手工修正。
    func toRecord(existing: CKRecord? = nil, clearNilFields: Bool = false) -> CKRecord {
        let record = toRecordViaReflection(existing: existing, clearNilFields: clearNilFields)
        if let file = file {
            record["data"] = CKAsset(fileURL: file)
        }
        record["file"] = nil
        return record
    }

    /// 遗留调用点入口：`file == nil` 时返回 nil（旧手写实现的语义）。
    func toRecord(recordType _: String) -> CKRecord? {
        guard file != nil else { return nil }
        return toRecord()
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
