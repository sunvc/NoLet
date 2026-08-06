//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChatMessageArrayView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 纯 SwiftUI 消息列表，最新消息在底部。

//  History:
//    Created by Neo 2026/7/15 08:45.
//

import SwiftUI

struct ChatMessageArrayView: View {
    @ObservedObject private var chatManager = NoLetChatManager.shared
    @State private var nearBottom = true

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(chatManager.chatMessages) { message in
                        ChatMessageCell(item: message)
                            .id(message.id)
                    }

                    HStack(spacing: 8) {
                        Text("正在输入...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .opacity(chatManager.isFocusedInput ? 1 : 0.0001)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .id("typingIndicator")

                    Color.clear
                        .frame(height: 1)
                        .id("bottomMarker")
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: NearBottomKey.self,
                                    value: geo.frame(in: .named("chat")).minY
                                )
                            }
                        )
                }
            }
            .coordinateSpace(name: "chat")
            .scrollDismissesKeyboard(.interactively)
            .onPreferenceChange(NearBottomKey.self) { minY in
                nearBottom = minY < UIScreen.main.bounds.height + 120
            }
            .onChange(of: chatManager.chatMessages) { messages in
                guard nearBottom, let last = messages.last else { return }
                withAnimation(.smooth(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: chatManager.isFocusedInput) { focused in
                if focused {
                    withAnimation(.smooth) {
                        proxy.scrollTo("typingIndicator", anchor: .bottom)
                    }
                }
            }
        }
    }
}

private struct NearBottomKey: PreferenceKey {
    static var defaultValue: CGFloat { .greatestFiniteMagnitude }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
