//
//  CustomSection.swift
//  NoLet
//
//  自定义 Section：外观与系统 grouped section 一致（圆角卡片 + header/footer），
//  内部可放任意 View，卡片背景可自定义。可直接放进 List/Form，也可独立使用。
//

import SwiftUI

private enum CustomSectionMetrics {
    static let cardRadius: CGFloat = 10
    static let horizontalInset: CGFloat = 16
}

struct CustomSection<Content: View, Header: View, Footer: View, Fill: View>: View {
    private let content: Content
    private let header: Header
    private let footer: Footer
    private let fill: Fill

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @ViewBuilder footer: () -> Footer = { EmptyView() },
        @ViewBuilder background: () -> Fill = { Color(uiColor: .secondarySystemGroupedBackground) }
    ) {
        self.content = content()
        self.header = header()
        self.footer = footer()
        self.fill = background()
    }

    /// 用纯色/ShapeStyle 自定义卡片背景。
    func sectionBackground<S: ShapeStyle>(_ style: S) -> CustomSection<Content, Header, Footer, some View> {
        .init(
            content: { content },
            header: { header },
            footer: { footer },
            background: { Rectangle().fill(style) }
        )
    }

    private var showsHeader: Bool { !(header is EmptyView) }
    private var showsFooter: Bool { !(footer is EmptyView) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                header
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CustomSectionMetrics.horizontalInset)
                    .padding(.bottom, 6)
            }

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background {
                fill.clipShape(RoundedRectangle(
                    cornerRadius: CustomSectionMetrics.cardRadius, style: .continuous
                ))
            }
            .padding(.horizontal, CustomSectionMetrics.horizontalInset)

            if showsFooter {
                footer
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CustomSectionMetrics.horizontalInset)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 8)
        // 放进 List/Form 时作为整行铺满，让卡片自己控制边距和背景
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

extension CustomSection {
    /// 自定义卡片背景（渐变、材质、图片等任意 View）。
    func sectionBackground<NewFill: View>(
        @ViewBuilder _ background: @escaping () -> NewFill
    ) -> CustomSection<Content, Header, Footer, NewFill> {
        .init(
            content: { content },
            header: { header },
            footer: { footer },
            background: background
        )
    }
}
