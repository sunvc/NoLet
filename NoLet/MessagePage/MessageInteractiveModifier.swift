//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - MessageInteractiveModifier.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/18 16:31.

import SwiftUI

struct MessageInteractiveModifier: ViewModifier {
    let message: Message
    let namespace: Namespace.ID // 👈 用于 iOS 18 缩放动画

    @ObservedObject var manager: AppManager // 业务数据总管
    @Binding var replyText: String
    @FocusState.Binding var showReply: Bool
    @Binding var showSnap: Bool

    var onShowFull: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) {
                onShowFull()
            }
            .accessibilityAction(named: "显示全屏") {
                onShowFull()
            }
            .diff { view in
                Group {
                    if #available(iOS 18.0, *) {
                        view
                            .matchedTransitionSource(id: message.id, in: namespace)
                            .fullScreenCover(isPresented: Binding(
                                get: { manager.selectMessage?.id == message.id },
                                set: { if !$0 { manager.selectMessage = nil } }
                            )) {
                                SelectMessageView(message: message) {
                                    manager.selectMessage = nil
                                }
                                .navigationTransition(.zoom(sourceID: message.id, in: namespace))
                                .interactiveDismissDisabled(true)
                            }
                    } else {
                        view 
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let reply = message.reply {
                    TextField("回复", text: $replyText)
                        .customField(icon: "text.bubble")
                        .focused($showReply)
                        .opacity(showReply ? 1 : 0.0001)
                        .frame(height: showReply ? 50 : 1)
                        .keyboardType(.default)
                        .animation(.default, value: showReply)
                        .onSubmit(of: .text) {
                            sendReply(replyURL: reply)
                        }
                }
            }
            // 4. 动态消息截图
            .snapshot(trigger: showSnap) { item in
                manager.open(sheet: .share(
                    contents: [item],
                    preview: item,
                    title: String(localized: "消息截图")
                ))
            }
    }

    // 发送回复的网络封装
    private func sendReply(replyURL: String) {
        Task { @MainActor in
            do {
                let result = try await NetworkManager().fetch(url: replyURL + replyText)
                Toast.success(title: result.check() ? "回复成功" : "回复失败")
            } catch {
                Toast.shared.present(title: error.localizedDescription, symbol: .error)
            }
            self.replyText = ""
        }
    }
    
    func showFull() {
        manager.selectMessage = message
        Haptic.impact(.light)
    }
}

extension View {
    /// 一键注入消息的双击全屏、iOS 18 缩放动画、底部回复、卡片截图等交互矩阵
    func messageInteraction(
        message: Message,
        in namespace: Namespace.ID,
        manager: AppManager,
        replyText: Binding<String>,
        showReply: FocusState<Bool>.Binding, // 👈 专门适配 FocusState
        showSnap: Binding<Bool>,
        onShowFull: @escaping () -> Void
    ) -> some View {
        self.modifier(MessageInteractiveModifier(
            message: message,
            namespace: namespace,
            manager: manager,
            replyText: replyText,
            showReply: showReply,
            showSnap: showSnap,
            onShowFull: onShowFull
        ))
    }
}

struct MessageActionMenu: View {
    let message: Message           // 👈 你的消息模型
    let assistantAccounsCount: Int     // 助手账户数量
    
    @ObservedObject var manager: AppManager
    @Binding var showSnap: Bool
    @FocusState.Binding var showReply: Bool
    
    var onDelete: () -> Void           // 删除回调闭包

    var body: some View {
        Menu {
            // 1. 选择复制
            Section {
                Button {
                    Clipboard.set(message.body.plainText)
                    Toast.copy()
                } label: {
                    Label("复制内容", systemImage: "doc.on.doc")
                }
            }
            
            // 2. 分享截图
            Section {
                Button {
                    showSnap.toggle()
                } label: {
                    Label("分享截图", systemImage: "crop")
                }
            }

            // 3. 动态分享图片
            if let image = message.image, !image.isEmpty {
                Section {
                    Button {
                        shareImageAction(imagePath: image)
                    } label: {
                        Label("分享图片", systemImage: "photo.circle")
                    }
                }
            }

            // 4. 动态分享文字内容
            if !message.body.isEmpty {
                Section {
                    Button {
                        manager.open(sheet: .share(
                            contents: [message.body],
                            preview: nil,
                            title: String(localized: "文字消息")
                        ))
                    } label: {
                        Label("分享内容", systemImage: "doc.append")
                    }
                }
            }

            // 5. 回复
            if let reply = message.reply, !reply.isEmpty {
                Section {
                    Button {
                        showReply = true
                    } label: {
                        Label("回复", systemImage: "text.bubble")
                    }
                }
            }

            // 6. 智能助手
            if assistantAccounsCount > 0 {
                Section {
                    Button {
                        Haptic.impact()
                        // 确保切回主线程执行 UI 核心路由逻辑
                        DispatchQueue.main.async {
                            AppManager.shared.askMessageID = message.id
                            AppManager.shared.page = .assistant
                            if manager.sizeClass == .compact {
                                AppManager.shared.router = []
                            } else {
                                AppManager.shared.router = [.noletChat]
                            }
                        }
                    } label: {
                        Label("智能助手", systemImage: "atom")
                    }
                }
            }

            // 7. 删除
            Section {
                Button(role: .destructive) { // 💡 推荐：给删除按钮标记 role，系统会自动将其变红并优化震感
                    onDelete()
                } label: {
                    Label("删除", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.primary)
                }
            }

        } label: {
            // 🏷 你的那个小巧的点击触发区域
            HStack {
                Spacer()
                Image(systemName: "ellipsis")
                    .imageScale(.large)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
            }
            .contentShape(Rectangle())
        }.frame(maxWidth: 60)
        
    }

    // 抽出图片下载的 Task 逻辑，保持 body 的纯净
    private func shareImageAction(imagePath: String) {
        Task {
            if let imageLocalPath = await ImageManager.downloadImage(imagePath),
               let uiImage = UIImage(contentsOfFile: imageLocalPath) {
                // 确保更新 UI 时回到主线程
                await MainActor.run {
                    manager.open(sheet: .share(
                        contents: [uiImage],
                        preview: uiImage,
                        title: String(localized: "图片消息")
                    ))
                }
            }
        }
    }
}
