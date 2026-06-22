//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - WebRTCView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/22 17:07.
    
import SwiftUI
import Combine

enum WebRTCScreenState {
    case dial // 拨号键盘
    case calling // 主动呼叫复合页面 (呼叫中 ➔ 通话中 / 呼叫失败)
    case incoming // 模拟来电复合页面 (来电中 ➔ 正在接通 ➔ 通话中 / 接听失败)
}

// MARK: - 主容器视图

struct WebRTCView: View {
    @State private var currentScreen: WebRTCScreenState = .dial
    @State private var phoneNumber: String = ""

    

    var body: some View {
        ZStack {
            switch currentScreen {
            case .dial:
                DialView(phoneNumber: $phoneNumber, onCall: {
                    currentScreen = .calling
                }, simulateIncoming: {
                    phoneNumber = "张三"
                    currentScreen = .incoming
                })

            case .calling:
                CallView(name: phoneNumber, isPresented: $currentScreen)

            case .incoming:
                IncomingCallView(name: phoneNumber, isPresented: $currentScreen)
            }
        }
        .background(DynamicBlobView())
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentScreen)
    }
}

// MARK: - 1. 拨号键盘页面

struct DialView: View {
    @Binding var phoneNumber: String
    var onCall: () -> Void
    var simulateIncoming: () -> Void
    
    // 保持扁平的一维数组，方便 Grid 循环处理（或者维持原样亦可）
    let buttons = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["*", "0", "#"]]

    var body: some View {
        VStack(spacing: 20) {
            // 顶部模拟按钮
            HStack {
                Spacer()
                Button(action: simulateIncoming) {
                    Text("模拟来电 🔔")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassCard()
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 号码显示区域
            Text(phoneNumber.isEmpty ? " " : phoneNumber)
                .font(.system(size: 44, weight: .light, design: .rounded))
                .lineLimit(1)
                .frame(height: 60)
            
            Spacer()
            
            // MARK: - 核心修改：使用 Grid 网格系统
            Grid(horizontalSpacing: 28, verticalSpacing: 18) {
                // 1. 渲染前 4 行数字与符号键
                ForEach(buttons, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                if phoneNumber.count < 15 { phoneNumber.append(key) }
                            }) {
                                Text(key)
                                    .font(.system(size: 32, weight: .regular))
                                    .frame(width: 78, height: 78)
                                    .glassCard(50, padding: 0, borderColor: .gray)
                                    .tint(.primary)
                            }
                        }
                    }
                }
                
                // 2. 渲染底部控制栏（呼叫键与删除键）
                GridRow {
                    // 左侧用空视图占 1 列宽度，保持整体平移对称，或作为美学留白
                    Color.clear
                        .frame(width: 78, height: 78)
                    
                    // 中间：呼叫按钮 (对应键盘中间列 '8' 和 '0' 的垂直中轴线)
                    Button(action: { if !phoneNumber.isEmpty { onCall() } }) {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .frame(width: 78, height: 78)
                            .glassCard(50)
                            .foregroundColor(phoneNumber.isEmpty ? .secondary : .green) // 有输入时变绿提示
                            .clipShape(Circle())
                    }
                    .disabled(phoneNumber.isEmpty)
                    
                    // 右侧：删除按钮
                    Button(action: { if !phoneNumber.isEmpty { phoneNumber.removeLast() } }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title3)
                            .frame(width: 78, height: 78) // 修正回 78x78 保持视觉上完美的对齐
                            .foregroundColor(.primary)
                            .glassCard(50)
                    }
                }
            }
            .padding(.bottom, 40)
            
            Spacer()
        }
    }
}

// MARK: - 2. 主动呼叫页面 (集成：呼叫中 ➔ 通话中 / 新增：呼叫失败)

struct CallView: View {
    var name: String
    @Binding var isPresented: WebRTCScreenState

    enum CallStatus {
        case calling // 正在呼叫
        case active // 通话中
        case failed // 呼叫失败
    }

    @State private var currentStatus: CallStatus = .calling
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var callDuration = 0
    @State private var scaleEffect = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()

            // 头像及特效区域
            ZStack {
                if currentStatus == .calling {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .scaleEffect(scaleEffect ? 1.3 : 1.0)
                        .opacity(scaleEffect ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                            value: scaleEffect
                        )
                } else if currentStatus == .failed {
                    // 呼叫失败：红色警示呼吸圈
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 130, height: 130)
                }

                Circle()
                    .fill(.background.opacity(0.5))
                    .frame(width: 110, height: 110)

