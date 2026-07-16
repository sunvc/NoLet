//
//  PermissionsStartView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import CoreTelephony
import Defaults
import SwiftUI

/// 权限选项模型
struct PermissionOption: Identifiable, Equatable {
    var id = UUID()
    var mode: PermissionType
    var title: String
    var description: String
    var iconName: String
    var isSelected: Bool = false
    var isRequired: Bool = false // 是否为必选项

    enum PermissionType: Int {
        case base
        case critical
        case network
        case server
    }
}

// 权限设置步骤枚举
enum PermissionStep {
    case networkPermission // 第一步：网络权限
    case otherPermissions // 第二步：其他权限
}

struct PermissionsStartView: View {
    @State private var networkPer = PermissionOption(
        mode: .network,
        title: String(localized: "网络权限"),
        description: String(localized: "允许应用通过网络接收推送通知"),
        iconName: "network",
        isSelected: false,
        isRequired: true
    )

    @State private var basePer = PermissionOption(
        mode: .base,
        title: String(localized: "普通通知权限"),
        description: String(localized: "一般性的应用通知提醒"),
        iconName: "bell",
        isSelected: false,
        isRequired: true
    )

    @State private var criticalPer = PermissionOption(
        mode: .critical,
        title: String(localized: "重要通知权限"),
        description: String(localized: "高穿透性通知提醒"),
        iconName: "bell.badge"
    )

    @State private var serverPer = PermissionOption(
        mode: .server,
        title: String(localized: "使用官方服务器"),
        description: String(localized: "是否使用官方服务器"),
        iconName: "server.rack",
        isSelected: true
    )

    @State private var voicePer = PermissionOption(
        mode: .server,
        title: String(localized: "语音对讲"),
        description: String(localized: "是否开启语音对讲服务"),
        iconName: "message.and.waveform",
        isSelected: false
    )

    @State private var currentStep: PermissionStep = .networkPermission // 当前权限设置步骤
    @State private var showNextScreen: Bool = false
    @State private var showAlert: Bool = false // 显示警告提示
    @State private var alertMessage: String = "" // 警告提示信息
    @State private var alertTitle: String = "" // 警告提示标题
    @State private var customServerAddress: String = "" // 自定义服务器地址
    @State private var urlValidationError: Bool = false // URL验证错误标志
    @ObservedObject private var appManager = AppManager.shared
    @Default(.usePtt) var usePtt

    var complete: (() -> Void)?

