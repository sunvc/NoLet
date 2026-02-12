//
//  Encodable+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//

import SwiftUI

extension Encodable {
    func toEncodableDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any] else { return nil }
        return dictionary
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func toStringDict(excluding keysToExclude: [String] = []) -> [String: String] {
        var result: [String: String] = [:]
        for (keyAny, valueAny) in self {
            guard let key = keyAny as? String, !keysToExclude.contains(key) else { continue }

            let strValue: String
            switch valueAny {
            case let v as String: strValue = v
            case let v as CustomStringConvertible: strValue = v.description
            default: strValue = String(describing: valueAny)
            }

            result[key] = strValue
        }
        return result
    }

    func toJSONString(excluding keysToExclude: [String] = []) -> String? {
        let stringDict = toStringDict(excluding: keysToExclude)
        guard stringDict.count > 0 else { return nil }

        guard JSONSerialization.isValidJSONObject(stringDict),
              let data = try? JSONSerialization.data(
                  withJSONObject: stringDict,
                  options: [.prettyPrinted]
              )
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
