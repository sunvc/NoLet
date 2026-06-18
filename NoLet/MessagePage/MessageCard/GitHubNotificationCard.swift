//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - GitHubNotificationCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:25.

import SwiftUI

struct GitHubNotificationCard: View {
    let message: Message
    @State private var isActionDispatched = false

    // 根据消息等级 (level) 配置主题色
    var levelColor: Color {
        switch message.ttl {
        case 0:
            return Color.blue // 普通信息 / 推送
        case 1:
            return Color(red: 0.18, green: 0.64, blue: 0.28) // 成功 / 正常
        case 2:
            return Color.orange // 警告级
        case 3:
            return Color.red // 严重 / 崩溃 / 故障
        default:
            return Color(red: 0.55, green: 0.32, blue: 0.89) // 紫色 (自定义等)
        }
    }

    // 等级标签文字
    var levelLabel: String {
        switch message.ttl {
        case 0: return "INFO"
        case 1: return "SUCCESS"
        case 2: return "WARN"
        case 3: return "CRIT"
        default: return "EVENT"
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

                        Text(message.group)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // 来源主机 (host / from)
                        if let from = message.url {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(from)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 相对时间
                        Text(message.createDate, style: .relative)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        // 未读红点/蓝点
                        if !message.read {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 7, height: 7)
                                .shadow(color: .blue.opacity(0.5), radius: 2)
                        }
                    }

                    // 中部：等级标签与分支/网络属性
                    HStack(spacing: 8) {
                        // 级别标
                        HStack(spacing: 4) {
                            Image(systemName: message.icon ?? "bell.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(levelLabel)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(levelColor)
                        .cornerRadius(4)

                        // Subtitle 副标题分支
                        if let subtitle = message.subtitle {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 9))
                                Text(subtitle)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(4)
                        }

                        // Host 来源主机
                        if let host = message.url {
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

                        Text(message.body)
                            .font(.system(size: 12.5))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .padding(.top, 1)
                    }

                    // 如果存在回复 (reply)，渲染引用样式气泡
                    if let reply = message.reply {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(levelColor.opacity(0.5))
                                .frame(width: 2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("回复内容:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(reply)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary.opacity(0.8))
                            }
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)
                    }

                    // 底部：其他备注信息与 TTL 进度
                    HStack(spacing: 8) {
                        if let other = message.other {
                            Text(other)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.8))
                                .lineLimit(1)
                        }

                        Spacer()

                        // TTL 进度指示器
                        if message.ttl > 0 && !message.isExpired {
                            HStack(spacing: 4) {
                                Text("TTL")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)

                                Circle()
                                    .trim(from: 0.0, to: CGFloat(message.lifePercent))
                                    .stroke(levelColor, lineWidth: 1.5)
                                    .frame(width: 10, height: 10)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .opacity(message.read ? 0.85 : 1.0) // 已读卡片略微变暗降噪

            // 底部操作链接区 (url 替换了原 link)
            if let urlString = message.url {
                Divider()

                HStack {
                    Button(action: {
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 13))
                            Text("点击跳转链接")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(levelColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Spacer()

                    // 特殊：针对带有回复的消息，渲染快捷答复动作按钮
                    if message.reply != nil {
                        Button(action: {
                            withAnimation {
                                isActionDispatched = true
                            }
                        }) {
                            Text(isActionDispatched ? "已送达" : "快捷回复")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isActionDispatched ? .gray : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isActionDispatched ? Color.gray
                                    .opacity(0.1) : levelColor)
                                .cornerRadius(6)
                        }
                        .disabled(isActionDispatched)
                        .padding(.trailing, 16)
                    }
                }
                .background(levelColor.opacity(0.02))
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

struct GitHubShowcaseView: View {
    // 模拟基于最新 Message 数据模型的真实通知数据
    let mockMessages = [
        Message(
            id: "msg_01",
            createDate: Date().addingTimeInterval(-15), // 15秒前
            group: "GITHUB/REPO",
            title: "Merge pull request #157 from feature/jwt-auth",
            subtitle: "main <- jwt-auth",
            body: "实现了符合 OAuth2 规范的 JWT 核心安全鉴权。支持自动令牌刷新与设备白名单校验。",
            icon: "arrow.triangle.merge",
            url: "https://github.com/apple/swift",
            image: nil,
            reply: "集成测试已跑完，所有 12 项合规性审查正常。",
            ttl: 600,
            read: false,
            other: "SHA: e8d9c2b"
        ),
        Message(
            id: "msg_02",
            createDate: Date().addingTimeInterval(-120), // 2分钟前
            group: "PROD-SERVER",
            title: "[Dependabot] 严重漏洞预警",
            subtitle: "requirements.txt",
            body: "发现 Django 框架远程代码执行 RCE 高危漏洞。在版本低于 3.2.1 情况下可能遭遇报头注入，建议立即将其升级到 3.2.5。",
            icon: "shield.lefthalf.filled",
            url: "https://github.com/advisories",
            image: nil,
            reply: nil,
            ttl: 3600,
            read: true, // 已读状态
            other: "CVE-2026-9918"
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("实时接收并推送的自建消息流")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // 卡片一：GitHub Merge 回复（未读 + level 0）
                    GitHubNotificationCard(message: mockMessages[0])
                    
                    // 卡片二：安全高危报警（已读 + level 3）
                    GitHubNotificationCard(message: mockMessages[1])
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("消息中心")
        }
    }
}

#Preview {
    GitHubShowcaseView()
        .preferredColorScheme(.light)
}
