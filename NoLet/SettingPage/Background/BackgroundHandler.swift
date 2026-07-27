//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - BackgroundHandler.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/19 14:17.

import Defaults
import SwiftUI

extension Defaults.Keys {
    static let background = Key<ContentBackgroundStyle>("ContentBackgroundStyle", .custom)
    static let customColor = Key<GradientColorNode>(
        "GradientColorNode",
        .init(color: Color.customNolet)
    )
}

enum ContentBackgroundStyle: String, CaseIterable, Defaults.Serializable {
    case custom
    case tiffany
    case tiffany2
    case aurora

    var name: String {
        switch self {
        case .custom: String(localized: "自定义")
        case .tiffany: String(localized: "蒂芙尼")
        case .tiffany2: String(localized: "蒂芙尼蓝")
        case .aurora: String(localized: "暮色极光")
        }
    }
}

struct ContentBackgroundView: View {
    @Default(.background) private var background
    @Default(.customColor) private var customColor

    var body: some View {
        switch background {
        case .tiffany:
            TiffanyBlueBackground()
        case .tiffany2:
            TiffanyBlueBackground2()
        case .aurora:
            AuroraThemeBackground()
        case .custom:
            customColor.color
                .ignoresSafeArea()
        }
    }
}

nonisolated struct StoredRGBA: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    // 从 SwiftUI.Color 转换（完美提取浮点数和 Alpha）
    init(color: Color) {
        #if os(macOS)
        let nativeColor = NSColor(color)
        #else
        let nativeColor = UIColor(color)
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        nativeColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// 供设置面板和 Defaults 直接使用的节点
nonisolated struct GradientColorNode: Identifiable, Codable, Equatable, Defaults.Serializable {
    var id = UUID()
    var rgba: StoredRGBA

    var color: Color {
        get { rgba.color }
        set { rgba = StoredRGBA(color: newValue) }
    }

    init(color: Color) {
        self.rgba = StoredRGBA(color: color)
    }
}
