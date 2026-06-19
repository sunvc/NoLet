//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - AuroraThemeBackground.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 17:19.
    

import SwiftUI

// MARK: - 1. 背景主题视图
struct AuroraThemeBackground: View {
    @State private var phase: Double = 0.0
    
    // 主题配色方案（可自由更换）
    let topColor = Color(red: 0.12, green: 0.08, blue: 0.32)      // 深邃夜空紫
    let blobColor1 = Color(red: 0.25, green: 0.45, blue: 0.95)    // 霓虹梦幻蓝
    let blobColor2 = Color(red: 0.85, green: 0.25, blue: 0.65)    // 极光魅惑粉
    let blobColor3 = Color(red: 0.30, green: 0.85, blue: 0.70)    // 薄荷发光绿

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { graphicsContext, size in
                let width = CGFloat(size.width)
                let height = CGFloat(size.height)
                
                // 确保尺寸有效
                guard width > 0 && height > 0 else { return }
                
                // 1. 绘制底层基础渐变
                let baseGradient = GraphicsContext.Shading.linearGradient(
                    Gradient(colors: [topColor, .mint]),
                    startPoint: CGPoint(x: 0.0, y: 0.0),
                    endPoint: CGPoint(x: 0.0, y: height)
                )
                graphicsContext.fill(Path(CGRect(origin: .zero, size: size)), with: baseGradient)
                
                // 2. 开启模糊滤镜，制造绚丽的晕染网格效果（Mesh Effect）
                graphicsContext.addFilter(.blur(radius: 70))
                
                // 在隔离层绘制流光粒子
                graphicsContext.drawLayer { layerContext in
                    
                    // 粒子 A：左上角蓝色流光
                    let xA = width * 0.2 + CGFloat(sin(phase * 0.5)) * 50.0
                    let yA = height * 0.2 + CGFloat(cos(phase * 0.6)) * 60.0
                    let radiusA = CGFloat(max(width, height) * 0.4)
                    layerContext.fill(
                        Path(ellipseIn: CGRect(x: xA - radiusA, y: yA - radiusA, width: radiusA * 2.0, height: radiusA * 2.0)),
                        with: .color(blobColor1.opacity(0.6))
                    )
                    
                    // 粒子 B：右下角粉色流光
                    let xB = width * 0.8 + CGFloat(cos(phase * 0.4)) * 60.0
                    let yB = height * 0.7 + CGFloat(sin(phase * 0.7)) * 50.0
                    let radiusB = CGFloat(max(width, height) * 0.45)
                    layerContext.fill(
                        Path(ellipseIn: CGRect(x: xB - radiusB, y: yB - radiusB, width: radiusB * 2.0, height: radiusB * 2.0)),
                        with: .color(blobColor2.opacity(0.5))
                    )
                    
                    // 粒子 C：中间发光绿（起点缀作用，透明度较低）
                    let xC = width * 0.5 + CGFloat(sin(phase * 0.8)) * 40.0
                    let yC = height * 0.45 + CGFloat(cos(phase * 0.5)) * 40.0
                    let radiusC = CGFloat(max(width, height) * 0.3)
                    layerContext.fill(
                        Path(ellipseIn: CGRect(x: xC - radiusC, y: yC - radiusC, width: radiusC * 2.0, height: radiusC * 2.0)),
                        with: .color(blobColor3.opacity(0.4))
                    )
                }
            }
            .ignoresSafeArea()
            .onAppear {
                phase = 0.0
            }
            .onChange(of: context.date) {newDate in
                // 使用时间戳驱动丝滑的动画
                phase = newDate.timeIntervalSinceReferenceDate
            }
        }
    }
}

#Preview{
    AuroraThemeBackground()
}
