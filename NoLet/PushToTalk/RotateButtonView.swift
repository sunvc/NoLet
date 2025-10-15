//
//  RotateButtonView.swift
//  pushme
//
//  Created by lynn on 2025/7/21.


import SwiftUI
import AVFAudio
struct RotateButtonView: View {
    // rotating angle...
    @State var angle: Double = 0
    // 记录上一次的角度（用于计算增量）
    @State var lastAngle: Double = 0
    
    @State private var lastRotatedValue: Int = 0
    var dotColor: (Int, Int) -> Color
    var rotate:(Int)-> Void
    var body: some View {
   
        GeometryReader {
            let width = $0.size.width
            ZStack{
                
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: width, height: width)
                
                ZStack{
                    
                    Circle()
                        .fill(Color.black.gradient)
                        .frame(width: width - 60, height: width - 60)
                        .shadow(color: Color.white.opacity(0.2), radius: 5, x: 5, y: 5)
                        .shadow(color: Color.white.opacity(0.2), radius: 5, x: -5, y: -5)
                        .rotationEffect(.init(degrees: angle))
                    
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
                                           .mask(Circle().fill(LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]), startPoint: .top, endPoint: .bottom)))
                                   )
                        )
                    
                        .frame(width: 50, height: 50)
                    // moving view left...
                        .offset(x: (width - 150) / 2)
                        .rotationEffect(.init(degrees: angle))
                    // adding gesture...
                        .gesture(
                            DragGesture(minimumDistance: 0).onChanged(onChanged(value:))
                                .onEnded({ value in
                                    withAnimation(Animation.bouncy(duration: 0.1, extraBounce: 0.3)) {
                                        self.angle = 0
                                        self.lastAngle = 0
                                    }
                                    Haptic.notify(.success)
                                    
                                })
                        )
                    
                    // 240 - 30 = 210...
                    // rotaing to start point...
                        .rotationEffect(.init(degrees: -210))
                    
                }
                
                ZStack{
                  
                    let highlightCount = abs(Int(angle) % 360) / 12 + 1
                    // dots....
                    ForEach(0...29,id: \.self){index in
                        
                        ZStack{
                            Capsule()
                                .fill( dotColor(0, Int(angle)))
                            
                            if angle > 0{
                                Capsule()
                                    .fill( Int(angle) % 360 / 12 + 1 > index ? dotColor(1, Int(angle)) : .clear)
                            }else{
                                // 反向点亮从后往前
                                if index >= 30 - highlightCount {
                                    Capsule()
                                        .fill(dotColor(1, Int(angle)))
                                }
                            }
                            
                            
                        }
                        .frame(width: 10, height: 10)
                        .offset(x: -(width + 10) / 2)
                        .rotationEffect(.init(degrees: Double(index) * 12 - 24 ))
                            
                    }
                }
                
            }
            
        }
        .onChange(of: angle) { newValue in
            let roundedValue = Int(newValue)
            if roundedValue != lastRotatedValue {
                rotate(roundedValue)
                lastRotatedValue = roundedValue
            }
        }
    }
    
    func onChanged(value: DragGesture.Value) {
        let translation = value.location
        let vector = CGVector(dx: translation.x, dy: translation.y)
        let radians = atan2(vector.dy - 10, vector.dx - 10)
        
        var currentAngle = radians * 180 / .pi
        
        // 确保角度在0-360°之间
        if currentAngle < 0 { currentAngle += 360 }
        
        // 计算增量（当前角度 - 上次角度）
        var deltaAngle = currentAngle - lastAngle
        
        // 处理跨过360°边界的情况（避免突变）
        if deltaAngle > 180 {
            deltaAngle -= 360
        } else if deltaAngle < -180 {
            deltaAngle += 360
        }
        
        self.angle += deltaAngle
        self.lastAngle = currentAngle
        
    }
    
}

#Preview {
    PushToTalkView()
}
