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
    @ObservedObject private var manager = AppManager.shared

    @Default(.autoSaveToAlbum) var autoSaveToAlbum

    @Default(.defaultBrowser) var defaultBrowser
    @Default(.muteSetting) var muteSetting
    @Default(.feedbackSound) var feedbackSound
    @Default(.usePtt) var usePtt
    @Default(.background) var background
    @Default(.customColor) private var customColor
    @Default(.locPer) private var locPer
    

    var body: some View {
        List {
            // FIXME: - 修复MAC不能使用PushToTalk崩溃
            if !.isiOSAppOnMac {
                
               
                Section {
                    
                    Toggle(isOn: $usePtt) {
                        Label {
                            Text(verbatim: "PTT")
                        } icon: {
                            Image(systemName: "message.badge.waveform")
                                .foregroundStyle(
                                    usePtt ? Color.accentColor : Color.red,
                                    Color.primary
                                )
                        }
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
                        manager.router = [.more, .noletChatSetting(nil)]
                        return true
                    }.id("noletchatsettings")
                    
                } header: {
                    Text("附加功能")
                        .bold()
                        .font(.footnote)
                }
            }
            
            LocationStatusView()

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
                Picker(selection: $background) {
                    ForEach(ContentBackgroundStyle.allCases, id: \.self) { item in
                        Text(item.name)
                            .tag(item)
                    }
                } label: {
                    Label {
                        Text("选择样式")
                    } icon: {
                        Image(systemName: "paintpalette")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.mint)
                            .scaleEffect(0.9)
                    }
                }
                if background == .custom {
                    ForEach($customColor) { $stop in
                        ColorPicker(selection: Binding(
                            get: { stop.color },
                            set: { stop.color = $0 }
                        )) {
                            Label {
                                Text("颜色")
                            } icon: {
                                Image(systemName: "\((customColor.firstIndex(of: stop) ?? 0) + 1).circle")
                            }
                        }
                    }
                    .onDelete { customColor.remove(atOffsets: $0) }
                    Button {
                        customColor.append(.init(color: .accentColor))
                    } label: {
                        Label("添加颜色", systemImage: "plus.circle")
                    }
                    .disabled(customColor.count >= 6)
                }

            } header: {
                Text("全局背景样式")
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
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle("更多设置")
    }
}

extension DefaultBrowserModel {
    var title: String {
        switch self {
        case .auto: String(localized: "自动")
        case .safari: "Safari"
        case .app: String(localized: "内部")
        }
    }
}

#Preview {
    NavigationStack {
        MoreOperationsView()
    }
}