    // 获取当前使用的服务器地址
    private var currentServerURL: String {
        if !serverPer.isSelected && !appManager.customServerURL.isEmpty {
            return appManager.customServerURL
        } else {
            return NCONFIG.server
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // 顶部图标和标题
            VStack(spacing: 10) {
                Text("欢迎使用")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if currentStep == .networkPermission {
                    Text("请先授予网络权限")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("请选择您需要的其他权限")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 30)

            if currentStep == .networkPermission {
                // 第一步：只显示网络权限
                VStack(spacing: 12) {
                    Text("确认已开启网络权限")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    PermissionOptionCard(option: $networkPer)

                    // 网络权限说明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("为什么需要网络权限？")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text("网络权限是应用正常运行的基础，用于接收推送通知、同步数据和获取最新信息。没有网络权限，应用的核心功能将无法正常工作。")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.05))
                    )
                }
                .padding(.horizontal)
                // 服务器设置部分
                VStack(spacing: 12) {
                    Text("服务器设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 10) {
                        PermissionOptionCard(option: $serverPer)
                            .onChange(of: serverPer) { value in
                                if value.isSelected {
                                    self.customServerAddress = ""
                                }
                            }

                        // 自定义服务器地址输入框 - 仅在开启自定义服务器时显示
                        if !serverPer.isSelected {
                            HStack {
                                Image(systemName: "link")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 36, height: 36)
                                    .background {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                    }

                                TextField("请输入服务器地址", text: $customServerAddress)
                                    .font(.subheadline)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
            } else {
                // 第二步：显示其他权限选项
                VStack(spacing: 12) {
                    Text("通知权限设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 10) {
                        PermissionOptionCard(option: $basePer)
                        PermissionOptionCard(option: $criticalPer)
                            .onChange(of: criticalPer) { newValue in
                                if newValue.isSelected && !basePer.isSelected {
                                    self.basePer.isSelected = true
                                }
                            }
                        if !ProcessInfo.processInfo.isiOSAppOnMac {
                            PermissionOptionCard(option: $voicePer)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }

            Spacer()

            // 底部按钮区域
            VStack(spacing: 15) {
                if currentStep == .networkPermission {
                    // 第一步：继续按钮
                    Button {
                        guard networkPer.isSelected else {
                            // 网络权限未选择，显示警告
                            alertTitle = String(localized: "需要网络权限")
                            alertMessage = String(localized: "网络权限是应用正常运行的基础，请授予网络权限以继续。")
                            showAlert = true
                            return
                        }
                        // 检查如果开启了自定义服务器，需要验证URL
                        if !serverPer.isSelected {
                            Task { @MainActor in
                                let customServer = customServerAddress.normalizedURLString()

                                if customServer.count > 10 {
                                    if await NetworkManager().health(url: customServer) {
                                        appManager.customServerURL = customServerAddress
                                        withAnimation {
                                            self.currentStep = .otherPermissions
                                        }
                                        return
                                    }
                                }
                                // URL无效，显示警告
                                self.alertTitle = String(localized: "服务器地址无效")
                                self
                                    .alertMessage =
                                    String(
                                        localized: "请输入有效的服务器URL地址，例如：https://example.com"
                                    )
                                self.showAlert = true
                                self.urlValidationError = true
                            }

                        } else {
                            // 未开启自定义服务器，直接进入下一步
                            withAnimation {
                                currentStep = .otherPermissions
                            }
                        }
                    } label: {
                        Text("继续")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background {
                                Capsule()
                                    .fill(networkPer.isSelected ? Color.mint.gradient : Color
                                        .gray.gradient)
                            }
                    }
                } else {
                    // 第二步：完成按钮
                    Button {
                        if basePer.isSelected && networkPer.isSelected {
                            // 完成并进入下一个界面
                            withAnimation {
                                showNextScreen = true
                                complete?()
                            }
                        } else {
                            // 显示警告
                            alertTitle = String(localized: "必选权限未选择")
                            alertMessage =
                                String(
                                    localized: "普通通知权限为必选项。如果开启重要通知权限，所有权限将自动开启。请选择必要的权限以继续使用应用。"
                                )
                            showAlert = true
                        }
                        Defaults[.usePtt] = voicePer.isSelected
                    } label: {
                        Text("完成设置")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background {
                                Capsule()
                                    .fill(
                                        basePer.isSelected && networkPer.isSelected ? Color.mint
                                            .gradient :
                                            Color.gray.gradient
                                    )
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .opacity(showNextScreen ? 0 : 1)
        .animation(.easeInOut, value: showNextScreen)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定")) {
                    // 重置URL验证错误状态
                    if urlValidationError {
                        urlValidationError = false
                    }
                }
            )
        }
        .padding(.top, 70)
        .padding(.bottom, 30)
        .background(ContentBackgroundView())
    }

    /// 组件初始化
    init(complete: (() -> Void)? = nil) {
        self.complete = complete

        // 加载已保存的服务器地址
        if !serverPer.isSelected {
            _customServerAddress = State(initialValue: appManager.customServerURL)
        } else {
            _customServerAddress = State(initialValue: "")
        }

        // 设置默认的alert标题和消息
        _alertTitle = State(initialValue: String(localized: "需要网络权限"))
        _alertMessage = State(initialValue: String(localized: "网络权限是应用正常运行的基础，请授予网络权限以继续。"))
    }

    // 验证URL是否有效
    private static func isValidURL(_ urlString: String) -> Bool {
        // 如果URL为空，则无效
        if urlString.isEmpty {
            return false
        }
        // 检查URL格式是否有效
        if let url = URL(string: urlString) {
            // 确保URL有scheme和host
            return url.scheme != nil && url.host != nil
        }

        return urlString.hasHttp
    }
}

/// 权限选项卡片视图 - Toggle风格
struct PermissionOptionCard: View {
    @Binding var option: PermissionOption

    var body: some View {
        HStack(spacing: 15) {
            // 图标
            Image(systemName: option.iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                }

            // 文本内容
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(option.title)
                        .font(.headline)

                    if option.isRequired {
                        Text("(必选)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text(option.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Toggle开关

            Toggle(isOn: Binding(
                get: { option.isSelected },
                set: { newValue in
                    // 如果是必选项且已选中，则不允许取消选择
                    if !(option.isRequired && option.isSelected && !newValue) {
                        option.isSelected = newValue
                    }
                }
            )) {}
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .labelsHidden()
                .onChange(of: option.isSelected) { newValue in
                    if newValue {
                        Task {
                            switch option.mode {
                            case .base:
                                _ = await AppManager.shared.registerForRemoteNotifications()
                            case .critical:
                                _ = await AppManager.shared.registerForRemoteNotifications(true)
                            case .network:
                                let success = await NetworkManager().test()
                                if !success {
                                    option.isSelected = false
                                }
                            case .server:
                                break
                            }
                        }
                    }
                }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .glassCard()
    }
}

#Preview {
    ContentView()
        .sheet(isPresented: .constant(true)) {
            PermissionsStartView()
                .presentationDetents([.large])
                .customPresentationCornerRadius(30)
        }
}
