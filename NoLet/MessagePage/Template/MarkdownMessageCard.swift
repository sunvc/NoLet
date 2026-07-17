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
            HStack {
                if let title = message.title {
                    HighlightedText(
                        text: title,
                        searchText: config.searchText
                    )
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                MessageActionMenu(
                    message: message,
                    assistantAccounsCount: config.accounts,
                    manager: manager,
                    showSnap: $showSnap,
                    showReply: $showReply,
                    onDelete: config.delete
                )
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

            if message.title != nil || message.subtitle != nil {
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
            Divider()
            HStack(alignment: .center) {
                AvatarView(icon: message.icon)
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 5)

                if config.showGroup {
                    HighlightedText(
                        text: message.group,
                        searchText: config.searchText
                    )
                    .textSelection(.enabled)
                    .accessibilityLabel("群组名")
                    .accessibilityValue(message.group)
                    Spacer()
                }

                Spacer(minLength: 0)

                if message.url != nil {
                    Image(systemName: "network")
                        .imageScale(.small)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let url = message.url, let fileURL = URL(string: url) {
                                AppManager.openURL(url: fileURL, .safari)
                            }
                            Haptic.impact()
                        }
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
        .padding(5)
        .glassCard(12)
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
    }

    func showFull() {
        manager.selectMessage = message

        Haptic.impact(.light)
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
