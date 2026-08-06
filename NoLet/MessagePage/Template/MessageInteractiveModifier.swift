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
    let message: MessageEntity
    let namespace: Namespace.ID

    @ObservedObject var manager: AppManager
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
        guard !replyText.removingAllWhitespace.isEmpty else {
            Toast.info(title: "内容不能为空")
            return
        }
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
        message: MessageEntity,
        in namespace: Namespace.ID,
        manager: AppManager,
        replyText: Binding<String>,
        showReply: FocusState<Bool>.Binding,
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
    let message: MessageEntity
    let assistantAccounsCount: Int

    @ObservedObject var manager: AppManager
    @Binding var showSnap: Bool
    @FocusState.Binding var showReply: Bool

    var onDelete: () -> Void

    var body: some View {
        Menu {
            Section {
                Button {
                    Clipboard.set(message.bodyText.plainText)
                    Toast.copy()
                } label: {
                    Label("复制内容", systemImage: "doc.on.doc")
                }
            }

            Section {
                Button {
                    showSnap.toggle()
                } label: {
                    Label("分享截图", systemImage: "crop")
                }
            }

            if let image = message.image, !image.isEmpty {
                Section {
                    Button {
                        shareImageAction(imagePath: image)
                    } label: {
                        Label("分享图片", systemImage: "photo.circle")
                    }
                }
            }

            if !message.bodyText.isEmpty {
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

            if let reply = message.reply, !reply.isEmpty {
                Section {
                    Button {
                        showReply = true
                    } label: {
                        Label("回复", systemImage: "text.bubble")
                    }
                }
            }

            if assistantAccounsCount > 0 {
                Section {
                    Button {
                        Haptic.impact()
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

            Section {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("删除", systemImage: "trash.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.primary, .red)
                }
            }

        } label: {
            Text(message.createDate ?? .now, format: .relative(presentation: .named))
                .font(.footnote)
                .foregroundColor(.secondary)
                .accessibilityLabel("时间:")
                .accessibilityValue((message.createDate ?? .now)
                    .formatted(date: .long, time: .standard))
                .contentShape(Rectangle())
                .lineLimit(1)
        }
    }

    private func shareImageAction(imagePath: String) {
        Task {
            if let imageLocalPath = await ImageManager.downloadImage(imagePath),
               let uiImage = UIImage(contentsOfFile: imageLocalPath)
            {
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

extension MessagesManager {
    static func examples() -> [[AnyHashable: Any]] {
        [
            [
                "id": UUID().uuidString,
                "createDate": Int(Date.now.timeIntervalSince1970),
                "group": String(localized: "示例"),
                "title": String(localized: "默认样式"),
                "body": String(localized: "这是一段示例内容"),
                "ttl": 600,
                "read": false,
            ],
            [
                "id": UUID().uuidString,
                "createDate": Int(Date.now.timeIntervalSince1970),
                "group": String(localized: "示例"),
                "title": String(localized: "MD样式"),
                "body": "# NoLet \n## NoLet \n### NoLet",
                "ttl": 600,
                "read": false,
                "style": "markdown",
            ],
            [
                "id": UUID().uuidString,
                "createDate": Int(Date.now.timeIntervalSince1970),
                "group": String(localized: "示例"),
                "title": String(localized: "终端样式"),
                "body": String(localized: "这是一段示例内容") + " style=terminal",
                "ttl": 600,
                "read": false,
                "style": "terminal",
            ],
            [
                "id": UUID().uuidString,
                "createDate": Int(Date().addingTimeInterval(-1).timeIntervalSince1970),
                "group": String(localized: "主机通知"),
                "title": "Merge pull request #157 from feature/jwt-auth",
                "subtitle": String(localized: "实现了符合 OAuth2 规范的 JWT 核心安全鉴权。"),
                "body": String(localized: "实现了符合 OAuth2 规范的 JWT 核心安全鉴权。支持自动令牌刷新与设备白名单校验。"),
                "icon": "",
                "url": "https://github.com/apple/swift",
                "reply": "https://wzs.app/reply",
                "ttl": 600,
                "read": false,
                "style": "github",
                "other": """
                    {
                        "footer" : "SHA:alksdjfklaj",
                        "header" : "GITHUB/REPO",
                        "from" : "https://api.githun.com",
                        "branch" : "main <- jwt-auth",
                        "severity" : "success"
                    }
                    """,
            ],
            [
                "id": UUID().uuidString,
                "createDate": Int(Date().timeIntervalSince1970),
                "group": "wechat",
                "title": String(localized: "收款通知"),
                "subtitle": "+¥18.50",
                "body": String(localized: "二维码收款已到账"),
                "icon": "https://favicon.wzs.app/wechat.com",
                "ttl": 600,
                "read": false,
                "style": "pay",
                "other": """
                    { "ticket":"NO: 999999999999" }
                    """,
            ],
        ]
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        }
    }
}

extension View {
    @ViewBuilder
    func mbackground26<S>(_ color: S, radius: CGFloat = 0) -> some View where S: ShapeStyle {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
        } else {
            background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(color)
                    .shadow(group: false)
            )
        }
    }

    func shadow(group _: Bool) -> some View {
        shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .shadow(color: Color.shadow1, radius: 5, x: 3, y: 5)
            .shadow(color: Color.shadow1.opacity(0.5), radius: 5, x: -3, y: -5)
    }
}

extension MessageEntity {
    func accessibilityValue() -> String {
        var text: [String] = []

        text
            .append(
                String(localized: "时间:") + (createDate ?? .now)
                    .formatted(date: .long, time: .standard)
            )

        if let title = title {
            text.append(String(localized: "标题") + ":" + title)
        }
        if let subtitle = subtitle {
            text.append(String(localized: "副标题") + ":" + subtitle)
        }

        if !bodyText.isEmpty {
            text.append(String(localized: "内容") + ":" + bodyText)
        }

        if image != nil {
            text.append(String(localized: "附件: 一张图片"))
        }

        if let url = url {
            text.append(String(localized: "跳转链接:") + url)
        }

        return text.joined(separator: "\n")
    }

    // 放到类内部，静态缓存格式化器
    private static var relativeFormatter: RelativeDateTimeFormatter {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .full
        fmt.calendar = Calendar.current
        return fmt
    }

    func expiredTime() -> String {
        if ttl == ExpirationTime.forever.rawValue {
            return "∞ ∞ ∞"
        }

        let expireDate = (createDate ?? .now).addingTimeInterval(TimeInterval(ttl))
        let remainSeconds = Date.now.distance(to: expireDate)

        guard remainSeconds > 0 else {
            return String(localized: "已过期")
        }

        if remainSeconds < 86400 {
            return String(localized: "即将过期")
        }

        let text = Self.relativeFormatter.localizedString(for: expireDate, relativeTo: .now)
        return text
    }
}
