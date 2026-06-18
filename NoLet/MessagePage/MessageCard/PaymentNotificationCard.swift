//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - PaymentNotificationCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:49.
    
import SwiftUI
import Combine

struct PaymentNotificationCard: View {
    let message: Message
    
    // 引入定时器，让倒计时进度条和时间能够实时刷新
    @State private var timeTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var currentLifePercent: Double = 1.0
    @State private var isExpired: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. 头部信息 (平台来源 & 紧急级别)
            HStack(spacing: 8) {
                // 动态获取图标，这里用系统图标兜底
                Image(systemName: message.icon ?? "creditcard.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(brandColor(for: message.group))
                
                Text(message.group)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 紧急级别标签 (例如 level >= 3 认为是高风险/大额交易)
                if message.ttl >= 3 {
                    Text("加急确认")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
                
                // 时间显示
                Text(formatDate(message.createDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding([.top, .horizontal], 16)
            
            // 2. 卡片主体 (商户名称 & 金额/内容)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let from = message.url {
                        Text(from)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(message.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 右侧展示元数据：在支付场景下非常适合放“金额”
                if let other = message.other {
                    Text(other)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(isExpired ? .secondary : brandColor(for: message.group))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, message.ttl > 0 ? 12 : 16) // 如果有TTL，留白缩减给进度条
            
            // 3. 底部生命周期倒计时条 (TTL 机制)
            if message.ttl > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(currentLifePercent < 0.3 ? Color.red : brandColor(for: message.group))
                            .frame(width: geo.size.width * CGFloat(currentLifePercent), height: 4)
                            .animation(.linear(duration: 0.5), value: currentLifePercent)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .opacity(isExpired ? 0.3 : 1.0)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        // 灰色蒙版表示已过期
        .overlay(
            Group {
                if isExpired {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .allowsHitTesting(false)
                }
            }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // 监听定时器更新生命周期
        .onReceive(timeTicker) { _ in
            updateLifeCycle()
        }
        .onAppear {
            updateLifeCycle()
        }
    }
    
    // MARK: - 辅助方法
    
    private func updateLifeCycle() {
        self.currentLifePercent = message.lifePercent
        self.isExpired = message.isExpired
    }
    
    // 根据支付平台自动匹配品牌色
    private func brandColor(for group: String) -> Color {
        switch group.lowercased() {
        case "alipay", "支付宝": return Color.blue
        case "wechat", "wechat pay", "微信支付": return Color.green
        case "apple pay": return Color.black
        case "visa": return Color(red: 0.0, green: 0.2, blue: 0.6)
        default: return Color.indigo // 默认优雅的紫色
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


struct PaymentNotificationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // 模拟 1：正在倒计时的扣款确认
            PaymentNotificationCard(message: Message(
                id: "1",
                createDate: Date(),
                group: "支付宝",
                title: "支付确认",
                body: "您正在【Apple Store】消费，请在限时内确认扣款。",
                icon: "checkmark.shield.fill",
                ttl: 30,  // 30秒存活
                read: false,
                other: "-¥6,799.00"
            ))
            
            // 模拟 2：普通的微信收款通知（无倒计时）
            PaymentNotificationCard(message: Message(
                id: "2",
                createDate: Date().addingTimeInterval(+300), // 5分钟前
                group: "微信支付",
                title: "收款通知",
                body: "二维码收款已到账",
                icon: "indianrupeesign.circle.fill", // 动态图标
                ttl: 0, // 0 代表永久有效，不显示进度条
                read: true,
                other: "+¥18.50"
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}


