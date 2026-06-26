//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - GitHubMessageCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:25.

import SwiftUI

struct GitHubMessageCard: View {
    let message: Message
    var config: MessageCardConfiguration = .init()
    @State private var isActionDispatched = false

    @ObservedObject var manager = AppManager.shared
    @Namespace private var messageNameSpace
    @State private var replyText: String = ""
    @FocusState private var showReply
    @State private var showSnap: Bool = false

    var severity: String {
        message.value(for: "severity", "EVENT").uppercased()
    }

    // 根据消息等级 (level) 配置主题色
    var levelColor: Color {
        switch severity {
        case "INFO":
            return Color.blue // 普通信息 / 推送
        case "SUCCESS":
            return Color(red: 0.18, green: 0.64, blue: 0.28) // 成功 / 正常
        case "WARN":
            return Color.orange // 警告级
        case "CRIT":
            return Color.red // 严重 / 崩溃 / 故障
        default:
            return Color(red: 0.55, green: 0.32, blue: 0.89) // 紫色 (自定义等)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 1. 左侧级别状态竖条 (颜色随 level 改变)
                Rectangle()
                    .fill(levelColor)
                    .frame(width: 5)

                // 2. 右侧主体内容
                VStack(alignment: .leading, spacing: 10) {
                    // 顶部：分组与来源元数据
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text(verbatim: message.value(for: "header", "GITHUB"))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(verbatim: "•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(message.group)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(message.createDate, format: .relative(presentation: .named))
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        // TTL 进度指示器
                        if message.ttl > 0 && !message.isExpired {
                            Circle()
                                .trim(from: 0.0, to: CGFloat(message.lifePercent))
                                .stroke(levelColor, lineWidth: 1.5)
                                .frame(width: 10, height: 10)
                                .rotationEffect(.degrees(-90))
                        }
                    }

                    // 中部：等级标签与分支/网络属性
                    HStack(spacing: 8) {
                        // 级别标
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 9, weight: .bold))
                            Text(severity)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(levelColor)
                        .cornerRadius(4)

                        // Subtitle 副标题分支
                        if let branch = message.value(for: "branch", "main") {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 9))
                                Text(branch)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(4)
                        }

                        // Host 来源主机
                        if let host = message.value(for: "from", ""),
                           let url = URL(string: host),
                           let host = url.host()
                        {
                            Text(host)
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    // 标题与内容描述
                    VStack(alignment: .leading, spacing: 6) {
                        if let title = message.title {
                            Text(title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let subTitle = message.subtitle {
                            Text(subTitle)
                                .font(.system(size: 12.5))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .padding(.top, 1)
                        }
                    }

     
                    if !message.body.isEmpty {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(levelColor.opacity(0.5))
                                .frame(width: 2)

                            SCSelectableTextRepresentable(
                                text: message.body.plainText,
                                font: .systemFont(ofSize: 11, weight: .medium),
                                textColor: .textBlack,
                                textAlignment: .left,
                                lineLimit: 5
                            )
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)
                    }

                    // 底部：其他备注信息与 TTL 进度
                    HStack(spacing: 8) {
                        if let footer = message.value(for: "footer", "") {
                            Text(footer)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.8))
                                .lineLimit(1)
                        }

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
            }
            .background(Color(.secondarySystemGroupedBackground))
        }
        .glassCard(12, padding: 0, borderColor: nil)
        .messageInteraction(
            message: message,
            in: messageNameSpace,
            manager: manager,
            replyText: $replyText,
            showReply: $showReply,
            showSnap: $showSnap,
            onShowFull: showFull
        )
        .shadow(color: config.focusColor, radius: 10, x: 0, y: 0)
    }

    func showFull() {
        manager.selectMessage = message

        Haptic.impact(.light)
    }
}

#Preview {
    ScrollView { 
        GitHubMessageCard(message: Message(
            id: UUID().uuidString,
            createDate: Date().addingTimeInterval(-1), // 15秒前
            group: "主机通知",
            title: "Merge pull request #157 from feature/jwt-auth",
            subtitle: "实现了符合 OAuth2 规范的 JWT 核心安全鉴权。",
            body: "实现了符合 OAuth2 规范的 JWT 核心安全鉴权。支持自动令牌刷新与设备白名单校验。",
            icon: "",
            url: "https://github.com/apple/swift",
            image: nil,
            reply: "https://wzs.app/reply",
            ttl: 600,
            read: false,
            other: """
                {
                    "footer" : "SHA:alksdjfklaj", 
                    "header" : "GITHUB/REPO", 
                    "from" : "https://api.githun.com",
                    "branch" : "main <- jwt-auth",
                    "severity" : "success",
                }
                """
        ))
    }
}
