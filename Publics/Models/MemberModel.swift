//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - TokensModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/27 23:01.

import CloudKit
import Defaults
import Foundation
import SwiftUI

nonisolated struct MemberModel: Codable, Hashable, Equatable, Sendable {
    var id: String
    var name: String = ""
    var token: String = ""
    var talk: String = ""
    var voip: String = ""
    var location: String = ""
    var avatar: UIImage?
    var newAvatar: URL? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case token
        case location
        case talk
        case voip
    }
}

nonisolated extension MemberModel: CloudKitConvertible {
    static let recordType = "Member"

    static var skippedKeys: Set<String> { ["avatar", "newAvatar"] }

    init?(record: CKRecord) {
        let name = (record["name"] as? String) ?? ""
        let token = (record["token"] as? String) ?? ""
        let locationToken = (record["location"] as? String) ?? ""
        let talk = (record["talk"] as? String) ?? ""
        let voip = (record["voip"] as? String) ?? ""

        self.id = record.recordID.recordName
        self.name = name
        self.token = token
        self.location = locationToken
        self.talk = talk
        self.voip = voip

        if let asset = record["avatar"] as? CKAsset,
           let fileURL = asset.fileURL,
           let data = try? Data(contentsOf: fileURL)
        {
            self.avatar = UIImage(data: data)
        } else {
            self.avatar = nil
        }
    }

    /// 覆写以桥接 `newAvatar` → `"avatar"` 键，并保持"空字符串不覆盖旧值"的合并语义。
    func toRecord(existing: CKRecord? = nil, clearNilFields: Bool = false) -> CKRecord {
        let record = toRecordViaReflection(existing: existing, clearNilFields: clearNilFields)

        if name.isEmpty { record["name"] = existing?["name"] }
        if token.isEmpty { record["token"] = existing?["token"] }
        if location.isEmpty { record["location"] = existing?["location"] }
        if talk.isEmpty { record["talk"] = existing?["talk"] }
        if voip.isEmpty { record["voip"] = existing?["voip"] }

        if let avatarUrl = newAvatar {
            record["avatar"] = CKAsset(fileURL: avatarUrl)
        }
        return record
    }
}


//nonisolated extension TokensModel: Defaults.Serializable {}
nonisolated extension MemberModel: Defaults.Serializable {}

nonisolated extension Defaults.Keys {
    static let member = Key<MemberModel>("MemberModel", MemberModel(id: IDManager.id))
}
