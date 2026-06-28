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

import Defaults
import Foundation

nonisolated struct TokensModel: Codable {
    var token: String = ""
    var talk: String = ""
    var voip: String = ""
    var location: String = ""
}

nonisolated extension TokensModel: Defaults.Serializable {}

nonisolated extension Defaults.Keys {
    static let token = Key<TokensModel>("TokensModelTokens", TokensModel())
}
