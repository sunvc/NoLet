//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PlainMessageCard.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 13:20.

import SwiftUI

struct PlainMessageCard: MessageCardProtocol {
    let message: Message
    var config: MessageCardConfiguration

    @ObservedObject var manager = AppManager.shared
    @Namespace private var messageNameSpace
    @State private var replyText: String = ""
    @FocusState private var showReply
    @State private var showSnap: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 顶部图片与标签区域
            if let image = message.image {
                AsyncPhotoView(url: image, zoom: false, height: 200)
                    .padding(5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.showFull()
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if let url = message.url, let url = URL(string: url) {
                        Button{
                            AppManager.openURL(url: url, .auto)
                        }label: {
                            Image(systemName: "link.circle")
                                .foregroundStyle(.primary, .blue)
                                .font(.title2)
                        }
                    }

                    if let location = message.value(for: "location", ""),
                       let location = location.location()
                    {
                        Button {
                            AppManager.openMap(
                                latitude: location.0,
                                longitude: location.1,
                                destinationName: message.title ?? String(localized: "未知位置")
                            )
                        } label: {
                            Image(systemName: "map.circle")
                                .foregroundStyle(.primary, .green)
                                .font(.title2)
                        }
                        .buttonStyle(.borderless)
                    }

                    Spacer()
                    Text(message.createDate, format: .relative(presentation: .named))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                if message.title != nil || message.subtitle != nil {
                    VStack(alignment: .leading, spacing: 2) {
                        // 主标题
                        if let title = message.title {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        if let subtitle = message.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .fontWeight(.heavy)
                                .foregroundColor(.secondary)
                                .tracking(1) // 字间距
                        }
                    }
                }

                SCSelectableTextRepresentable(
                    text: message.body.plainText,
                    font: .systemFont(ofSize: 17, weight: .medium),
                    textColor: .textBlack,
                    textAlignment: .left,
                    lineLimit: 5
                )

                Divider()
                    .padding(.top, 6)

                HStack {
                    AvatarView(icon: message.icon)
                        .frame(width: 30, height: 30, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(message.group)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 5)

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
            }
            .padding(20)
        }
        .glassCard(24, padding: 10)
        .messageInteraction(
            message: message,
            in: messageNameSpace,
            manager: manager,
            replyText: $replyText,
            showReply: $showReply,
            showSnap: $showSnap,
            onShowFull: showFull
        )
        .shadow(color: config.focusColor, radius: 10, x: 0, y: 0)
    }

    func showFull() {
        manager.selectMessage = message

        Haptic.impact(.light)
    }
}

#Preview {
    PlainMessageCard(message: Message(
        id: UUID().uuidString,
        createDate: .now.addingTimeInterval(-60000),
        group: "工作",
        title: "如何用正念重塑你与自然的关系",
        subtitle: "探索自然",
        body: "在这个快节奏的时代，沉浸于自然不仅是一种放松，更是一场心灵的治愈之旅。本文将带你探索那些被忽视的绿色角落。",
        url: "https://wzs.app",

        ttl: 1000,
        read: false
    ), config: .init())
}
