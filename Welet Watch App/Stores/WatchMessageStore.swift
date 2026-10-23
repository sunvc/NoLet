//
//  WatchMessageStore.swift
//  Welet Watch App
//
//  CloudMessage 列表:启动先渲染本地缓存,再从私有库全量拉最近 200 条。
//  首次启动(或未登录 iCloud)时展示一批仅本机的示例消息,
//  拉到任意真实消息后示例消失;示例永不上云。
//

import CloudKit
import Combine
import SwiftUI

@MainActor
final class WatchMessageStore: ObservableObject {
    static let shared = WatchMessageStore()

    @Published var messages: [CloudMessage] = []
    @Published var isRefreshing = false
    @Published var iCloudReady: Bool = true

    private let store = CloudKitStore.shared
    private static let seededKey = "welet.cache.messagesSeeded"

    private init() {
        messages = WatchCache.load(WatchCache.Key.messages, as: [CloudMessage].self) ?? []
        seedSamplesIfNeeded()
        Task { await refresh() }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        iCloudReady = await store.isAccountAvailable()
        guard iCloudReady else { return }

        guard let fetched = await store.fetchMessagesResult(limit: 200) else { return }
        guard !fetched.isEmpty else { return }

        // 有真实消息后丢弃本机示例,避免混排
        messages = fetched
        WatchCache.save(fetched, key: WatchCache.Key.messages)
    }

    func markRead(_ message: CloudMessage) async {
        guard !message.read else { return }
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].read = true
        }
        WatchCache.save(messages, key: WatchCache.Key.messages)

        // 示例消息只存在本机,不上云
        guard message.source != Self.sampleSource else { return }
        var updated = message
        updated.read = true
        await store.saveMessages([updated])
    }

    // MARK: - Sample messages

    private static let sampleSource = "sample"

    private func seedSamplesIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.seededKey), messages.isEmpty else { return }

        let now = Int(Date().timeIntervalSince1970)
        let samples: [[AnyHashable: Any]] = [
            [
                Params.title.name: "服务器告警",
                Params.body.name: "CPU 使用率 92%,已持续 5 分钟",
                Params.group.name: "运维",
                Params.createDate.name: now - 5 * 60,
                Params.read.name: false,
            ],
            [
                Params.title.name: "部署通知",
                Params.body.name: "v2.3.0 已成功发布到生产环境",
                Params.group.name: "CI/CD",
                Params.createDate.name: now - 2 * 3600,
                Params.read.name: false,
            ],
            [
                Params.body.name: "每日备份已完成 ✅",
                Params.group.name: "系统",
                Params.createDate.name: now - 26 * 3600,
                Params.read.name: true,
            ],
        ]

        messages = samples
            .compactMap { CloudMessage(json: $0, source: Self.sampleSource) }
            .sorted { $0.createDate > $1.createDate }
        WatchCache.save(messages, key: WatchCache.Key.messages)
        defaults.set(true, forKey: Self.seededKey)
    }
}
