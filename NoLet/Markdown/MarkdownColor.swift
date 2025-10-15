//
//  MarkdownColor+.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//

import MarkdownUI
import SwiftUI

struct MarkdownColors {
    // 主文本颜色：高亮但不刺眼
    static let text = Color(light: Color(rgba: 0x111111FF), dark: Color(rgba: 0xFAFAFAFF))

    // 次要文本颜色：更温和的中灰偏蓝
    static let secondaryText = Color(light: Color(rgba: 0x3C4A5AFF), dark: Color(rgba: 0xA5B0C0FF))

    // 第三级文本颜色：蓝灰调，风格更轻快
    static let tertiaryText = Color(light: Color(rgba: 0x6A7B8EFF), dark: Color(rgba: 0x7F8FA3FF))

    // 背景颜色
    static let background = Color(light: Color(rgba: 0xFFFFFFFF), dark: Color(rgba: 0x101418FF))

    // 次要背景颜色：引入冷灰调
    static let secondaryBackground = Color(light: Color(rgba: 0xF2F6FAFF), dark: Color(rgba: 0x1A1F26FF))

    // 链接颜色：鲜艳蓝调，增强可点击性
    static let link = Color(light: Color(rgba: 0x0B5FFFff), dark: Color(rgba: 0x61A5FFFF))

    // 边框颜色：色温更高的浅灰蓝
    static let border = Color(light: Color(rgba: 0xD0D8E0FF), dark: Color(rgba: 0x3A4A5AFF))

    // 分割线颜色：淡蓝灰，避免死灰感
    static let divider = Color(light: Color(rgba: 0xC8D4E0FF), dark: Color(rgba: 0x2B3642FF))

    // 复选框颜色：鲜亮蓝灰，强调状态
    static let checkbox = Color(light: Color(rgba: 0x3366CCFF), dark: Color(rgba: 0x85B4FFFF))

    // 复选框背景颜色：有一点明度变化
    static let checkboxBackground = Color(light: Color(rgba: 0xEAF1FAFF), dark: Color(rgba: 0x2D3A4AFF))
}


extension View {
    func markdownHeadingStyle(fontSize: CGFloat, fontWeight: SwiftUI.Font.Weight = .semibold) -> some View {
        self
            .relativeLineSpacing(.em(0.125))
            .markdownMargin(top: 24, bottom: 16)
            .markdownTextStyle {
                FontWeight(fontWeight)
                FontSize(.em(fontSize))
            }
    }
    
    func markdownParagraphStyle() -> some View {
        self
            .fixedSize(horizontal: false, vertical: true)
            .relativeLineSpacing(.em(0.25))
            .markdownMargin(top: 0, bottom: 16)
    }
}

struct MarkdownTheme {
    static func defaultTheme(_ defaultSize:CGFloat = 16, scaleFactor:CGFloat = 1.0) -> Theme {
        Theme()
        
            .text { FontSize(defaultSize * scaleFactor) }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(MarkdownColors.secondaryBackground)
                    
            }
            .strong { FontWeight(.semibold) }
            .link { ForegroundColor(MarkdownColors.link) }
            .heading1 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .markdownHeadingStyle(fontSize: 2)
                    Divider().overlay(MarkdownColors.divider)
                }
            }
            .heading2 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .markdownHeadingStyle(fontSize: 1.5)
                    Divider().overlay(MarkdownColors.divider)
                }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 1.25)
            }
            .heading4 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 1)
            }
            .heading5 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.875)
            }
            .heading6 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.85)
                    .markdownTextStyle {
                        ForegroundColor(MarkdownColors.tertiaryText)
                    }
            }
            .paragraph { configuration in
                configuration.label
                    .markdownParagraphStyle()
            }
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(MarkdownColors.border)
                        .relativeFrame(width: .em(0.2))
                    configuration.label
                        .markdownTextStyle { ForegroundColor(MarkdownColors.secondaryText) }
                        .relativePadding(.horizontal, length: .em(1))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .codeBlock { configuration in
                CodeBlock(configuration)
            }
            .listItem { configuration in
                configuration.label
                    .padding(.bottom, 10)
            }
            .taskListMarker { configuration in
                Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(MarkdownColors.checkbox, MarkdownColors.checkboxBackground)
                    .imageScale(.small)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(color: MarkdownColors.border))
                    .markdownTableBackgroundStyle(
                        .alternatingRows(MarkdownColors.background, MarkdownColors.secondaryBackground)
                    )
                    .markdownMargin(top: 0, bottom: 16)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 {
                            FontWeight(.semibold)
                        }
                        BackgroundColor(nil)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 13)
                    .relativeLineSpacing(.em(0.25))
            }
            .thematicBreak {
                Divider()
                    .relativeFrame(height: .em(0.25))
                    .overlay(MarkdownColors.border)
                    .markdownMargin(top: 24, bottom: 24)
            }
            .image { config in
                config.label
                    .zoomable()
                    .zIndex(9999)
            }
            
            
    }
}

