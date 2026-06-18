//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - CyberTerminalNotificationCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 12:35.

import SwiftUI

// MARK: - 风格 2：极客极简 · HUD 动态终端卡片

struct CyberTerminalNotificationCard: View {
    let message: Message
    @State private var isCopied = false

    var severityColor: Color {
        switch message.group.lowercased() {
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

                Text("push-receiver://\(message.group.lowercased())")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)

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

                Text(message.body)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(6)
                    .padding(.leading, 14)
            }

            // 3. 极客式底层元数据
            HStack(spacing: 12) {
                // 精简小图标 + 接收时间
                Label {
                    Text(message.createDate, style: .time)
                        .font(.system(size: 11, design: .monospaced))
                } icon: {
                    Image(systemName: message.icon ?? "")
                        .foregroundColor(severityColor)
                }

                Spacer()

                // 操作选项：如果包含 Link 则提供快捷一键复制/打开
                if let link = message.url {
                    Button(action: {
                        UIPasteboard.general.string = link
                        withAnimation {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isCopied = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.clipboard")
                            Text(isCopied ? "Copied!" : "复制Link")
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(isCopied ? .green : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                    }
                }
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(severityColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: severityColor.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    CyberTerminalNotificationCard(message: Message(
        id: "123",
        createDate: .now,
        group: "",
        title: "生产数据库磁盘过高报警",
        subtitle: "警告：/dev/sda1 剩余空间仅 8.5%",
        body: "收到 Prometheus 警报：宿主机 [Pro-db-04] 当前剩余空间 8.5G/100G，已连续 15 分钟呈递增趋势，请尽快处理日志堆积或挂载扩容。",
        icon: nil,
        url: "https://grafana.example.com/alerts",
        image: nil,
        reply: nil,
        ttl: 2,
        read: true,
        other: nil
    ))
}
