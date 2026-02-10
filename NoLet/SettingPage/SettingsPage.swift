//
//  SettingsPage.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/8.
//

import Defaults
import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var manager: AppManager

    @Default(.appIcon) var setting_active_app_icon

    @Default(.sound) var sound
    @Default(.servers) var servers
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.noServerModel) var noServerModel

    @State private var webShow: Bool = false
    @State private var showLoading: Bool = false
    @State private var showPaywall: Bool = false
    @State private var buildDetail: Bool = false

    var serverTypeColor: Color {
        let right = servers.filter(\.status == true).count
        let left = servers.filter(\.status == false).count

        if right > 0 && left == 0 {
            return .green
        } else if left > 0 && right == 0 {
            return .red
        } else {
            return .orange
        }
    }

    // 定义一个 NumberFormatter
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    @State private var selectView: String? = "message"

    var body: some View {
        List(selection: $selectView) {
            if manager.sizeClass == .regular {
                Section {
                    if manager.prouter.count > 0 {
                        ListButton {
                            Label("消息", systemImage: "ellipsis.message")
                        } action: {
                            Task { @MainActor in
                                manager.router = []
                            }
                            return true
                        }.id("message")
                    }

                    if manager.prouter.first != .noletChat {
                        Section {
                            ListButton {
                                Label {
                                    Text("智能助手")
                                } icon: {
                                    Image("agent")
                                        .resizable()
                                        .scaledToFit()
                                        .customForegroundStyle(.accent, .primary)
                                }
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.green, .primary)

                            } action: {
                                Task { @MainActor in
                                    manager.router = [.noletChat]
                                }
                                return true
                            }.id("noletchat")
                        }
                    }
                } header: {
                    Text("主视图")
                }
            }

            Section(header: Text("App配置").textCase(.none)) {
                ZStack {
                    if noServerModel {
                        Toggle(isOn: $noServerModel) {
                            Label {
                                Text("无服务器模式")
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "apple.logo")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(Color.red)
                            }
                        }
                    } else {
                        ListButton {
                            Label {
                                Text("服务器")
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "externaldrive.badge.wifi")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(serverTypeColor, Color.primary)
                            }

                        } action: {
                            Task { @MainActor in
                                manager.router = [.server]
                            }
                            return true
                        }.id("servers")
                    }
                }
                .onChange(of: noServerModel) { _ in
                    if !noServerModel {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            manager.router = [.server]
                            Haptic.impact()
                        }
                    }
                }

                ListButton {
                    Label {
                        Text("云图标")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        ZStack {
                            Image(systemName: "icloud")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(Color.primary)
                            Image(systemName: "photo")
                                .scaleEffect(0.4)
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent)
                                .offset(y: 2)
                        }
                    }
                } action: {
                    Task { @MainActor in
                        manager.open(sheet: .cloudIcon)
                    }
                    return true
                }.id("icloudPng")

                ListButton {
                    Label {
                        Text("智能助手")
                    } icon: {
                        Image("agent")
                            .resizable()
                            .scaledToFit()
                            .customForegroundStyle(.accent, .primary)
                    }

                } action: {
                    Task { @MainActor in
                        manager.router = [.noletChatSetting(nil)]
                    }
                    return true
                }.id("noletchatsettings")

                ListButton {
                    Label {
                        Text("声音设置")
                    } icon: {
                        Image(systemName: "speaker.wave.2.circle")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } trailing: {
                    Text(sound)
                        .foregroundStyle(.gray)
                } action: {
                    Task { @MainActor in
                        manager.router = [.sound]
                    }
                    return true
                }.id("sounds")

                ListButton {
                    Label {
                        Text("算法配置")
                    } icon: {
                        Image(systemName: "key.viewfinder")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, Color.primary)
                            .scaleEffect(0.9)
                    }
                } action: {
                    Task { @MainActor in
                        manager.router = [.crypto]
                    }
                    return true
                }.id("cryptoview")

                ListButton {
                    Label {
                        Text("数据管理")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "archivebox.circle")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task { @MainActor in
                        manager.router = [.dataSetting]
                    }
                    return true
                }.id("datamanager")

                ListButton {
                    Label {
                        Text("更多设置")
                    } icon: {
                        Image(systemName: "gear.badge")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task { @MainActor in
                        manager.router = [.more]
                    }
                    return true
                }.id("moresettings")
            }

            Section {
                ListButton {
                    Label {
                        Text("关于\(NCONFIG.AppName)")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "exclamationmark.octagon")

                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task { @MainActor in
                        manager.router = [.about]
                    }
                    return true
                }.id("aboutsetting")

                if #available(iOS 17.0, *) {
                    ListButton {
                        if let vipInfo = manager.VipInfo, vipInfo.isVip {
                            Label {
                                Text("获取开发者支持")
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "questionmark.app.dashed")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(.accent, Color.primary)
                            }
                        } else {
                            Label {
                                Text("开发者支持计划")
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "creditcard.circle")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(.accent, Color.primary)
                            }
                        }
                    } action: {
                        if let vipInfo = manager.VipInfo, vipInfo.isVip {
                            AppManager.openURL(url: NCONFIG.telegram, .safari)
                        } else {
                            Task { @MainActor in
                                manager.open(sheet: .paywall)
                            }
                        }
                        return true
                    }.id("store")
                }

            } header: {
                Text("其他")
                    .textCase(.none)
            }
        }
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.open(full: .scan)
                    Haptic.impact()
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, Color.primary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(AppManager.shared)
    }
}
