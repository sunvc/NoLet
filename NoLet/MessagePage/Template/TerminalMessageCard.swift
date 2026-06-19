//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - TerminalMessageCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 12:35.

import SwiftUI

// MARK: - 风格 2：极客极简 · HUD 动态终端卡片

struct TerminalMessageCard: MessageCardProtocol {
    let message: Message
    var config: MessageCardConfiguration

    @ObservedObject var manager = AppManager.shared
    @Namespace private var messageNameSpace
    @State private var replyText: String = ""
    @FocusState private var showReply
    @State private var showSnap: Bool = false

    var severityColor: Color {
        switch message.value(for: "severity", "success").lowercased() {
        case "error", "alert", "system": return .red
        case "warning": return .orange
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Terminal 顶部命令样式栏
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                }

                Spacer()

                Text(message.createDate, format: .relative(presentation: .named))
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()

                // 生存环 (TTL 倒计时)
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(message.lifePercent))
                        .stroke(severityColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                }
            }

            // 2. 主体终端输出式样
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("$")
                        .foregroundColor(severityColor)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)

                    Text(message.title ?? "没有标题")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                if let subtitle = message.subtitle {
                    Text(">> [\(subtitle)]")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.leading, 14)
                }

                SCSelectableTextRepresentable(
                    text: message.body.plainText,
                    font: .systemFont(ofSize: 13, weight: .medium),
                    textColor: UIColor.secondaryLabel,
                    textAlignment: .left,
                    lineLimit: 5
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(6)
                .padding(.leading, 5)
            }

            if let image = message.image {
                AsyncPhotoView(url: image, zoom: false, height: 200)
                    .padding(5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.showFull()
                    }
            }

            // 3. 极客式底层元数据
            HStack(spacing: 12) {
                // 精简小图标 + 接收时间

                AvatarView(icon: message.icon)
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(message.group)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 5)

                Spacer()

                // 操作选项：如果包含 Link 则提供快捷一键复制/打开
                if let link = message.url, let url = URL(string: link) {
                    Link(destination: url) {
                        Text(verbatim: "LINK")
                            .font(.caption)
                    }
                }

                MessageActionMenu(
                    message: message,
                    assistantAccounsCount: config.accounts,
                    manager: manager,
                    showSnap: $showSnap,
                    showReply: $showReply,
                    onDelete: config.delete
                )
            }
        }
        .padding(16)
        .glassCard()
        .messageInteraction(
            message: message,
            in: messageNameSpace,
            manager: manager,
            replyText: $replyText,
            showReply: $showReply,
            showSnap: $showSnap,
            onShowFull: showFull
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(severityColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: severityColor.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    func showFull() {
        manager.selectMessage = message

        Haptic.impact(.light)
    }
}

#Preview {
    TerminalMessageCard(message: Message(
        id: "123",
        createDate: .now.addingTimeInterval(-1),
        group: "服务器",
        title: "生产数据库磁盘过高报警",
        subtitle: "警告：/dev/sda1 剩余空间仅 8.5%",
        body: "收到 Prometheus 警报：宿主机 [Pro-db-04] 当前剩余空间 8.5G/100G，已连续 15 分钟呈递增趋势，请尽快处理日志堆积或挂载扩容。",
        icon: nil,
        url: "https://grafana.example.com/alerts",
        image: "https://s3.wzs.app/nolet/logo.png",
        reply: nil,
        ttl: 2,
        read: true,
        other: "{ \"severity\" : \"success\" }"
    ), config: .init())
}
