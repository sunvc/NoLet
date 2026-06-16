//
//  RotateButtonView.swift
//  NoLet
//
//  Created by lynn on 2025/7/21.

//
// import SwiftUI
// import AVFAudio
// struct RotateButtonView: View {
//    // rotating angle...
//    @State var angle: Double = 0
//    // 记录上一次的角度（用于计算增量）
//    @State var lastAngle: Double = 0
//
//    @State private var lastRotatedValue: Int = 0
//    var dotColor: (Int, Int) -> Color
//    var rotate:(Int)-> Void
//    var body: some View {
//
//        GeometryReader {
//            let width = $0.size.width
//            ZStack{
//
//                Circle()
//                    .fill(Color.gray.opacity(0.15))
//                    .frame(width: width, height: width)
//
//                ZStack{
//
//                    Circle()
//                        .fill(Color.black.gradient)
//                        .frame(width: width - 60, height: width - 60)
//                        .shadow(color: Color.white.opacity(0.2), radius: 5, x: 5, y: 5)
//                        .shadow(color: Color.white.opacity(0.2), radius: 5, x: -5, y: -5)
//                        .rotationEffect(.init(degrees: angle))
//
//                    Circle()
//                        .fill(.clear)
//                        .overlay(
//                               Circle()
//                                   .stroke(Color.gray.opacity(0.5), lineWidth: 2)
//                                   .overlay(
//                                       Circle()
//                                           .stroke(Color.gray.opacity(0.3), lineWidth: 6)
//                                           .blur(radius: 3)
//                                           .offset(x: 0, y: 3)
//                                           .mask(Circle().fill(LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]), startPoint: .top, endPoint: .bottom)))
//                                   )
//                        )
//
//                        .frame(width: 50, height: 50)
//                    // moving view left...
//                        .offset(x: (width - 150) / 2)
//                        .rotationEffect(.init(degrees: angle))
//                    // adding gesture...
//                        .gesture(
//                            DragGesture(minimumDistance: 0).onChanged(onChanged(value:))
//                                .onEnded({ value in
//                                    withAnimation(Animation.bouncy(duration: 0.1, extraBounce: 0.3)) {
//                                        self.angle = 0
//                                        self.lastAngle = 0
//                                    }
//                                    Haptic.notify(.success)
//
//                                })
//                        )
//
//                    // 240 - 30 = 210...
//                    // rotaing to start point...
//                        .rotationEffect(.init(degrees: -210))
//
//                }
//
//                ZStack{
//
//                    let highlightCount = abs(Int(angle) % 360) / 12 + 1
//                    // dots....
//                    ForEach(0...29,id: \.self){index in
//
//                        ZStack{
//                            Capsule()
//                                .fill( dotColor(0, Int(angle)))
//
//                            if angle > 0{
//                                Capsule()
//                                    .fill( Int(angle) % 360 / 12 + 1 > index ? dotColor(1,
//                                    Int(angle)) : .clear)
//                            }else{
//                                // 反向点亮从后往前
//                                if index >= 30 - highlightCount {
//                                    Capsule()
//                                        .fill(dotColor(1, Int(angle)))
//                                }
//                            }
//
//
//                        }
//                        .frame(width: 10, height: 10)
//                        .offset(x: -(width + 10) / 2)
//                        .rotationEffect(.init(degrees: Double(index) * 12 - 24 ))
//
//                    }
//                }
//
//            }
//
//        }
//        .onChange(of: angle) { newValue in
//            let roundedValue = Int(newValue)
//            if roundedValue != lastRotatedValue {
//                rotate(roundedValue)
//                lastRotatedValue = roundedValue
//            }
//        }
//    }
//
//    func onChanged(value: DragGesture.Value) {
//        let translation = value.location
//        let vector = CGVector(dx: translation.x, dy: translation.y)
//        let radians = atan2(vector.dy - 10, vector.dx - 10)
//
//        var currentAngle = radians * 180 / .pi
//
//        // 确保角度在0-360°之间
//        if currentAngle < 0 { currentAngle += 360 }
//
//        // 计算增量（当前角度 - 上次角度）
//        var deltaAngle = currentAngle - lastAngle
//
//        // 处理跨过360°边界的情况（避免突变）
//        if deltaAngle > 180 {
//            deltaAngle -= 360
//        } else if deltaAngle < -180 {
//            deltaAngle += 360
//        }
//
//        self.angle += deltaAngle
//        self.lastAngle = currentAngle
//
//    }
//
// }

import AVFAudio
import SwiftUI

