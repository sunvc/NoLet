//
//  MarkdownMessageCard.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/2/13.
//

import Defaults
import Kingfisher
import SwiftUI
import UniformTypeIdentifiers

struct MarkdownMessageCard: MessageCardProtocol {
    let message: Message
    var config: MessageCardConfiguration

    @State private var showLoading: Bool = false

    @State private var timeMode: Int = 0

    @ObservedObject private var manager = AppManager.shared

    var dateTime: String {
        if config.showAllTTL {
            message.expiredTime()
        } else {
            switch timeMode {
            case 1: message.createDate.formatString()
            case 2: message.expiredTime()
            default: message.createDate.agoFormatString()
            }
        }
    }

    @Namespace private var sms

    @FocusState private var showReply
    @State private var replyText: String = ""

    var lineColor: Color {
        if manager.copyMessageId == message.id {
            return .orange
        } else {
            return message.reply == nil ? .gray.opacity(0.6) : .green
        }
    }

    @State private var showSnap: Bool = false
    var body: some View {
        /// 记录一下, 在 List 直接使用 Section 会内存泄漏, 必须包一层
        VStack {
            Section {
                VStack {
                    HStack(alignment: .center) {
                        AvatarView(icon: message.icon)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.bottom, 5)

                        VStack {
                            if let title = message.title {
                                HighlightedText(
                                    text: title,
                                    searchText: config.searchText
                                )
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if let subtitle = message.subtitle {
                                HighlightedText(
                                    text: subtitle,
                                    searchText: config.searchText
                                )
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())

                    if let urlstr = message.url {
                        HStack {
                            HStack(spacing: 1) {
                                Image(systemName: "network")
                                    .imageScale(.small)

                                HighlightedText(
                                    text: urlstr,
                                    searchText: config.searchText
                                )
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundStyle(.accent)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                                .foregroundStyle(.gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let url = message.url, let fileURL = URL(string: url) {
                                AppManager.openURL(url: fileURL, .safari)
                            }
                            Haptic.impact()
                        }
                    }

                    if message.title != nil || message.subtitle != nil || message.url != nil{
                        Line()
                            .stroke(
                                .gray,
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    lineCap: .butt,
                                    lineJoin: .miter,
                                    dash: [5, 3]
                                )
                            )
                            .frame(height: 1)
                            .padding(.vertical, 1)
                            .padding(.horizontal, 3)
                    }
                    VStack {
                        if let url = message.image {
                            AsyncPhotoView(url: url, zoom: false, height: 230)
                                .padding(5)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.showFull()
                                }
                        }

                        if !message.body.isEmpty {
                            MarkdownCustomView(
                                content: message.body,
                                searchText: config.searchText,
                                select: manager.copyMessageId == message.id
                            )
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 5)
                            .accessibilityElement(children: .ignore)
                            .accessibilityValue(
                                String("\(PBMarkdown.plain(message.accessibilityValue()))")
                            )
                            .accessibilityLabel("消息内容")
                        }
                    }
                }
                .padding(8)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 15,
                        bottomLeadingRadius: 5,
                        bottomTrailingRadius: 5,
                        topTrailingRadius: 15,
                        style: .continuous
                    )
                    .fill(lineColor)
                    .frame(height: 3)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 3)
                    .onTapGesture {
                        if manager.copyMessageId != message.id {
                            withAnimation {
                                manager.copyMessageId = message.id
                            }
                        } else {
                            withAnimation {
                                manager.copyMessageId = nil
                            }
                        }
                    }
                }
                .frame(minHeight: 50)
                .glassCard(20)
                .padding(10)
                .contentShape(Rectangle())
                .messageInteraction(
                    message: message,
                    in: sms,
                    manager: manager,
                    replyText: $replyText,
                    showReply: $showReply,
                    showSnap: $showSnap,
                    onShowFull: showFull
                )
            } header: {
                MessageViewHeader()
            }
        }
        .padding(.vertical)
        .contentShape(Rectangle())
    }

    func showFull() {
        manager.selectMessage = message

        Haptic.impact(.light)
    }

    @ViewBuilder
    func MessageViewHeader() -> some View {
        HStack {
            Text(message.createDate, format: .relative(presentation: .named))
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 10)
                .VButton(onRelease: { _ in
                    withAnimation {
                        let number = self.timeMode + 1
                        self.timeMode = number > 2 ? 0 : number
                    }
                    return true
                })
                .accessibilityLabel("时间:")
                .accessibilityValue(message.createDate
                    .formatted(date: .long, time: .standard))

            Spacer()

            if config.showGroup {
                HighlightedText(text: message.group, searchText: config.searchText)
                    .textSelection(.enabled)
                    .accessibilityLabel("群组名")
                    .accessibilityValue(message.group)
                Spacer()
            }

            MessageActionMenu(
                message: message,
                assistantAccounsCount: config.accounts,
                manager: manager,
                showSnap: $showSnap,
                showReply: $showReply,
                onDelete: config.delete
            )
        }
        .background(config.focusColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(.horizontal, 15)
    }
}

