//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PaymentMessageCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:49.

import Combine
import SwiftUI

struct PaymentMessageCard: View {
    let message: Message
    var config: MessageCardConfiguration = .init()
    @State private var isActionDispatched = false

    @ObservedObject var manager = AppManager.shared
    @Namespace private var messageNameSpace
    @State private var replyText: String = ""
    @FocusState private var showReply
    @State private var showSnap: Bool = false

    @State private var timeTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var currentLifePercent: Double = 1.0
    @State private var isExpired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 头部信息 (平台来源 & 紧急级别)
            HStack(spacing: 8) {
                // 动态获取图标，这里用系统图标兜底

                AvatarView(icon: message.icon)
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let title = message.title {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                // 时间显示
                Text(message.createDate, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding([.top, .horizontal], 16)

            // 2. 卡片主体 (商户名称 & 金额/内容)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let url = message.url, let url = URL(string: url) {
                        Link("打开链接", destination: url)
                            .font(.footnote)
                    }

                    Text(message.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // 右侧展示元数据：在支付场景下非常适合放“金额”
                if let money = message.subtitle {
                    Text(money)
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(isExpired ? .secondary : brandColor(for: message.group))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, message.ttl > 0 ? 12 : 16) // 如果有TTL，留白缩减给进度条
            if let number = message.value(for: "ticket", ""), !number.isEmpty{
                HStack {
                    Text(number)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
            }
            

            // 3. 底部生命周期倒计时条 (TTL 机制)
            if message.ttl > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 4)

                        Capsule()
                            .fill(currentLifePercent < 0.3 ? Color
                                .red : brandColor(for: message.group))
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
        .glassCard(20)
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

    // 3. 你的原函数调用变得极度极其简单
    private func brandColor(for group: String) -> Color {
        return PaymentPlatform(rawValue: group).brandColor
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct PaymentMessageCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PaymentMessageCard(message: Message(
                id: "1",
                createDate: Date(),
                group: "alipay",
                title: "支付确认",
                subtitle: "-¥6,799.00",
                body: "您正在【Apple Store】消费，请确认扣款。",
                icon: "https://favicon.wzs.app/alipay.com",
                ttl: 10, // 10秒存活
                read: false
            ))
            .padding()
            PaymentMessageCard(message: Message(
                id: "2",
                createDate: Date(), 
                group: "wechat",
                title: "收款通知",
                subtitle: "+¥18.50",
                body: "二维码收款已到账",
                icon: "https://favicon.wzs.app/wechat.com",
                ttl: 20, 
                read: false,
                other: """
                    {
                        "ticket":"订单号: 999999999999"
                    }
                    """
            ))
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

enum PaymentPlatform {
    // === 国际卡组织 (Card Networks) ===
    case visa
    case mastercard
    case amex // American Express
    case discover
    case jcb // 日本吉三巴
    case unionpay // 银联

    // === 手机钱包与科技巨头 (Digital Wallets) ===
    case applePay
    case googlePay
    case samsungPay

    // === 亚太主流钱包 (Asia-Pacific Wallets) ===
    case alipay // 支付宝
    case wechat // 微信支付
    case linePay // LINE Pay (日韩/中国台湾)
    case paytm // 印度主流钱包

    // === 欧美主流在线支付与先买后付 (Online & BNPL) ===
    case paypal
    case stripe
    case klarna // 欧洲流行先买后付

    // === 欧洲本地转账/直付 (European Local Payments) ===
    case ideal // 荷兰国民支付
    case bancontact // 比利时国民支付
    case giropay // 德国常用直付

    case unknown(String)

    // 初始化方法：聚合全球常见别名、缩写及中英文
    init(rawValue: String) {
        let normalized = rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized {
        // 国际卡组织
        case "visa": self = .visa
        case "mastercard", "master": self = .mastercard
        case "amex", "american express", "americanexpress": self = .amex
        case "discover", "discover card": self = .discover
        case "jcb": self = .jcb
        case "unionpay", "union pay", "银联", "银联支付": self = .unionpay
        // 手机钱包
        case "applepay", "apple pay": self = .applePay
        case "googlepay", "google pay", "gpay": self = .googlePay
        case "samsungpay", "samsung pay": self = .samsungPay
        // 亚太主流
        case "alipay", "支付宝": self = .alipay
        case "wechat", "wechat pay", "wechatpay", "微信支付": self = .wechat
        case "linepay", "line pay": self = .linePay
        case "paytm": self = .paytm
        // 欧美主流
        case "paypal", "pay pal": self = .paypal
        case "stripe": self = .stripe
        case "klarna": self = .klarna
        // 欧洲本地
        case "ideal": self = .ideal
        case "bancontact": self = .bancontact
        case "giropay": self = .giropay
        default: self = .unknown(rawValue)
        }
    }

    // 绑定各大平台的官方标准品牌色
    var brandColor: Color {
        switch self {
        // 国际卡组织
        case .visa: return Color(hex: "#1A1F71") // Visa 经典深蓝
        case .mastercard: return Color(hex: "#FF5F00") // 万事达标志性橙色
        case .amex: return Color(hex: "#016FD0") // 运通蓝
        case .discover: return Color(hex: "#E55C20") // Discover 橙
        case .jcb: return Color(hex: "#00377B") // JCB 深蓝
        case .unionpay: return Color(hex: "#00796B") // 银联标志性红绿蓝偏青色调
        // 手机钱包
        case .applePay: return Color.primary // 适配黑白暗黑模式
        case .googlePay: return Color(hex: "#4285F4") // Google 蓝
        case .samsungPay: return Color(hex: "#1428A0") // 三星蓝
        // 亚太主流
        case .alipay: return Color(hex: "#128EFA") // 支付宝蓝
        case .wechat: return Color(hex: "#07C160") // 微信生态绿
        case .linePay: return Color(hex: "#06C755") // LINE 绿
        case .paytm: return Color(hex: "#00BAF2") // Paytm 浅蓝
        // 欧美主流
        case .paypal: return Color(hex: "#003087") // PayPal 深蓝
        case .stripe: return Color(hex: "#635BFF") // Stripe 经典紫蓝
        case .klarna: return Color(hex: "#FFB3C7") // Klarna 标志性粉色
        // 欧洲本地
        case .ideal: return Color(hex: "#CC0066") // iDEAL 玫红
        case .bancontact: return Color(hex: "#000000") // 比利时黑 (建议按需适配暗黑模式)
        case .giropay: return Color(hex: "#005A9B") // Giropay 蓝
        case .unknown: return Color.indigo // 默认兜底紫色
        }
    }

    // 额外扩展：获取面向用户的标准展示名称
    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .discover: return "Discover"
        case .jcb: return "JCB"
        case .unionpay: return "中国银联"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .samsungPay: return "Samsung Pay"
        case .alipay: return "支付宝"
        case .wechat: return "微信支付"
        case .linePay: return "LINE Pay"
        case .paytm: return "Paytm"
        case .paypal: return "PayPal"
        case .stripe: return "Stripe"
        case .klarna: return "Klarna"
        case .ideal: return "iDEAL"
        case .bancontact: return "Bancontact"
        case .giropay: return "Giropay"
        case .unknown(let name): return name
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
