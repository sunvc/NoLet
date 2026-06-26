//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - MemberModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/24 12:45.

import CloudKit
import SwiftUI

struct MemberModel: Codable, Hashable, Equatable {
    var id: String
    var name: String
    var token: String
    var avatar: UIImage?
    var newAvatar: URL? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case token
    }
}

extension MemberModel {
    static let recordType = "Member"

    init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let token = record["token"] as? String
        else {
            return nil
        }

        self.id = record.recordID.recordName
        self.name = name
        self.token = token

        if let asset = record["avatar"] as? CKAsset,
           let fileURL = asset.fileURL,
           let data = try? Data(contentsOf: fileURL)
        {
            self.avatar = UIImage(data: data)
        } else {
            self.avatar = nil
        }
    }
}
