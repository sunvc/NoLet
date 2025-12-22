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

struct PushIcon: Identifiable {
    var id: String
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

    init(
        id: String = UUID().uuidString,
        name: String,
        description: [String],
        size: Int,
        sha256: String,
        file: URL? = nil,
        previewImage: UIImage? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.size = size
        self.sha256 = sha256
        self.file = file
        self.previewImage = previewImage
    }

    init?(from record: CKRecord) {
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
