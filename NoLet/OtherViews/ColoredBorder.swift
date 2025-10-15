//
//  ColoredBorder.swift
//  pushback
//
//  Created by lynn on 2025/5/2.
//
import SwiftUI
import Foundation

struct ColoredBorder: View {
    var topLeft:Double
    var topRight:Double
    var bottomLeft:Double
    var bottomRight:Double
    var padding:Double
    var showAnimate:Bool = false
   
    
    init(lineWidth: Double = 3, topLeft: Double, topRight: Double, bottomLeft: Double, bottomRight: Double, padding:Double = 5) {
        self.lineWidth = lineWidth
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.padding = padding
    }
    init( lineWidth: Double = 3, left:Double ,right:Double, padding:Double = 5){
        self.lineWidth = lineWidth
        self.topLeft = left
        self.topRight = right
        self.bottomLeft = left
        self.bottomRight = right
        self.padding = padding
    }
    
    init(lineWidth: Double = 3, top:Double, bottom:Double, padding:Double = 5){
        self.lineWidth = lineWidth
        self.topLeft = top
        self.topRight = top
        self.bottomLeft = bottom
        self.bottomRight = bottom
        self.padding = padding
    }
    
    init(lineWidth: Double = 3, cornerRadius:Double? = nil, padding:Double = 5){
        self.lineWidth = lineWidth
        self.padding = padding
        if let cornerRadius{
            self.topLeft = cornerRadius
            self.topRight = cornerRadius
            self.bottomLeft = cornerRadius
            self.bottomRight = cornerRadius
        }else{
            let data:Double = ProcessInfo.processInfo.isiOSAppOnMac ? 5 : 50
            self.topLeft = data
            self.topRight = data
            self.bottomLeft = data
            self.bottomRight = data
        }
    }
    
    @State private var rotation:Double = 0
    @State private var lineWidth:Double = 3
    
    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: topLeft, bottomLeadingRadius: bottomLeft, bottomTrailingRadius: bottomRight, topTrailingRadius: topRight)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                    center: .center,
                    angle: .degrees(rotation)
                ),
                lineWidth: lineWidth
            )
            .padding(padding)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
