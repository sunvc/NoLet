//
//  MarkdownColor.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//

import MarkdownUI
import SwiftUI

enum MarkdownColors {
    // 主标题：Light 纯黑增加分量，Dark 灰白避免刺眼
    static let title = Color(
        light: Color(rgba: 0x0000_00FF),
        dark: Color(rgba: 0xE1E4_E8FF) // 柔和的浅灰白
    )

    // 正文颜色：Light 模式稍浅一点点（深灰），Dark 模式采用淡青灰（阅读最舒服）
    static let text = Color(
        light: Color(rgba: 0x1A20_2CFF),
        dark: Color(rgba: 0xD1D5_DBFF) // 略暗于标题，形成层级
    )

    // 次要文本：蓝灰调。Dark 模式下降低明度，使其“退后”
    static let secondaryText = Color(
        light: Color(rgba: 0x4A55_68FF),
        dark: Color(rgba: 0x9CA3_AFFF)
    )

    // 第三级文本：仅用于脚注或极其不重要的说明
    static let tertiaryText = Color(
        light: Color(rgba: 0x7180_96FF),
        dark: Color(rgba: 0x6B72_80FF)
    )

    // 背景颜色：Dark 模式采用深蓝黑，比纯黑更有质感
    static let background = Color(
        light: Color(rgba: 0xFFFF_FFFF),
        dark: Color(rgba: 0x0D11_17FF)
    )

    // 次要背景（代码块、引用块）：Light 灰蓝，Dark 深灰蓝
    static let secondaryBackground = Color(
        light: Color(rgba: 0xF6F8_FAFF),
        dark: Color(rgba: 0x161B_22FF)
    )

    // 链接：Light 鲜艳，Dark 稍微降低饱和度防止“发光”感
    static let link = Color(
        light: Color(rgba: 0x0969_DAFF),
        dark: Color(rgba: 0x58A6_FFFF)
    )

    // 边框/分割线：保持轻快，Dark 模式不要太亮
    static let border = Color(light: Color(rgba: 0xD0D7_DEFF), dark: Color(rgba: 0x3036_3DFF))
    static let divider = Color(light: Color(rgba: 0xD8E0_E8FF), dark: Color(rgba: 0x2126_2DFF))

    // 复选框与强调色
    static let checkbox = Color(light: Color(rgba: 0x0969_DAFF), dark: Color(rgba: 0x388B_F1FF))
    static let checkboxBackground = Color(
        light: Color(rgba: 0xF3F6_F9FF),
        dark: Color(rgba: 0x161B_22FF)
    )
}

extension View {
    func markdownHeadingStyle(
        fontSize: CGFloat,
        fontWeight: SwiftUI.Font.Weight = .semibold
    ) -> some View {
        relativeLineSpacing(.em(0.125))
            .markdownMargin(top: 24, bottom: 16)
            .markdownTextStyle {
                FontWeight(fontWeight)
                FontSize(.em(fontSize))
                ForegroundColor(MarkdownColors.title)
            }
    }

    func markdownParagraphStyle() -> some View {
        fixedSize(horizontal: false, vertical: true)
            .relativeLineSpacing(.em(0.25))
            .markdownMargin(top: 0, bottom: 16)
    }
}

enum MarkdownTheme {
    static func defaultTheme(_ defaultSize: CGFloat = 16, scaleFactor: CGFloat = 1.0) -> Theme {
        Theme()
            .text {
                FontSize(defaultSize * scaleFactor)
                ForegroundColor(MarkdownColors.text)
            }
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
                        .markdownHeadingStyle(fontSize: 1.5)
                    Divider().overlay(MarkdownColors.divider)
                }
            }
            .heading2 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .markdownHeadingStyle(fontSize: 1.25)
                    Divider().overlay(MarkdownColors.divider)
                }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 1.0)
            }
            .heading4 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.875)
            }
            .heading5 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.85)
            }
            .heading6 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.82)
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
                        .markdownTextStyle { ForegroundColor(MarkdownColors.tertiaryText) }
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
                    .fixedSize(horizontal: true, vertical: true)
                    .markdownTableBorderStyle(.init(color: MarkdownColors.border))
                    .markdownTableBackgroundStyle(
                        .alternatingRows(
                            MarkdownColors.background,
                            MarkdownColors.secondaryBackground
                        )
                    )
                    .markdownMargin(top: 16, bottom: 16)
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