struct RotateButtonView: View {
    // 旋转角度
    @State private var angle: Double = 0
    // 记录上一次的手势绝对角度
    @State private var lastAngle: Double = 0
    // 标记是否是手势的第一帧（防止点下时突变）
    @State private var isDragging: Bool = false

    @State private var lastRotatedValue: Int = 0

    var rotate: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let center = width / 2 // 稳定的中心点

            ZStack {
                // 背景大圆
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: width, height: width)

                ZStack {
                    // 内层旋转旋钮主体
                    Circle()
                        .fill(Color.black.gradient)
                        .frame(width: width - 60, height: width - 60)
                        .shadow(color: Color.white.opacity(0.2), radius: 5, x: 5, y: 5)
                        .shadow(color: Color.white.opacity(0.2), radius: 5, x: -5, y: -5)
                        .rotationEffect(.init(degrees: angle))

                    // 旋钮上的小凹槽点（供手指触摸）
                    Circle()
                        .fill(.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                                        .blur(radius: 3)
                                        .offset(x: 0, y: 3)
                                        .mask(Circle().fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.black, Color.clear]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )))
                                )
                        )
                        .frame(width: 50, height: 50)
                        .offset(x: (width - 150) / 2)
                        .rotationEffect(.init(degrees: angle))
                        // 初始摆放偏角偏转
                        .rotationEffect(.init(degrees: -210))
                }
                // 【关键改动 1】：将手势挂在整个大容器 ZStack 上，或者利用透明蒙版捕获，
                // 这样无论按钮怎么转，手势判断都在稳定的固定坐标系中进行。
                .background(Circle().fill(Color.clear))
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("knobContainer"))
                        .onChanged { value in
                            onChanged(value: value, center: center)
                        }
                        .onEnded { _ in
                            withAnimation(.bouncy(duration: 0.1, extraBounce: 0.3)) {
                                self.angle = 0
                                self.lastAngle = 0
                            }
                            isDragging = false
                        }
                )

                // 周围的指示灯刻度圈
                ZStack {
                    let highlightCount = min(abs(Int(angle) % 360) / 12 + 1, 30)

                    ForEach(0...29, id: \.self) { index in
                        ZStack {
                            Capsule()
                                .fill(dotColor(0, Int(angle)))

                            if angle > 0 {
                                Capsule()
                                    .fill((Int(angle) % 360 / 12 + 1) > index ? dotColor(
                                        1,
                                        Int(angle)
                                    ) : .clear)
                            } else {
                                if index >= 30 - highlightCount {
                                    Capsule()
                                        .fill(dotColor(1, Int(angle)))
                                }
                            }
                        }
                        .frame(width: 10, height: 10)
                        .offset(x: -(width + 10) / 2)
                        .rotationEffect(.init(degrees: Double(index) * 12 - 24))
                    }
                }
            }
            // 【关键改动 2】：定义稳定的命名坐标空间
            .coordinateSpace(name: "knobContainer")
        }
        .onChange(of: angle) { newValue in
            let roundedValue = Int(newValue)
            if roundedValue != lastRotatedValue {
                rotate(roundedValue)
                lastRotatedValue = roundedValue
            }
        }
    }

    // 动态传入中心点，计算平滑旋转
    private func onChanged(value: DragGesture.Value, center: CGFloat) {
        let touchLocation = value.location

        // 基于精准且固定的外层中轴线建立向量
        let vector = CGVector(dx: touchLocation.x - center, dy: touchLocation.y - center)

        // 防止用户手势完美点在绝对中心导致 atan2 分母为0崩溃或计算异常
        guard vector.dx != 0 || vector.dy != 0 else { return }

        let radians = atan2(vector.dy, vector.dx)

        var currentAngle = radians * 180 / .pi
        if currentAngle < 0 { currentAngle += 360 }

        // 如果是刚触碰的第一帧，初始化角度，不计算增量（避免闪跳）
        if !isDragging {
            lastAngle = currentAngle
            isDragging = true
            return
        }

        // 计算角度增量
        var deltaAngle = currentAngle - lastAngle

        // 处理 0° / 360° 突变边界的平滑过渡
        if deltaAngle > 180 {
            deltaAngle -= 360
        } else if deltaAngle < -180 {
            deltaAngle += 360
        }

        self.angle += deltaAngle
        self.lastAngle = currentAngle
    }
    
    func dotColor(_ upNumber: Int = 0, _ angle: Int) -> Color {
        let colors: [Color] = [
            .gray.opacity(0.5), .green, .teal, .blue, .yellow, .orange, .purple, .red,
        ] + Array(repeating: Color.red, count: 20)

        let number = abs(Int(angle / 360)) + upNumber
        let index = number % colors.count
        return colors[index]
    }
}

#Preview {
    PushToTalkView()
}
