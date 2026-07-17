//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChatMessageArrayView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/15 08:45.

import MessagingUI
import SwiftUI

struct ChatMessageArrayView: View {
    @ObservedObject private var chatManager = NoLetChatManager.shared
    @ObservedObject private var manager = AppManager.shared
    @State private var scrollPosition = TiledScrollPosition(
        autoScrollsToBottomOnAppend: true,
        scrollsToBottomOnReplace: true
    )
    @State private var isPrependLoading = false
    @State private var isAppendLoading = false
    @State private var isTyping = false
    @State private var isNearBottom = true

    @Environment(\.isSearching) private var isSearching

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TiledView(
                items: chatManager.chatMessages,
                scrollPosition: $scrollPosition
            ) { message in
                ChatMessageCell(item: message)
            }
            .prependLoader(.loader(
                perform: {
                    if chatManager.messagesCount > 0,
                       chatManager.chatMessages.count < chatManager.messagesCount
                    {
                        self.isPrependLoading = true
                        chatManager.page += 1
                        Task {
                            await chatManager.updateMessage()
                            self.isPrependLoading = false
                        }
                    }
                },
                isProcessing: isPrependLoading
            ) { loadText })
            .appendLoader(.loader(
                perform: {
                    if chatManager.page != 1 {
                        self.isAppendLoading = true
                        chatManager.page = 1
                        Task {
                            await chatManager.updateMessage()
                            self.isAppendLoading = false
                        }
                    }

                },
                isProcessing: isAppendLoading
            ) { loadText })
            .typingIndicator(.indicator(isVisible: chatManager.isFocusedInput) {
                HStack(spacing: 8) {
                    Text("正在输入...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            })
            .revealConfiguration(.default)
            .onDragIntoBottomSafeArea {
                chatManager.isFocusedInput = false
                self.hideKeyboard()
            }
            .onTapBackground {
                chatManager.isFocusedInput = false
                self.hideKeyboard()
            }
            .onTiledScrollGeometryChange { geometry in
                let nextIsNearBottom = geometry.pointsFromBottom < 100
                if isNearBottom != nextIsNearBottom {
                    isNearBottom = nextIsNearBottom
                }
            }

            // Scroll to bottom button
            if !isNearBottom && !isSearching {
                Button {
                    scrollPosition.scrollTo(edge: .bottom, animated: true)
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                        .background(Circle().fill(.white))
                }
                .padding()
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(ContentBackgroundView())
        .onChange(of: isSearching) { value in
            if value {
                scrollPosition.scrollTo(edge: .bottom, animated: true)
            }
        }
        .onChange(of: chatManager.chatMessages) { _ in
            if isNearBottom {
                scrollPosition.scrollTo(edge: .bottom, animated: true)
            }
        }
        .onChange(of: chatManager.isFocusedInput) { _ in
            scrollPosition.scrollTo(edge: .bottom, animated: true)
        }
    }

    private var loadText: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("加载消息中...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