                Image(systemName: "person")
                    .font(.system(size: 45))
                    .foregroundColor(.primary)
            }.onAppear { scaleEffect = true }

            // 文本及状态融合
            VStack(spacing: 8) {
                Text(name.isEmpty ? "未知号码" : name)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.primary)

                switch currentStatus {
                case .calling:
                    Text("正在呼叫...")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                case .active:
                    Text(formatTimeString(seconds: callDuration))
                        .font(.system(
                            size: 20,
                            weight: .regular,
                            design: .monospaced
                        ))
                        .foregroundColor(.primary)
                case .failed:
                    Text("呼叫失败，对方无应答")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.red.opacity(0.8))
                }
            }
            .padding(.top, 16)
            .animation(.easeInOut(duration: 0.3), value: currentStatus)

            // 音波插槽
            Group {
                if currentStatus == .active {
                    AudioVisualizerView().padding(.vertical, 30)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else { Spacer().frame(height: 120) }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStatus)

            Spacer()
            CallBottomsView(isMuted: $isMuted, isSpeakerOn: $isSpeakerOn) { 
                isPresented = .dial
            }
        }
        .onReceive(timer) { _ in if currentStatus == .active { callDuration += 1 } }
        .onAppear {
            // 【模拟逻辑】：如果是测试号码 "404"，模拟呼叫失败；其他号码 2秒后正常接通
            if name == "404" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { currentStatus = .failed }
                    // 失败展示 2.5 秒后自动退回拨号盘
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { isPresented = .dial }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { currentStatus = .active }
                }
            }
        }
    }

    func formatTimeString(seconds: Int) -> String { String(
        format: "%02d:%02d",
        seconds / 60,
        seconds % 60
    ) }
}

// MARK: - 3. 被动来电页面 (来电中 ➔ 正在接通 ➔ 通话中 / 新增：接听失败)

struct IncomingCallView: View {
    var name: String
    @Binding var isPresented: WebRTCScreenState

    enum IncomingStatus {
        case ringing // 来电振铃中
        case connecting // 正在接通中
        case active // 正在通话中
        case failed // 接听失败
    }

    @State private var currentStatus: IncomingStatus = .ringing
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var callDuration = 0
    @State private var scaleEffect = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()

            // 动态头像环境
            ZStack {
                if currentStatus == .ringing {
                    Circle()
                        .fill(Color.blue.opacity(0.12)).frame(width: 160, height: 160)
                        .scaleEffect(scaleEffect ? 1.25 : 1.0).opacity(scaleEffect ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: false),
                            value: scaleEffect
                        )
                } else if currentStatus == .connecting {
                    Circle()
                        .stroke(Color.primary.opacity(0.05), lineWidth: 2).frame(
                            width: 130,
                            height: 130
                        )
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(Angle(degrees: scaleEffect ? 360 : 0))
                        .animation(
                            .linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: scaleEffect
                        )
                } else if currentStatus == .failed {
                    // 接听失败红色背晕
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 130, height: 130)
                }

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                    .overlay(Circle().stroke(
                        currentStatus == .failed ? Color.red.opacity(0.5) : Color.primary
                            .opacity(0.12),
                        lineWidth: 1
                    ))
                Image(systemName: "person.fill").font(.system(size: 45))
                    .foregroundColor(.primary.opacity(0.5))
            }
            .onAppear { scaleEffect = true }

            // 文本状态切换
            VStack(spacing: 8) {
                Text(name.isEmpty ? "未知来电" : name)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.primary)

                switch currentStatus {
                case .ringing:
                    Text("来电中... 北京, 中国").font(.system(size: 16))
                        .foregroundColor(.primary)
                case .connecting:
                    Text("正在接通...")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                case .active:
                    Text(formatTimeString(seconds: callDuration))
                        .font(.system(
                            size: 20,
                            weight: .regular,
                            design: .monospaced
                        ))
                        .foregroundColor(.primary.opacity(0.5))
                case .failed:
                    Text("接听失败，连接中断")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 16)
            .animation(.easeInOut(duration: 0.3), value: currentStatus)

            // 正弦音波
            Group {
                if currentStatus == .active {
                    AudioVisualizerView()
                        .padding(.vertical, 30)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else { Spacer().frame(height: 120) }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStatus)

            Spacer()

            // 底部动态控制面板切换
            ZStack {
                if currentStatus == .ringing {
                    HStack {
                        VStack(spacing: 12) {
                            Button(action: { isPresented = .dial }) {
                                Image(systemName: "phone.down.fill").font(.title3).frame(
                                    width: 72,
                                    height: 72
                                )
                                .background(Color.red.opacity(0.9))
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                            }
                            Text("拒绝")
                                .font(.system(size: 13))
                                .foregroundColor(.primary.opacity(0.6))
                        }
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                withAnimation { currentStatus = .connecting }

                                // 【模拟逻辑】：如果是特殊人名 "未知号码" 或者是 "404" 触发接听失败；其余正常接通
                                if name == "404" || name == "未知号码" {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { currentStatus = .failed }
                                        // 停留 2.5 秒错误警告，自动退出
                                        DispatchQueue.main
                                            .asyncAfter(deadline: .now() + 2.5) {
                                                isPresented = .dial
                                            }
                                    }
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        withAnimation { currentStatus = .active }
                                    }
                                }
                            }) {
                                Image(systemName: "phone.fill").font(.title3).frame(
                                    width: 72,
                                    height: 72
                                )
                                .background(Color.green.opacity(0.9))
                                .foregroundColor(.primary)
                                .clipShape(Circle())
                            }
                            Text("接听")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Spacer()
                    CallBottomsView(isMuted: $isMuted, isSpeakerOn: $isSpeakerOn) { 
                        isPresented = .dial
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentStatus)
        }
        .onReceive(timer) { _ in if currentStatus == .active { callDuration += 1 } }
    }

    func formatTimeString(seconds: Int) -> String { String(
        format: "%02d:%02d",
        seconds / 60,
        seconds % 60
    ) }
}

