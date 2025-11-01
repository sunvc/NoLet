    //
    //  File name:     DataStorageView.swift
    //  Author:        Copyright (c) 2024 QingHe. All rights reserved.
    //  Blog  :        https://uuneo.com
    //  E-mail:        to@uuneo.com
    //  Description:
    //  History:
    //  Created by uuneo on 2024/12/11.

import SwiftUI
import Defaults
import UniformTypeIdentifiers
import Photos

struct MoreOperationsView: View {
    @EnvironmentObject private var manager:AppManager



    @Default(.autoSaveToAlbum) var autoSaveToAlbum

    @Default(.badgeMode) var badgeMode
    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.defaultBrowser) var defaultBrowser
    @Default(.muteSetting) var muteSetting
    @Default(.feedbackSound) var feedbackSound
    @Default(.limitScanningArea) var limitScanningArea
    @Default(.limitMessageLine) var limitMessageLine


    var body: some View {
        List{
            
            
            Section{
                ListButton {
                    Label {
                        Text( "语音配置")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "speaker.zzz")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                    
                } action:{
                    Task{@MainActor in
                        manager.router = [.more, .tts]
                    }
                    return true
                }
                
                Toggle(isOn: $feedbackSound) {
                    Label("声音反馈", systemImage: "iphone.homebutton.radiowaves.left.and.right.circle")
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
            }header: {
                Text("声音设置")
            }

            Section{
             
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
                            .symbolEffect(.replace)
                    }

                }
                
                Stepper(
                    value: $limitMessageLine,
                    in: 3...50,
                    step: 1
                ) {
                    Label("消息显示高度", systemImage: "\(String(format: "%02d", limitMessageLine)).circle")
                        .onLongPressGesture {
                            limitMessageLine = 3
                        }
                }
              
                Picker(selection: $badgeMode) {
                    Text( "自动").tag(BadgeAutoMode.auto)
                    Text( "自定义").tag(BadgeAutoMode.custom)
                } label: {
                    Label {
                        Text( "角标模式")
                    } icon: {
                        Image(systemName: "app.badge")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .symbolEffect(.pulse, delay: 3)
                    }
                }
                .onChange(of: badgeMode) { newValue in
                    if newValue == .auto{
                        Task.detached {
                            let unRead =  MessagesManager.shared.unreadCount()
                            UNUserNotificationCenter.current().setBadgeCount( unRead )
                        }
                            
                        
                    }
                }
                
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
                }label:{
                    Label {
                        Text("默认浏览器")
                    } icon: {
                        Image(systemName: "safari")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .scaleEffect(0.9)
                    }
                    
                }
                
                Toggle(isOn: $limitScanningArea) {
                    Label("扫码区域限制", systemImage: "qrcode.viewfinder")
                }
                Toggle(isOn: $autoSaveToAlbum) {
                    Label("自动保存到相册", systemImage: "photo.on.rectangle.angled")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .onChange(of: autoSaveToAlbum) { newValue in
                            if newValue{
                                PHPhotoLibrary.requestAuthorization{status in
                                    switch status {
                                    case .notDetermined:
                                        self.autoSaveToAlbum = false
                                        Toast.info(title:"未选择权限")

                                    case .restricted, .limited:
                                        Toast.info(title: "有限的访问权限")

                                    case .denied:
                                        self.autoSaveToAlbum = false
                                        Toast.info(title: "拒绝了访问权限")

                                    case .authorized:
                                        Toast.success(title: "已授权访问照片库")

                                    @unknown default:
                                        break

                                    }
                                }
                            }
                        }

                }
            }header: {
                Text( "消息卡片未分组时是否显示logo")
                    .foregroundStyle(.gray)
            } footer:{
                Text( "是否收到消息自动保存图片")
                    .foregroundStyle(.gray)
            }

            Section{
                
                ListButton {
                    Label {
                        Text("小组件")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "window.shade.closed")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                    }
                } action:{
                    manager.router
                        .append(.widget(title: nil, data: "app"))
                    return true
                }
                
                ListButton {
                    Label {
                        Text( "系统设置")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "gear.circle")

                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                            .symbolEffect(.rotate)
                    }
                } action:{
                    Task{@MainActor in
                        AppManager.openSetting()
                    }
                    return true
                }
            } footer:{
                Text( "自动模式按照未读数，自定义按照推送badge参数")
                    .foregroundStyle(.gray)
            }

        }
        .navigationTitle("更多设置")
        .navigationBarTitleDisplayMode(.inline)

    }













}

#Preview {
    MoreOperationsView()
        .environmentObject(AppManager.shared)
}
