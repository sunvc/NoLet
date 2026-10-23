//
//  WatchCryptoStore.swift
//  Welet Watch App
//
//  加密配置仅保存在手表本地(UserDefaults),不上传 CloudKit:
//  私有库并非端到端加密,明文密钥上云会扩大泄漏面。
//

import Combine
import SwiftUI

@MainActor
final class WatchCryptoStore: ObservableObject {
    static let shared = WatchCryptoStore()

    @Published var configs: [WatchCryptoConfig] = []

    private init() {
        configs = WatchCache.load(WatchCache.Key.crypto, as: [WatchCryptoConfig].self) ?? []
    }

    func save(_ config: WatchCryptoConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        persist()
    }

    func remove(_ config: WatchCryptoConfig) {
        configs.removeAll { $0.id == config.id }
        persist()
    }

    private func persist() {
        WatchCache.save(configs, key: WatchCache.Key.crypto)
    }
}
