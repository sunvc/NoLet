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
    static let background = Key<ContentBackgroundStyle>("ContentBackgroundStyle", .none)
    static let customColor = Key<[GradientColorNode]>(
        "CustomGradientColors",
        default: [
            .init(color: Color(red: 0.35, green: 0.78, blue: 0.80)),
            .init(color: Color(red: 0.55, green: 0.45, blue: 0.90)),
        ]
    )
}

enum ContentBackgroundStyle: String, CaseIterable, Defaults.Serializable {
    case none
    case custom
    case tiffany
    case aurora

    var name: String {
        switch self {
        case .none: String(localized: "无")
        case .custom: String(localized: "自定义")
        case .tiffany: String(localized: "蒂芙尼")
        case .aurora: String(localized: "暮色极光")
        }
    }
}

struct ContentBackgroundView: View {
    @Default(.background) private var background
    @Default(.customColor) private var customColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch background {
        case .none:
            Color.gray.opacity(0.16)
                .ignoresSafeArea()
        case .tiffany:
            TiffanyBlueBackground()
        case .aurora:
            AuroraThemeBackground()
        case .custom:
            LinearGradient(
                colors: customColor.map { $0.color(for: colorScheme) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

nonisolated struct StoredRGBA: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(color: Color) {
        let c = Self.resolve(color)
        self.red = c.red
        self.green = c.green
        self.blue = c.blue
        self.alpha = c.alpha
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// 暗色由亮色自动推导：在 HSB 空间降低明度、略提饱和度。
    var darkColor: Color {
        let (h, s, b, a) = rgbaHSB
        return Color(
            hue: h,
            saturation: min(1, s * 1.15),
            brightness: b * 0.62,
            opacity: a
        )
    }

    private var rgbaHSB: (h: Double, s: Double, b: Double, a: Double) {
        #if os(macOS)
        let native = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        #else
        let native = UIColor(color)
        #endif
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        native.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (Double(h), Double(s), Double(b), Double(a))
    }

    func color(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkColor : color
    }

    static func resolve(_ color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        #if os(macOS)
        let nativeColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        #else
        let nativeColor = UIColor(color)
        #endif
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nativeColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
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

    func color(for colorScheme: ColorScheme) -> Color {
        rgba.color(for: colorScheme)
    }

    init(color: Color) {
        self.rgba = StoredRGBA(color: color)
    }
}
