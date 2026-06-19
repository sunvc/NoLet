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
    @ObservedObject private var manager = AppManager.shared

    @Default(.appIcon) var setting_active_app_icon

    @Default(.sound) var sound
    @Default(.servers) var servers
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.usePtt) var usePtt

    @State private var webShow: Bool = false
    @State private var showLoading: Bool = false
    @State private var showPaywall: Bool = false
    @State private var buildDetail: Bool = false

    var serverTypeColor: Color {
        let right = servers.filter { $0.status > 0 }.count
        let left = servers.filter { $0.status == 0 }.count

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

                    if usePtt {
                        ListButton {
                            Label("语音", systemImage: "message.and.waveform")
                        } action: {
                            Task { @MainActor in
                                manager.router = [.ptt]
                            }
                            return true
                        }.id("messageVoice")
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
                        Text("铃声设置")
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
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
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
    }
}