#Preview {
    List {
        MarkdownMessageCard(
            message: MessagesManager.examples().first!, config: .init()
        )
        .listRowBackground(Color.clear)
        .listSectionSeparator(.hidden)
        .listRowInsets(EdgeInsets())

    }.listStyle(.grouped)
}

extension MessagesManager {
    static func examples() -> [Message] {
        [
            Message(
                id: UUID().uuidString,
                createDate: .now,
                group: "Markdown",
                title: String(localized: "示例"),
                body: "# NoLet \n## NoLet \n### NoLet",
                ttl: 1,
                read: false
            ),

            Message(
                id: UUID().uuidString,
                createDate: .now,
                group: String(localized: "示例"),
                title: String(localized: "使用方法"),
                body: String(localized: """
                    * 右上角功能菜单，使用示例，分组
                    * 单击图片/双击消息全屏查看
                    * 全屏查看，翻译，总结，朗读
                    * 左滑删除，右滑复制和智能解答。
                    """),
                ttl: 1,
                read: false
            ),

            Message(
                id: UUID().uuidString,
                createDate: .now,
                group: "App",
                title: String(localized: "点击跳转app"),
                body: String(localized: "url属性可以打开URLScheme, 点击通知消息自动跳转，前台收到消息自动跳转"),
                url: "weixin://",
                ttl: 1,
                read: false
            ),
        ]
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        }
    }
}

extension View {
    @ViewBuilder
    func mbackground26<S>(_ color: S, radius: CGFloat = 0) -> some View where S: ShapeStyle {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
        } else {
            background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(color)
                    .shadow(group: false)
            )
        }
    }

    func shadow(group _: Bool) -> some View {
        shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .shadow(color: Color.shadow1, radius: 5, x: 3, y: 5)
            .shadow(color: Color.shadow1.opacity(0.5), radius: 5, x: -3, y: -5)
    }
}

extension Message {
    fileprivate func accessibilityValue() -> String {
        var text: [String] = []

        text
            .append(
                String(localized: "时间:") + createDate
                    .formatted(date: .long, time: .standard)
            )

        if let title = title {
            text.append(String(localized: "标题") + ":" + title)
        }
        if let subtitle = subtitle {
            text.append(String(localized: "副标题") + ":" + subtitle)
        }

        if !body.isEmpty {
            text.append(String(localized: "内容") + ":" + body)
        }

        if image != nil {
            text.append(String(localized: "附件: 一张图片"))
        }

        if let url = url {
            text.append(String(localized: "跳转链接:") + url)
        }

        return text.joined(separator: "\n")
    }

    fileprivate func expiredTime() -> String {
        if ttl == ExpirationTime.forever.rawValue {
            return "∞ ∞ ∞"
        }

        let days = createDate.daysRemaining(afterSubtractingFrom: ttl)
        if days <= 0 {
            return String(localized: "已过期")
        }

        let calendar = Calendar.current
        let now = Date()
        let targetDate = calendar.date(byAdding: .day, value: days, to: now)!

        let components = calendar.dateComponents([.year, .month, .day], from: now, to: targetDate)

        if let years = components.year, years > 0 {
            return String(localized: "\(years)年")
        } else if let months = components.month, months > 0 {
            return String(localized: "\(months)个月")
        } else if let days = components.day {
            return String(localized: "\(days)天")
        }

        return String(localized: "即将过期")
    }
}
