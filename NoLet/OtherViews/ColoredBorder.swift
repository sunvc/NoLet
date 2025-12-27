//
//  ColoredBorder.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/2.
//

import SwiftUI

struct ColoredBorder: View {
    var topLeft: Double
    var topRight: Double
    var bottomLeft: Double
    var bottomRight: Double
    var padding: Double
    var showAnimate: Bool = false

    init(
        lineWidth: Double = 3,
        topLeft: Double,
        topRight: Double,
        bottomLeft: Double,
        bottomRight: Double,
        padding: Double = 1
    ) {
        self.lineWidth = lineWidth
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.padding = padding
    }

    init(lineWidth: Double = 3, left: Double, right: Double, padding: Double = 1) {
        self.lineWidth = lineWidth
        topLeft = left
        topRight = right
        bottomLeft = left
        bottomRight = right
        self.padding = padding
    }

    init(lineWidth: Double = 3, top: Double, bottom: Double, padding: Double = 1) {
        self.lineWidth = lineWidth
        topLeft = top
        topRight = top
        bottomLeft = bottom
        bottomRight = bottom
        self.padding = padding
    }

    init(lineWidth: Double = 3, cornerRadius: Double? = nil, padding: Double = 1) {
        self.lineWidth = lineWidth
        self.padding = padding
        if let cornerRadius {
            topLeft = cornerRadius
            topRight = cornerRadius
            bottomLeft = cornerRadius
            bottomRight = cornerRadius
        } else {
            let data: Double = ProcessInfo.processInfo.isiOSAppOnMac ? 5 : 55
            topLeft = data
            topRight = data
            bottomLeft = data
            bottomRight = data
        }
    }

    @State private var rotation: Double = 0
    @State private var lineWidth: Double = 3

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: topLeft,
            bottomLeadingRadius: bottomLeft,
            bottomTrailingRadius: bottomRight,
            topTrailingRadius: topRight
        )
        .stroke(
            AngularGradient(
                gradient: Gradient(colors: [
                    .red,
                    .orange,
                    .yellow,
                    .green,
                    .blue,
                    .purple,
                    .red,
                ]),
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