// MARK: - 辅助组件：动态正弦波形

struct SineWaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width, height = rect.height, midY = height / 2
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * frequency * .pi * 2 + phase)
            path.addLine(to: CGPoint(x: x, y: midY + sine * amplitude))
        }
        return path
    }
}

struct AudioVisualizerView: View {
    @State private var phase: CGFloat = 0.0

    // 【核心改动】为三层波形定义完全独立的振幅（高度）状态
    @State private var amplitude1: CGFloat = 10.0
    @State private var amplitude2: CGFloat = 15.0
    @State private var amplitude3: CGFloat = 6.0

    // 使用三个不同的时间间隔，让它们高矮交错，绝不同步
    let timer1 = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()
    let timer2 = Timer.publish(every: 0.48, on: .main, in: .common).autoconnect()
    let timer3 = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 第一层：暗绿底波（频率低，波动慢，高度适中）
            SineWaveShape(phase: phase, amplitude: amplitude1, frequency: 1.2)
                .stroke(Color.green.opacity(0.15), lineWidth: 1.5)
                .onReceive(timer1) { _ in
                    withAnimation(.easeInOut(duration: 0.33)) {
                        amplitude1 = CGFloat.random(in: 6...18)
                    }
                }

            // 第二层：亮绿主波（核心视觉，相位相反，波动频率中等，高度最高）
            SineWaveShape(phase: -phase * 1.3, amplitude: amplitude2, frequency: 1.8)
                .stroke(Color.green.opacity(0.45), lineWidth: 2)
                .onReceive(timer2) { _ in
                    withAnimation(.easeInOut(duration: 0.45)) {
                        amplitude2 = CGFloat.random(in: 10...28) // 给予更大的起伏空间
                    }
                }

            // 第三层：白色微波（高频快节奏，负责丰富细节，高度较矮）
            SineWaveShape(phase: phase * 0.7, amplitude: amplitude3, frequency: 2.5)
                .stroke(Color.primary.opacity(0.25), lineWidth: 1)
                .onReceive(timer3) { _ in
                    withAnimation(.linear(duration: 0.22)) { // 速度快，用 linear 更有跳动感
                        amplitude3 = CGFloat.random(in: 3...10)
                    }
                }
        }
        .frame(height: 80)
        .onAppear {
            // 基础动画：保持波浪永无止境地平移滚动
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Preview

struct CallBottomsView: View {
    @Binding var isMuted: Bool
    @Binding var isSpeakerOn: Bool
    var action: () -> Void
    var body: some View {
        // 底部控制舱
        HStack(spacing: 0) {
            Button(action: { isMuted.toggle() }) {
                VStack(spacing: 6) {
                    Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 22)).frame(
                            width: 56,
                            height: 56
                        )
                        .glassCard(50)
                        .foregroundColor(isMuted ? Color.red : .primary)
                        .clipShape(Circle())
                    Text(isMuted ? "已静音" : "静音")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.4))
                }
            }.frame(maxWidth: .infinity)

            Button(action: action) {
                Image(systemName: "phone.down.fill")
                    .font(.title2).frame(width: 76, height: 76)
                    .background(Color.red.opacity(0.9))
                    .foregroundColor(.primary)
                    .clipShape(Circle())
                    .shadow(
                        color: Color.red.opacity(0.3),
                        radius: 15,
                        x: 0,
                        y: 5
                    )
            }.frame(width: 90)

            Button(action: { isSpeakerOn.toggle() }) {
                VStack(spacing: 6) {
                    Image(systemName: isSpeakerOn ? "speaker.wave.3.fill" :
                        "speaker.wave.1.fill")
                        .font(.system(size: 20)).frame(
                            width: 56,
                            height: 56
                        )
                        .glassCard(50)
                        .foregroundColor(.primary)
                        .clipShape(Circle())
                    Text("扬声器")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.4))
                }
            }.frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24).padding(.horizontal, 16)
        .glassCard(35)
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
}

