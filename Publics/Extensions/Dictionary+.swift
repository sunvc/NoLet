//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - Dictionary+.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/2 17:09.

import Foundation

extension Dictionary {
    static func + (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs) { _, new in new }
    }

    static func += (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs) { _, new in new }
    }
}

extension Dictionary where Key == String, Value == String {
    func text() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

