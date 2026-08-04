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

import CryptoKit
import Foundation
import UIKit
import UniformTypeIdentifiers

nonisolated extension Encodable {
    func toEncodableDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any] else { return nil }
        return dictionary
    }
}

nonisolated extension UTType {
    static let trnExportType = UTType(exportedAs: "me.uuneo.nolet.exv")
}

nonisolated extension Dictionary {
    static func + (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs) { _, new in new }
    }

    static func += (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs) { _, new in new }
    }
}

nonisolated extension Dictionary where Key == String, Value == String {
    func text() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

nonisolated extension Dictionary where Key == AnyHashable, Value == Any {
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

// MARK: -  keyPath+.swift

nonisolated func == <T, Value: Equatable>(keyPath: KeyPath<T, Value>, value: Value) -> (T) -> Bool {
    { $0[keyPath: keyPath] == value }
}

// data+
nonisolated extension Data {
    func sha256() -> String {
        return SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }

    nonisolated func toThumbnail(max: Int = 300) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max,
        ]

        if let source = CGImageSourceCreateWithData(self as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}

nonisolated extension Array where Element: Hashable {
    func uniqued<Value: Hashable>(
        by keyPath: KeyPath<Element, Value>,
        _ data: Element? = nil
    ) -> [Element] {
        var seen = Set<Value>()
        var result = filter { seen.insert($0[keyPath: keyPath]).inserted }
        if let data { result.insert(data, at: 0) }
        return result
    }
}
