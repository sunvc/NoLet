//
//  WatchCache.swift
//  Welet Watch App
//
//  UserDefaults.standard 上的轻量 JSON 缓存:
//  手表与手机不共享 App Group,这里仅用于本设备离线时先渲染上次数据。
//

import Foundation

enum WatchCache {
    private static let defaults = UserDefaults.standard

    enum Key {
        static let messages = "welet.cache.messages"
        static let servers = "welet.cache.servers"
        static let crypto = "welet.cache.crypto"
        static let deviceToken = "welet.deviceToken"
        static let deviceUUID = "welet.deviceUUID"
    }

    static func load<T: Decodable>(_ key: String, as type: T.Type = T.self) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    static var deviceUUID: String {
        if let uuid = defaults.string(forKey: Key.deviceUUID), !uuid.isEmpty {
            return uuid
        }
        let uuid = UUID().uuidString
        defaults.set(uuid, forKey: Key.deviceUUID)
        return uuid
    }

    static var deviceToken: String? {
        get { defaults.string(forKey: Key.deviceToken) }
        set { defaults.set(newValue, forKey: Key.deviceToken) }
    }
}
