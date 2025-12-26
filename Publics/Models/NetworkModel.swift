//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - NetworkModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 21:37.
    

import Foundation

// MARK: - Remote Response
struct baseResponse<T>: Codable where T: Codable {
    var code: Int
    var message: String
    var data: T?
    var timestamp: Int?
}

struct DeviceInfo: Codable {
    var deviceKey: String
    var deviceToken: String
    var group: String?

    // 使用 `CodingKeys` 枚举来匹配 JSON 键和你的变量命名
    enum CodingKeys: String, CodingKey {
        case deviceKey = "key"
        case deviceToken = "token"
        case group
    }
}

enum requestHeader: String {
    case https = "https://"
    case http = "http://"
}
