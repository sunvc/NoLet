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
         aps, alert, caf

    var name: String { rawValue.lowercased() }
}

extension [Params] {
    func allString() -> [String] {
        compactMap { param in
            param.name
        }
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func raw<T>(_ params: Params, nesting: Bool = true) -> T? {
        let value = raw(params, nesting: nesting)

        switch T.self {
        case is String.Type:
            // 字符串类型转换
            if let s = value as? String {
                return s as? T
            } else if let n = value as? Int {
                return String(n) as? T
            } else if let b = value as? Bool {
                return String(b) as? T
            } else {
                return value as? T
            }

        case is Int.Type:
            // 整数类型转换
            if let n = value as? Int {
                return n as? T
            } else if let data = value as? String, let intValue = Int(data) {
                return intValue as? T
            } else {
                return value as? T
            }

        case is Bool.Type:
            // 布尔类型转换
            if let b = value as? Bool {
                return b as? T
            } else if let data = value as? Int {
                return (data > 0) as? T
            } else if let data = value as? String {
                // 支持更多布尔值字符串格式
                let lowercased = data.lowercased()
                if ["true", "y", "yes", "1"].contains(lowercased) {
                    return true as? T
                } else if ["false", "n", "no", "0"].contains(lowercased) {
                    return false as? T
                }
            }
            return value as? T

        default:
            return value as? T
        }
    }

    private func raw(_ params: Params, nesting: Bool = true) -> Any? {
        switch params {
        case .title, .subtitle, .body:
            if nesting {
                let alert =
                    (self[Params.aps.name] as? [String: Any])?[Params.alert.name] as? [String: Any]
                return alert?[params.name]
            } else {
                return self[params.name]
            }

        case .sound:
            if nesting {
                return (self[Params.aps.name] as? [AnyHashable: Any])?[Params.sound.name]
            } else {
                return self[params.name]
            }

        default:
            return self[params.name]
        }
    }

    func other() -> Self {
        filter { key, _ in
            guard let keyStr = key as? String else { return true }
            return !Params.allCases.contains { $0.name == keyStr }
        }
    }
}
