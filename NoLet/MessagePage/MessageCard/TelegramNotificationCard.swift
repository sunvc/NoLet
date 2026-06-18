//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - TelegramNotificationCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:35.

import SwiftUI

// MARK: - 风格：Telegram Premium 奢华毛玻璃智能卡片

struct TelegramNotificationCard: View {
    let message: Message

    // 高级奢华色彩系统：根据级别返回饱满、高雅的双色渐变
    var premiumGradient: LinearGradient {
        switch message.ttl {
        case 1: // 成功绿
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.80, blue: 0.50),
                    Color(red: 0.02, green: 0.60, blue: 0.35),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case 2: // 警告金/橙
            return LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.65, blue: 0.00),
                    Color(red: 0.85, green: 0.40, blue: 0.00),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case 3: // 烈焰红
            return LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.30, blue: 0.30),
                    Color(red: 0.80, green: 0.10, blue: 0.10),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        default: // Telegram Premium 经典宇宙蓝
            return LinearGradient(
                colors: [
                    Color(red: 0.24, green: 0.52, blue: 1.00),
                    Color(red: 0.12, green: 0.34, blue: 0.85),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    // 主题色单色，用于文字或精细描边
    var accentColor: Color {
        switch message.ttl {
        case 1: return Color(red: 0.05, green: 0.75, blue: 0.45)
        case 2: return Color(red: 0.95, green: 0.55, blue: 0.05)
        case 3: return Color(red: 0.95, green: 0.20, blue: 0.20)
        default: return Color(red: 0.22, green: 0.48, blue: 0.95)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 1. 左侧悬浮微光头像 (微立体投影)
            ZStack {
                Circle()
                    .fill(premiumGradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: accentColor.opacity(0.35), radius: 6, x: 0, y: 3)

                if let iconName = message.icon, !iconName.isEmpty {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(String((message.url ?? message.group).prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // 2. 右侧超轻薄水晶磨砂容器
            VStack(alignment: .leading, spacing: 12) {
                // 顶部：高级标题栏、域名与运动表盘式 TTL
                HStack(alignment: .center, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(message.group)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            // 动态小微光徽章 (表示已认证/官方级别推送)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(accentColor)
                        }

                        if let host = message.url {
                            Text("@\(host.lowercased())")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // TTL 奢华时钟盘
                    if message.ttl > 0 && !message.isExpired {
                        ZStack {
                            // 表盘外圈轨道
                            Circle()
                                .stroke(Color.primary.opacity(0.06), lineWidth: 2)
                                .frame(width: 26, height: 26)

                            // 进度环（带呼吸发光）
                            Circle()
                                .trim(from: 0.0, to: CGFloat(message.lifePercent))
                                .stroke(
                                    premiumGradient,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .frame(width: 26, height: 26)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: accentColor.opacity(0.4), radius: 3)

                            // 中间倒计时数字
                            Text("\(Int(Double(message.ttl) * message.lifePercent))")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(accentColor)
                        }
                    }
                }

                // 引用回复模块 (Reply Area with Premium Frosted Style)
                if let reply = message.reply {
                    HStack(spacing: 10) {
                        // 奢华双色渐变左侧竖边
                        RoundedRectangle(cornerRadius: 2)
                            .fill(premiumGradient)
                            .frame(width: 3.5)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(message.url ?? "Telegram Service")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(accentColor)

                            Text(reply)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.025))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                    )
                }

                // 信息文本区
                VStack(alignment: .leading, spacing: 4) {
                    if let title = message.title {
                        Text(title)
                            .font(.system(size: 14.5, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    Text(message.body)
                        .font(.system(size: 13.5))
                        .foregroundColor(.primary.opacity(0.85))
                        .lineSpacing(3)
                }

                // 富媒体网页链接预览卡片 (Advanced Web Link Component)
                if let urlString = message.url {
                    Button(action: {
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            // 极简网页大图/图标占位
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(premiumGradient.opacity(0.1))
                                    .frame(width: 42, height: 42)

                                Image(systemName: "safari.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(accentColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Web Instant View")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(accentColor)

                                Text(urlString)
                                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.02))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 底部元数据、时间、已读反馈 (双勾)
                HStack(spacing: 6) {
                    if let other = message.other {
                        Text(other)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.75))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(4)
                    }

                    Spacer()

                    // 精确时间
                    Text(message.createDate, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    // Premium 双勾，带专属发光阴影
                    if message.read {
                        HStack(spacing: -3) {
                            Image(systemName: "checkmark")
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(accentColor)
                        .shadow(color: accentColor.opacity(0.5), radius: 1)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            // 💡 极具苹果设计美学的超薄毛玻璃材质层 (支持深浅色自适应)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            // 💡 水晶级极细双色渐变描边：上方和左侧反光，下部深暗，实现顶级物理折射效果
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.15),
                                Color.black.opacity(0.05),
                                Color.white.opacity(0.3),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            // 精密的物理柔和阴影，避免低端感
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .shadow(color: accentColor.opacity(0.02), radius: 16, x: 0, y: 8)
        }
        .padding(.horizontal)
    }
}

// MARK: - 主演示展示画廊（动态流光弥散背景，突显毛玻璃折射）

struct GitHubShowcaseView1: View {
    @State private var animateGlow = false

    let mockMessages = [
        Message(
            id: "msg_premium_01",
            createDate: Date().addingTimeInterval(-12),
            group: "Telegram Premium",
            title: "💎 Telegram Premium 已激活",
            subtitle: nil,
            body: "感谢您订阅 Premium 专属通知服务！高吞吐量数据管道、4K 大文件极速解析与云端自动化集群警报功能均已解锁完成。",
            icon: "paperplane.fill",
            url: "https://telegram.org/blog/premium",
            image: nil,
            reply: "您的月度账单已完成合并支付结算。",
            ttl: 60,
            read: true,
            other: "#premium_active"
        ),
        Message(
            id: "msg_premium_02",
            createDate: Date().addingTimeInterval(-240),
            group: "K8S Production Cluster",
            title: "🔥 Cluster Node-09 Memory Spike",
            subtitle: nil,
            body: "CRITICAL: 物理节点集群中的 Node-09 遭遇内存突增，当前承载率突破 98.6%。检测到 4 个关键微服务进程发生死锁，系统已经准备启动备用负载容灾节点。",
            icon: "flame.fill",
            url: "https://k8s-console.local/dashboard",
            image: nil,
            reply: nil,
            ttl: 3600,
            read: false,
            other: "ERR_MEM_SPIKE"
        ),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // 1. 底层静谧背景
                Color(red: 0.08, green: 0.10, blue: 0.14)
                    .ignoresSafeArea()

                // 2. 奢华弥散流光气泡（用于呈现毛玻璃穿透折射效果）
                ZStack {
                    // 左上方紫色流光
                    Circle()
                        .fill(LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 260, height: 260)
                        .blur(radius: animateGlow ? 70 : 90)
                        .offset(x: animateGlow ? -60 : -100, y: animateGlow ? -150 : -200)
                        .opacity(0.3)

                    // 右下方蓝翠绿流光
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color(red: 0.0, green: 0.8, blue: 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 320, height: 320)
                        .blur(radius: animateGlow ? 80 : 100)
                        .offset(x: animateGlow ? 80 : 120, y: animateGlow ? 150 : 200)
                        .opacity(0.25)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true))
                    {
                        animateGlow.toggle()
                    }
                }

                // 3. 顶层卡片通知流
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("INTELLIGENT PUSH STREAM")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(2)

                                Text("自建 Premium 通知通道")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // 智能卡片 1 (Premium 蓝)
                        TelegramNotificationCard(message: mockMessages[0])

                        // 智能卡片 2 (高危艳红)
                        TelegramNotificationCard(message: mockMessages[1])

                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark) // 极力推荐深色暗黑风格，水晶玻璃感更加震撼
    }
}

// MARK: - 预览组件

struct GitHubNotificationCard_Previews: PreviewProvider {
    static var previews: some View {
        GitHubShowcaseView1()
    }
}
