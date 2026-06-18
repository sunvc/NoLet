//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - LiquidRichNotificationCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 12:56.

import SwiftUI

struct LiquidRichNotificationCard: View {
    let message: Message
    @State private var isPressed = false

    // 根据 Group 分组类型返回代表色彩
    var themeColor: Color {
        switch message.group.lowercased() {
        case "work", "工作", "待办提醒": return .blue
        case "system", "server", "服务器监控": return .red
        case "finance", "账单", "资产": return .green
        default: return .purple
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 主卡片体
            VStack(alignment: .leading, spacing: 12) {
                // 1. 顶部 Header 栏
                HStack(spacing: 8) {
                    // 圆角渐变 Icon 容器
                    ZStack {
                        LinearGradient(
                            colors: [themeColor, themeColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: message.icon ?? "")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(width: 30, height: 30)
                    .cornerRadius(8)

                    // 分组与时间
                    VStack(alignment: .leading, spacing: 1) {
                        Text(message.group)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)

                        Text(message.createDate, style: .relative)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // TTL 状态标签
                    HStack(spacing: 4) {
                        Circle()
                            .fill(message.isExpired ? Color.gray : themeColor)
                            .frame(width: 6, height: 6)
                            .shadow(color: themeColor.opacity(0.5), radius: 3)

                        Text(message.isExpired ? "已过期" : "存活中")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }

                // 2. 核心文本区域
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title ?? "没有标题")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let subtitle = message.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    Text(message.body)
                        .font(.system(size: 14))
                        .foregroundColor(.primary.opacity(0.8))
                        .lineLimit(3)
                        .padding(.top, 2)
                }

                // 3. 附属大图区域 (如果有)
                if let attachmentImage = message.image {
                    ZStack {
                        // 使用带毛玻璃的灰色背景占位
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))

                        Image(systemName: attachmentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                            .foregroundColor(themeColor.opacity(0.3))
                            .padding()

                        // 提示这是多媒体大图占位
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Label("媒体附件", systemImage: "photo")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.black.opacity(0.4))
                                    .cornerRadius(6)
                                    .padding(8)
                            }
                        }
                    }
                    .frame(height: 140)
                    .cornerRadius(12)
                }

                // 4. 生存时间 (TTL) 视觉带
                if !message.isExpired {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("TTL 剩余生命周期")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(message.ttl * Int( message.lifePercent))s")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(themeColor)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(themeColor)
                                    .frame(
                                        width: geo.size.width * CGFloat(message.lifePercent),
                                        height: 4
                                    )
                                    .shadow(color: themeColor.opacity(0.3), radius: 2)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))

            // 5. 底部动作条 (如果有跳转链接)
            if let linkString = message.url {
                Divider()

                Button(action: {
                    if let url = URL(string: linkString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "safari")
                            .font(.system(size: 13))
                        Text("点击打开关联链接")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(themeColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(themeColor.opacity(0.06))
                }
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

#Preview {
    LiquidRichNotificationCard(message: Message(
        id: "2",
        createDate: .now,
        group: "工作",
        title: "你有一条新的智能家居代办提醒",
        subtitle: "扫地机器人任务已结束",
        body: "客房与走廊的深度清扫工作已顺利完成。本次累计清扫 42 平方米，耗时 32 分钟。集尘盒可能已满，建议手动清理。",
        ttl: 10,
        read: true
    ))
}
