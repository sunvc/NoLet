//
//  WeletApp.swift
//  Welet Watch App
//
//  简化版 NoLet:消息列表 / 服务器列表 / 加密配置,
//  通过 CloudKit 私有库(iCloud.pushback)与手机双向同步。
//

import SwiftUI

@main
struct Welet_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    @StateObject private var messages = WatchMessageStore.shared
    @StateObject private var servers = WatchServerStore.shared
    @StateObject private var crypto = WatchCryptoStore.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                WatchMessageListView()
                    .environmentObject(messages)
                    .tabItem {
                        Label("消息", systemImage: "bell.fill")
                    }
                WatchServerListView()
                    .environmentObject(servers)
                    .tabItem {
                        Label("服务器", systemImage: "externaldrive.connectedToText.rectangle")
                    }
                WatchCryptoListView()
                    .environmentObject(crypto)
                    .tabItem {
                        Label("加密", systemImage: "lock.fill")
                    }
            }
        }
    }
}
