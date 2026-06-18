//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - SocialPremiumNotificationCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:42.
    
import SwiftUI


// MARK: - 社交平台品牌主题定义
struct BrandTheme {
    let name: String
    let gradient: LinearGradient
    let accent: Color
    let logo: String // 备用 SF Symbol 名称
}

func getBrandTheme(for platform: String) -> BrandTheme {
    let lower = platform.lowercased()
    if lower.contains("instagram") || lower.contains("ins") {
        return BrandTheme(
            name: "Instagram",
            gradient: LinearGradient(
                colors: [Color(red: 0.90, green: 0.10, blue: 0.40), Color(red: 0.95, green: 0.35, blue: 0.15), Color(red: 0.50, green: 0.15, blue: 0.80)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            accent: Color(red: 0.90, green: 0.10, blue: 0.40),
            logo: "camera.aperture"
        )
    } else if lower.contains("twitter") || lower.contains("x") {
        return BrandTheme(
            name: "X (Twitter)",
            gradient: LinearGradient(
                colors: [Color(red: 0.10, green: 0.10, blue: 0.12), Color(red: 0.25, green: 0.25, blue: 0.30)],
                startPoint: .top, endPoint: .bottom
            ),
            accent: Color.white,
            logo: "sparkles"
        )
    } else if lower.contains("discord") {
        return BrandTheme(
            name: "Discord",
            gradient: LinearGradient(
                colors: [Color(red: 0.35, green: 0.40, blue: 0.95), Color(red: 0.25, green: 0.30, blue: 0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            accent: Color(red: 0.35, green: 0.40, blue: 0.95),
            logo: "bubble.left.and.bubble.right.fill"
        )
    } else if lower.contains("youtube") || lower.contains("yt") {
        return BrandTheme(
            name: "YouTube",
            gradient: LinearGradient(
                colors: [Color(red: 1.00, green: 0.00, blue: 0.00), Color(red: 0.75, green: 0.00, blue: 0.00)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            accent: Color(red: 1.00, green: 0.00, blue: 0.00),
            logo: "play.rectangle.fill"
        )
    } else if lower.contains("wechat") || lower.contains("vx") {
        return BrandTheme(
            name: "WeChat",
            gradient: LinearGradient(
                colors: [Color(red: 0.05, green: 0.80, blue: 0.40), Color(red: 0.02, green: 0.60, blue: 0.30)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            accent: Color(red: 0.05, green: 0.80, blue: 0.40),
            logo: "message.and.waveform.fill"
        )
    } else {
        // 默认奢华极客蓝渐变
        return BrandTheme(
            name: "Universal Feed",
            gradient: LinearGradient(
                colors: [Color(red: 0.24, green: 0.52, blue: 1.00), Color(red: 0.12, green: 0.34, blue: 0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            accent: Color(red: 0.24, green: 0.52, blue: 1.00),
            logo: "bell.badge.fill"
        )
    }
}

// MARK: - 主卡片组件：Universal Social Prism Card
struct SocialPremiumNotificationCard: View {
    let message: Message
    
    // 手势与动效微物理模型
    @State private var isPressed = false
    @State private var showActionTray = false
    @State private var inputReplyText = ""
    @State private var isReplied = false
    @State private var dragOffset: CGFloat = 0.0
    
    var body: some View {
        let theme = getBrandTheme(for: message.group)
        
        VStack(spacing: 0) {
            // 支持滑动删除/归档的动态手势容器
            HStack {
                mainCardBody(theme: theme)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.translation.width < 0 {
                                    dragOffset = gesture.translation.width * 0.4
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    if dragOffset < -80 {
                                        // 触发手势归档行为（这里演示回弹）
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
            }
            
            // 优雅展开的回复交互坞 (Active Action Deck)
            if showActionTray {
                actionDockPanel(theme: theme)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal)
        // 卡片整体物理深度阴影与氛围流光
        .shadow(color: theme.accent.opacity(0.08), radius: 15, x: 0, y: 10)
    }
    
    // 卡片主板体 (Prism Board)
    @ViewBuilder
    private func mainCardBody(theme: BrandTheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // 1. 卡片首部 (Prism Header)
            HStack(alignment: .center, spacing: 12) {
                
                // 动态拟物理发光头像
                ZStack {
                    Circle()
                        .fill(theme.gradient)
                        .frame(width: 46, height: 46)
                        .shadow(color: theme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    if let iconName = message.icon, !iconName.isEmpty {
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: theme.logo)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // 右下角微光未读蓝点
                    if !message.read {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                            .offset(x: 16, y: 16)
                            .shadow(color: .cyan.opacity(0.8), radius: 3)
                    }
                }
                
                // 发送者与平台详情排版
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(message.url ?? "未知订阅源")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // 动态认证勋章
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(theme.accent)
                    }
                    
                    HStack(spacing: 6) {
                        Text(theme.name.uppercased())
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.accent.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.gradient.opacity(0.12))
                            .cornerRadius(4)
                        
                        if let host = message.url {
                            Text("@\(host.lowercased())")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                Spacer()
                
                // 航天级冷光生存表盘 (Aero-Dial TTL Tracker)
                if message.ttl > 0 && !message.isExpired {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(message.lifePercent))
                            .stroke(
                                theme.gradient,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: theme.accent.opacity(0.5), radius: 4)
                        
                        Text("\(Int(Double(message.ttl) * message.lifePercent))")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // 2. 被引用的源消息 (Quoted Origin / Thread Preview)
            if let reply = message.reply {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.gradient)
                        .frame(width: 3)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(message.url ?? "社交媒体对话")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(theme.accent)
                        
                        Text(reply)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                )
            }
            
            // 3. 消息文本核心区域 (Message Payload)
            VStack(alignment: .leading, spacing: 4) {
                if let title = message.title {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(message.body)
                    .font(.system(size: 13.5))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(3)
            }
            
            // 附带大图/媒体模块 (Media Content Preview)
            if let attachment = message.image {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 150)
                    
                    Image(systemName: attachment)
                        .font(.system(size: 32))
                        .foregroundColor(theme.accent.opacity(0.6))
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Label("富媒体卡片", systemImage: "photo.artframe")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.gradient.opacity(0.85))
                                .cornerRadius(6)
                                .padding(8)
                        }
                    }
                }
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            
            // 4. 底栏操作元数据与已读双勾 (Footer Deck)
            HStack(spacing: 8) {
                if let other = message.other {
                    Text(other)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(theme.accent.opacity(0.12))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(message.createDate, style: .time)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                
                // 双勾投递成功标记
                HStack(spacing: -3) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 8, weight: .black))
                .foregroundColor(theme.accent)
                .shadow(color: theme.accent.opacity(0.5), radius: 1)
            }
            .padding(.top, 2)
        }
        .padding(16)
        // 极高档超轻质感毛玻璃
        .background(.ultraThinMaterial)
        .cornerRadius(22)
        // 苹果级极细反光棱镜描边
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.05),
                            Color.black.opacity(0.1),
                            theme.accent.opacity(0.2)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // 三维动能交互微缩
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                showActionTray.toggle()
            }
        }
    }
    
    // 下部抽屉交互面板 (Interactive Action Deck)
    @ViewBuilder
    private func actionDockPanel(theme: BrandTheme) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // 快捷回复输入框
                HStack {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 12))
                        .foregroundColor(theme.accent)
                    
                    TextField("发送快捷回复...", text: $inputReplyText)
                        .font(.system(size: 12.5))
                        .foregroundColor(.white)
                        .onSubmit {
                            submitComment()
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
                
                // 发送按钮
                Button(action: submitComment) {
                    ZStack {
                        theme.gradient
                            .frame(width: 32, height: 32)
                            .cornerRadius(10)
                        
                        Image(systemName: isReplied ? "checkmark" : "paperplane.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // 辅助系统动作栏
            HStack(spacing: 20) {
                Button(action: {
                    if let urlStr = message.url, let url = URL(string: urlStr) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("跳转源头", systemImage: "safari.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    // 模拟静音推送源
                }) {
                    Label("静音该源", systemImage: "bell.slash.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .padding(.top, 14)
        .background(Color.black.opacity(0.2))
        .cornerRadius(18)
        .offset(y: -10)
        .padding(.horizontal, 12)
    }
    
    private func submitComment() {
        guard !inputReplyText.isEmpty else { return }
        withAnimation {
            isReplied = true
            inputReplyText = ""
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isReplied = false
            }
        }
    }
}

// MARK: - 精致奢华演示画廊
struct UniversalSocialShowcaseView: View {
    @State private var animateGlow = false
    @State private var mockMessages: [Message] = [
        Message(
            id: "msg_social_01",
            createDate: Date().addingTimeInterval(-10),
            group: "Instagram",
            title: "🔥 cristiano 上传了新的快照",
            subtitle: "cristiano • Threads",
            body: "“Stay focused, stay driven. ⚽💪 准备好迎接今晚的关键战役，全力以赴！”",
            icon: "camera.aperture",
            url: "https://instagram.com",
            image: "sparkles", // 模拟多媒体图片展示
            reply: "@leomessi: “Good luck, see you on pitch!”",
            ttl: 120,
            read: false,
            other: "❤️ 1.8M Likes"
        ),
        Message(
            id: "msg_social_02",
            createDate: Date().addingTimeInterval(-45),
            group: "X (Twitter)",
            title: "⚡ Elon Musk 刚刚发布了全新 Space X 火箭升空路径图",
            subtitle: "elonmusk • MainNet",
            body: "Starship Flight 7 trajectory calibration completed. Preparing ignition sequence for final orbital entry mock test.",
            icon: "sparkles",
            url: "https://x.com",
            image: nil,
            reply: nil,
            ttl: 300,
            read: true,
            other: "🔁 15.4K Retweets"
        ),
        Message(
            id: "msg_social_03",
            createDate: Date().addingTimeInterval(-240),
            group: "Discord",
            title: "👾 Midjourney Dev-Hub #announcements",
            subtitle: "midjourney • Server",
            body: "v7 Alpha build is officially live for testing. Incredible coherence, photorealistic rendering details, and 12x higher parsing speed. Check #beta-test channel.",
            icon: "bubble.left.and.bubble.right.fill",
            url: "https://discord.com",
            image: nil,
            reply: "Alpha keys dispatched to Premium tier members.",
            ttl: 3600,
            read: false,
            other: "🟢 8.4K Online"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. 底层静谧纯黑底色
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                // 2. 奢华霓虹霓变气泡 (折射穿透背景)
                ZStack {
                    // 左下偏光
                    Circle()
                        .fill(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .top, endPoint: .bottom))
                        .frame(width: 280, height: 280)
                        .blur(radius: animateGlow ? 75 : 95)
                        .offset(x: animateGlow ? -50 : -90, y: animateGlow ? 120 : 180)
                        .opacity(0.3)
                    
                    // 右上流光
                    Circle()
                        .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .top, endPoint: .bottom))
                        .frame(width: 300, height: 300)
                        .blur(radius: animateGlow ? 85 : 105)
                        .offset(x: animateGlow ? 70 : 110, y: animateGlow ? -150 : -200)
                        .opacity(0.25)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                        animateGlow.toggle()
                    }
                }
                
                // 3. 顶层卡片信息流
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Title Section
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("UNIVERSAL SOCIAL CHANNELS")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(2)
                                
                                Text("全平台社交消息流")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // 动态遍历消息卡片
                        ForEach(mockMessages) { msg in
                            SocialPremiumNotificationCard(message: msg)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark) // 必须处于深色暗黑美学中，毛玻璃水晶质感效果才完美
    }
}

// MARK: - 预览
struct GitHubNotificationCard_Previews1: PreviewProvider {
    static var previews: some View {
        UniversalSocialShowcaseView()
    }
}


