//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - ContentBackgroundView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 17:37.
    
import SwiftUI

struct TiffanyBlueBackground: View {
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
                    LinearGradient(
                        colors: [topGradient, bottomGradient],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    Canvas { graphicsContext, size in
                        guard w > 0 && h > 0 else { return }

                        graphicsContext.addFilter(.blur(radius: 45))
                        graphicsContext.addFilter(.alphaThreshold(min: 0.43, color: liquidColor))

                        graphicsContext.drawLayer { layerContext in
                            
                            let size1 = min(w, h) * 0.45
                            let cx1 = w * 0.5 + CGFloat(sin(time * 0.4)) * (w * 0.08)
                            let cy1 = h * 0.4 + CGFloat(cos(time * 0.5)) * (h * 0.08)
                            drawBlob(in: layerContext, x: cx1, y: cy1, size: size1)

                            let size2 = min(w, h) * 0.32
                            let cx2 = w * 0.25 + CGFloat(cos(time * 0.7 + 1.2)) * (w * 0.15)
                            let cy2 = h * 0.3 + CGFloat(sin(time * 0.5 + 0.8)) * (h * 0.22)
                            drawBlob(in: layerContext, x: cx2, y: cy2, size: size2)

                            let size3 = min(w, h) * 0.35
                            let cx3 = w * 0.75 + CGFloat(sin(time * 0.6 + 2.5)) * (w * 0.18)
                            let cy3 = h * 0.6 + CGFloat(cos(time * 0.8 + 1.7)) * (h * 0.25)
                            drawBlob(in: layerContext, x: cx3, y: cy3, size: size3)

                            let size4 = min(w, h) * 0.22
                            let cx4 = w * 0.5 + CGFloat(sin(time * 1.3 + 4.0)) * (w * 0.35)
                            let cy4 = h * 0.2 + CGFloat(cos(time * 1.1 + 3.1)) * (h * 0.15)
                            drawBlob(in: layerContext, x: cx4, y: cy4, size: size4)

                            let size5 = min(w, h) * 0.26
                            let cx5 = w * 0.4 + CGFloat(cos(time * 0.9 + 5.5)) * (w * 0.3)
                            let cy5 = h * 0.75 + CGFloat(sin(time * 1.2 + 0.5)) * (h * 0.18)
                            drawBlob(in: layerContext, x: cx5, y: cy5, size: size5)
                        }
                    }
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.85, blue: 0.83),
                                Color(red: 0.35, green: 0.78, blue: 0.80),
                                Color(red: 0.65, green: 0.92, blue: 0.88),
                                Color(red: 0.20, green: 0.60, blue: 0.65),
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
            with: .color(.white)
        )
    }
}

// MARK: - Preview
struct PremiumBlobThemeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            TiffanyBlueBackground()
            
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Tiffany Blossom")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.85))
                        Spacer()
                        Image(systemName: "drop.fill")
                            .foregroundColor(Color(red: 0.35, green: 0.78, blue: 0.80))
                    }

                    Text("当前画布已注入多轨不规则频率算法。5 个独立的流体微粒在全屏进行随机拓扑游走，碰撞时会触发高张力的液态拉丝与吞噬合并效果。")
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .foregroundColor(.black.opacity(0.6))

                    Button(action: {}) {
                        Text("进入奇幻空间")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Capsule().fill(Color(red: 0.25, green: 0.70, blue: 0.72)))
                    }
                    .padding(.top, 8)
                }
                .padding(28)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.6), lineWidth: 1)
                )
                .padding(24)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
            }
        }
        
    }
}

