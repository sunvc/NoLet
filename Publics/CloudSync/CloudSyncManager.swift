//
//  CloudSyncManager.swift
//  NoLet
//
//  手机端 CloudKit 同步编排:
//  - drain 收到的新消息上传私有库;
//  - 首次回填最近 200 条本地消息;
//  - 增量拉取手表/其它设备上传的消息并入 Core Data;
//  - 订阅静默推送路由与云端消息保留策略。
//
//  注意:加密配置(含 AES 明文密钥)永不上云,仅留在本机 App Group。
//  早期测试版本曾写入 CloudCryptoConfig,启动时做一次性云端清理。
//
//  只由主 app target 编译(不共享给 watch / extensions)。
//

import CloudKit
import Defaults
import Foundation

extension Defaults.Keys {
    fileprivate static let cloudMessageBackfillDone = Key<Bool>("cloudMessageBackfillDone", false)
    fileprivate static let cloudLastMessagePull = Key<Double>("cloudLastMessagePull", 0)
    fileprivate static let cloudCryptoPurgeDone = Key<Bool>("cloudCryptoPurgeDone", false)
}

@MainActor
final class CloudSyncManager {
    static let shared = CloudSyncManager()

    private let store = CloudKitStore.shared
    private let messageDB = MessageDBManager.shared

    private var isBootstrapping = false

    private init() {}

    // MARK: - Lifecycle

    /// AppDelegate 启动时调用一次。
    func start() {
        Task {
            try? await store.ensureSubscription(
                recordType: CloudSchema.RecordType.message,
                subscriptionID: CloudSchema.SubscriptionID.messageChanges
            )
            await purgeCryptoOnce()
        }
    }

    /// 每次进前台调用(SceneDelegate),内部防重入。
    func bootstrapIfNeeded() async {
        guard !isBootstrapping else { return }
        isBootstrapping = true
        defer { isBootstrapping = false }

        if !Defaults[.cloudMessageBackfillDone] {
            await backfillMessagesOnce()
            Defaults[.cloudMessageBackfillDone] = true
        }
        await pullMessages()
        await store.enforceMessageRetention()
    }

    /// 静默推送订阅回调(AppDelegate.didReceiveRemoteNotification)。
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        if CloudKitStore.subscriptionID(in: userInfo) == CloudSchema.SubscriptionID.messageChanges {
            await pullMessages()
        }
    }

    // MARK: - Messages

    /// drain / 回填的消息 JSON 批量上云。确定性 recordName 保证重复调用幂等。
    func upload(messages items: [[AnyHashable: Any]]) async {
        let messages = items.compactMap { CloudMessage(json: $0, source: "phone") }
        guard !messages.isEmpty else { return }
        await store.saveMessages(messages)
        await store.enforceMessageRetention()
    }

    private func backfillMessagesOnce() async {
        let now = Int64(Date().timeIntervalSince1970)
        let recent = await messageDB.recentJSON(limit: 200).filter { dict in
            // 跳过本地已过期的消息
            if let ttl = (dict[.ttl] as? NSNumber)?.int64Value, ttl > 0, ttl <= now {
                return false
            }
            return true
        }
        await upload(messages: recent)
    }

    func pullMessages() async {
        let lastTimestamp = Defaults[.cloudLastMessagePull]
        let modifiedAfter = lastTimestamp > 0
            ? Date(timeIntervalSince1970: lastTimestamp)
            : nil

        let messages = await store.fetchMessages(limit: 200, modifiedAfter: modifiedAfter)
        if messages.isEmpty {
            if lastTimestamp == 0 {
                Defaults[.cloudLastMessagePull] = Date().timeIntervalSince1970
            }
            return
        }

        var changed = false
        for message in messages {
            if await messageDB.upsertCloudMessage(message) {
                changed = true
            }
        }
        if changed {
            NotificationCenter.default.post(name: .messageDBBulkDidChange, object: nil)
        }
        Defaults[.cloudLastMessagePull] = Date().timeIntervalSince1970
    }

    // MARK: - Deprecated crypto cleanup

    /// 删除测试期上传到私有库的明文密钥记录,只执行一次。
    private func purgeCryptoOnce() async {
        guard !Defaults[.cloudCryptoPurgeDone] else { return }
        if await store.purgeDeprecatedCryptoRecords() {
            Defaults[.cloudCryptoPurgeDone] = true
        }
    }
}