struct DynamicBlobView: View {
    @State private var time: Double = 0.0

    let liquidColor = Color("PTTLiquidColor")
    let topGradient = Color("PTTBackgroundTop")
    let bottomGradient = Color("PTTBackgroundBottom")

    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height

                ZStack {
                    // 1. 底层：纯净的高级优雅渐变
                    LinearGradient(
                        colors: [topGradient, bottomGradient],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // 2. 核心层：超强果冻感 Canvas
                    Canvas { graphicsContext, _ in
                        guard w > 0 && h > 0 else { return }

                        // 【高级感果冻核心滤镜】
                        graphicsContext.addFilter(.blur(radius: 45))
                        graphicsContext.addFilter(.alphaThreshold(min: 0.43, color: liquidColor))

                        graphicsContext.drawLayer { layerContext in
                            // --- 核心球 1 (中央大型锚点，小幅度不规则晃动) ---
                            let size1 = min(w, h) * 0.45
                            let cx1 = w * 0.5 + CGFloat(sin(time * 0.4)) * (w * 0.08)
                            let cy1 = h * 0.4 + CGFloat(cos(time * 0.5)) * (h * 0.08)
                            drawBlob(in: layerContext, x: cx1, y: cy1, size: size1)

                            // --- 游走球 2 (左侧中型球，大范围纵向不规则移动) ---
                            let size2 = min(w, h) * 0.32
                            let cx2 = w * 0.25 + CGFloat(cos(time * 0.7 + 1.2)) * (w * 0.15)
                            let cy2 = h * 0.3 + CGFloat(sin(time * 0.5 + 0.8)) * (h * 0.22)
                            drawBlob(in: layerContext, x: cx2, y: cy2, size: size2)

                            // --- 游走球 3 (右侧中型球，大范围横向不规则移动) ---
                            let size3 = min(w, h) * 0.35
                            let cx3 = w * 0.75 + CGFloat(sin(time * 0.6 + 2.5)) * (w * 0.18)
                            let cy3 = h * 0.6 + CGFloat(cos(time * 0.8 + 1.7)) * (h * 0.25)
                            drawBlob(in: layerContext, x: cx3, y: cy3, size: size3)

                            // --- 游走球 4 (顶部小型微粒，高频斜向穿梭) ---
                            let size4 = min(w, h) * 0.22
                            let cx4 = w * 0.5 + CGFloat(sin(time * 1.3 + 4.0)) * (w * 0.35)
                            let cy4 = h * 0.2 + CGFloat(cos(time * 1.1 + 3.1)) * (h * 0.15)
                            drawBlob(in: layerContext, x: cx4, y: cy4, size: size4)

                            // --- 游走球 5 (底部小型微粒，负责下方的拉丝融合) ---
                            let size5 = min(w, h) * 0.26
                            let cx5 = w * 0.4 + CGFloat(cos(time * 0.9 + 5.5)) * (w * 0.3)
                            let cy5 = h * 0.75 + CGFloat(sin(time * 1.2 + 0.5)) * (h * 0.18)
                            drawBlob(in: layerContext, x: cx5, y: cy5, size: size5)
                        }
                    }
                    // 只在果冻身体里渲染蒂芙尼蓝的高级流光溢彩
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.85, blue: 0.83), // 标准蒂芙尼蓝
                                Color(red: 0.35, green: 0.78, blue: 0.80), // 略深的青蓝
                                Color(red: 0.65, green: 0.92, blue: 0.88), // 发光的薄荷绿
                                Color(red: 0.20, green: 0.60, blue: 0.65), // 暗部过渡绿
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.sourceAtop)
                    )
                    .drawingGroup()
                }
            }
            .onAppear {
                time = 0.0
            }
            .onChange(of: context.date) { newDate in
                time = newDate.timeIntervalSinceReferenceDate
            }
        }
        .ignoresSafeArea()
    }

    // 封装的强类型果冻球绘制函数，完美避免编译歧义
    private func drawBlob(in context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat) {
        context.fill(
            Path(ellipseIn: CGRect(
                x: x - size / 2,
                y: y - size / 2,
                width: size,
                height: size
            )),
            with: .color(.primary)
        )
    }
}

#Preview{
    WebRTCView()
}
