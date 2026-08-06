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
    case id, title, subtitle, body, group, url, category, level, ttl, markdown,
         sound, volume, badge, call, autoCopy, copy, saveAlbum, cipherText,
         cipherNumber, iv, aps, alert, caf, style, createDate, read, other,
         reply, icon, image, location, script

    var name: String { rawValue.lowercased() }
    static var names: [String] { allCases.prefix(27).compactMap { $0.name } }
}


extension Dictionary where Key == AnyHashable, Value == Any {
    subscript(key: Params) -> Any? {
        get { self[key.name] }
        set { self[key.name] = newValue }
    }

    private var apsObj: [AnyHashable: Any]? {
        self[.aps] as? [AnyHashable: Any]
    }

    private var alertObj: [AnyHashable: Any]? {
        apsObj?[.alert] as? [AnyHashable: Any]
    }

    func raw<T: ValueConvertible>(_ params: Params, as dataType: T.Type) -> T? {
        var value: Any? {
            switch params {
            case .title, .subtitle, .body:
                return alertObj?[params]
            case .sound:
                return apsObj?[params]
            default:
                return self[params]
            }
        }
        if let result = T.convert(from: value) {
            return result
        }
        return nil
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
        case let n as Int64:
            return String(n)
        case let b as Bool:
            return String(b)
        default:
            return nil
        }
    }
}

extension Int64: ValueConvertible {
    static func convert(from value: Any?) -> Int64? {
        switch value {
        case let n as Int64:
            return n
        case let s as String:
            return Int64(s)
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

        case let value as Bool:
            return value

        case let value as Int:
            switch value {
            case 1:
                return true
            case 0:
                return false
            default:
                return nil
            }
            
        case let value as String:
            switch value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() {

            case "true", "yes", "y", "1":
                return true

            case "false", "no", "n", "0":
                return false

            default:
                return nil
            }

        default:
            return nil
        }
    }
}
