//
//  File name:     DataStorageView.swift
//  NoLet
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://wzs.app
//  E-mail:        to@wzs.app
//

//  Description:

//  History:
//    Created by Neo on 2024/12/11.

import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct MoreOperationsView: View {
    @EnvironmentObject private var manager: AppManager

    @Default(.autoSaveToAlbum) var autoSaveToAlbum

    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.defaultBrowser) var defaultBrowser
    @Default(.muteSetting) var muteSetting
    @Default(.feedbackSound) var feedbackSound
    @Default(.limitMessageLine) var limitMessageLine

    var body: some View {
        List {
            Section {
                Toggle(isOn: $feedbackSound) {
                    Label {
                        Text("声音反馈")
                    } icon: {
                        Image(systemName: "iphone.homebutton.radiowaves.left.and.right.circle")
                            .foregroundStyle(
                                feedbackSound ? Color.accentColor : Color.red,
                                Color.primary
                            )
                    }
                }

                ListButton(leading: {
                    Label {
                        Text("删除静音分组")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "\(muteSetting.count).circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                    }
                }, trailing: {
                    Image(systemName: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.tint, Color.primary)
                }, showRight: true) {
                    Defaults[.muteSetting] = [:]
                    return true
                }
            } header: {
                Text("触感与反馈")
                    .bold()
                    .font(.footnote)
            }

            Section {
                Toggle(isOn: $autoSaveToAlbum) {
                    Label {
                        Text("自动保存")
                    } icon: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                autoSaveToAlbum ? Color.accentColor : Color.red,
                                Color.primary
                            )
                    }
                    .onChange(of: autoSaveToAlbum) { newValue in
                        if newValue {
                            Task { @MainActor in
                                let result = await ImageManager.requestAuthorization(for: .addOnly)

                                self.autoSaveToAlbum = result.0

                                Toast.shared.present(
                                    title: result.2,
                                    symbol: result.0 ? .success : .error
                                )
                            }
                        }
                    }
                }
            } header: {
                Text("媒体设置")
                    .bold()
                    .font(.footnote)
            }

            Section {
                Toggle(isOn: $showMessageAvatar) {
                    Label {
                        Text("显示图标")
                    } icon: {
                        Image(systemName: "camera.macro.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                showMessageAvatar ? Color.accentColor : Color.red,
                                Color.primary
                            )
                    }
                }

                Stepper(
                    value: $limitMessageLine,
                    in: 3...11,
                    step: 1
                ) {
                    Label(
                        "消息显示高度",
                        systemImage: "\(String(format: "%02d", limitMessageLine)).circle"
                    )
                    .onLongPressGesture {
                        limitMessageLine = 3
                    }
                }

            } header: {
                Text("消息卡片未分组时是否显示logo")
                    .bold()
                    .font(.footnote)
            } footer: {
                Text("是否收到消息自动保存图片")
                    .bold()
                    .font(.footnote)
            }

            Section {
                Picker(selection: Binding(get: {
                    defaultBrowser
                }, set: { value in
                    Haptic.impact()
                    defaultBrowser = value
                })) {
                    ForEach(DefaultBrowserModel.allCases, id: \.self) { item in
                        Text(item.title)
                            .tag(item)
                    }
                } label: {
                    Label {
                        Text("默认浏览器")
                    } icon: {
                        Image(systemName: "safari")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .scaleEffect(0.9)
                    }
                }

                ListButton {
                    Label {
                        Text("系统设置")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "gear.circle")

                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    Task { @MainActor in
                        AppManager.openSetting()
                    }
                    return true
                }
            }
        }
        .navigationTitle("更多设置")
    }
}

extension DefaultBrowserModel {
    var title: String {
        switch self {
        case .auto:
            String(localized: "自动")
        case .safari:
            "Safari"
        case .app:
            String(localized: "内部")
        }
    }
}

#Preview {
    NavigationStack {
        MoreOperationsView()
            .environmentObject(AppManager.shared)
    }
}
