//
//  WatchAppDelegate.swift
//  Welet Watch App
//
//  APNs 注册、CloudKit 订阅静默推送分流、业务推送解密后上云。
//  watchOS 没有 Notification Service Extension:App 未运行时加密推送只能原样展示,
//  明文主路径是手机扩展解密 → CloudMessage → 手表同步。
//

import CloudKit
import OSLog
import SwiftUI
import UserNotifications
import WatchKit

@MainActor
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationDidFinishLaunching(_: Notification) {
        Task {
            await purgeDeprecatedCryptoOnce()
            await ensureSubscriptions()
            await requestNotificationsAndRegister()
            await WatchRegistration.shared.registerAll()
        }
    }

    /// 早期测试版本曾把加密密钥写入私有库,启动时清理一次(与手机端同逻辑)。
    private func purgeDeprecatedCryptoOnce() async {
        let key = "welet.cloudCryptoPurgeDone"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        if await CloudKitStore.shared.purgeDeprecatedCryptoRecords() {
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        WatchCache.deviceToken = token
        Task { await WatchRegistration.shared.registerAll() }
    }

    func didFailToRegisterForRemoteNotifications(withDeviceTokenError error: Error) {
        CloudSchema.cloudLog.error("watch APNs register failed: \(error as NSError)")
    }

    /// CloudKit 私有库订阅静默推送 → 对应 Store 刷新。
    func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any]
    ) async -> WKBackgroundFetchResult {
        let subscriptionID = CloudKitStore.subscriptionID(in: userInfo)
        switch subscriptionID {
        case CloudSchema.SubscriptionID.messageChanges:
            await WatchMessageStore.shared.refresh()
        case .some:
            // 其它 CloudKit 订阅(如早期版本注册的服务器订阅)无需处理
            break
        case nil:
            // 业务推送:解密后上云,让两端都能看到
            await Self.uploadIncoming(userInfo)
        }
        return .newData
    }

    // MARK: -

    private func ensureSubscriptions() async {
        try? await CloudKitStore.shared.ensureSubscription(
            recordType: CloudSchema.RecordType.message,
            subscriptionID: CloudSchema.SubscriptionID.messageChanges
        )
    }

    private func requestNotificationsAndRegister() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        WKExtension.shared().registerForRemoteNotifications()
    }

    /// 业务推送 → (可选解密) → CloudMessage 上云。与扩展同规则:
    /// 解密后的 title/subtitle/body 同时写 aps.alert 和顶层键。
    fileprivate static func uploadIncoming(_ userInfo: [AnyHashable: Any]) async {
        let merged: [AnyHashable: Any]

        if userInfo[Params.cipherText.name] != nil {
            let configs = WatchCryptoStore.shared.configs
            guard let map = WatchCrypto.decryptUserInfo(userInfo, configs: configs) else { return }
            var copy = userInfo
            var alert: [AnyHashable: Any] = [:]
            if let title = map[Params.title.name] { alert[Params.title.name] = title }
            if let subtitle = map[Params.subtitle.name] { alert[Params.subtitle.name] = subtitle }
            if let body = map[Params.body.name] { alert[Params.body.name] = body }
            if !alert.isEmpty { copy[Params.aps.name] = [Params.alert.name: alert] }
            for (key, value) in map { copy[key] = value }
            merged = copy
        } else {
            merged = userInfo
        }

        guard let message = CloudMessage(json: merged, source: "watch") else { return }
        await CloudKitStore.shared.saveMessages([message])
        await WatchMessageStore.shared.refresh()
    }
}

extension WatchAppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await Self.uploadIncoming(notification.request.content.userInfo)
        return [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await Self.uploadIncoming(response.notification.request.content.userInfo)
    }
}
