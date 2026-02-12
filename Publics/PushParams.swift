//
//  PushParams.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/3/31.
//

import UserNotifications

enum Params: String, CaseIterable {
    case id, title, subtitle, body, from, host, group, url, category, level, ttl, markdown,
         sound, volume, badge, call,
         callback, autoCopy, copy,
         icon, image, saveAlbum,
         cipherText, cipherNumber, iv,
         aps, alert, caf,
         reply

    var name: String { rawValue.lowercased() }
    static var names: [String] { Self.allCases.compactMap { $0.name } }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    private var apsObj: [AnyHashable: Any]? {
        self[Params.aps.name] as? [AnyHashable: Any]
    }

    private var alertObj: [AnyHashable: Any]? {
        apsObj?[Params.alert.name] as? [AnyHashable: Any]
    }

    func raw<T: ValueConvertible>(_ params: Params) -> T? {
        var value: Any? {
            switch params {
            case .title, .subtitle, .body:
                return alertObj?[params.name]
            case .sound:
                return apsObj?[params.name]
            default:
                return self[params.name]
            }
        }
        return T.convert(from: value)
    }

    func other() -> Self {
        filter { key, _ in
            guard let keyStr = key as? String else { return true }
            return !Params.allCases.contains { $0.name == keyStr }
        }
    }
}

protocol ValueConvertible {
    static func convert(from value: Any?) -> Self?
}

extension String: ValueConvertible {
    static func convert(from value: Any?) -> String? {
        switch value {
        case let s as String:
            return s
        case let n as Int:
            return String(n)
        case let b as Bool:
            return String(b)
        default:
            return nil
        }
    }
}

extension Int: ValueConvertible {
    static func convert(from value: Any?) -> Int? {
        switch value {
        case let n as Int:
            return n
        case let s as String:
            return Int(s)
        case let b as Bool:
            return b ? 1 : 0
        default:
            return nil
        }
    }
}

extension Bool: ValueConvertible {
    static func convert(from value: Any?) -> Bool? {
        switch value {
        case let b as Bool:
            return b
        case let n as Int:
            return n > 0
        case let s as String:
            let lower = s.lowercased()
            if ["true", "y", "yes", "1"].contains(lower) {
                return true
            }
            return false
        default:
            return nil
        }
    }
}
