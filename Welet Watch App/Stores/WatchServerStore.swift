//
//  WatchServerStore.swift
//  Welet Watch App
//
//  服务器仅保存在手表本地(UserDefaults),不走 CloudKit 同步。
//  用于手表直收推送时的 /register 注册和请求签名。
//

import Combine
import SwiftUI

@MainActor
final class WatchServerStore: ObservableObject {
    static let shared = WatchServerStore()

    @Published var servers: [PushServerModel] = []

    private init() {
        servers = WatchCache.load(WatchCache.Key.servers, as: [PushServerModel].self) ?? []
    }

    func save(_ server: PushServerModel) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
        }
        persist()
        Task { await WatchRegistration.shared.registrationsChanged() }
    }

    func remove(_ server: PushServerModel) {
        servers.removeAll { $0.id == server.id }
        persist()
    }

    /// key 留空添加服务器时,由 /register 响应回填服务端分配的 key。
    func updateKey(_ key: String, for id: String) {
        guard let index = servers.firstIndex(where: { $0.id == id }),
              servers[index].key.isEmpty
        else { return }
        servers[index].key = key
        persist()
    }

    private func persist() {
        WatchCache.save(servers, key: WatchCache.Key.servers)
    }
}
