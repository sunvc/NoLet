//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChatMessageCell.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 单条消息卡片，内容完整展示，不内部滚动。

//  History:
//    Created by Neo 2026/7/15 09:13.

import SwiftUI


struct ChatMessageCell: View {
    let item: ChatMessage

    @ObservedObject private var chatManager = NoLetChatManager.shared
    @ObservedObject private var appManager = AppManager.shared

    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// 正在流式输出的助手消息直接读取 manager 的实时状态，
    /// 避免逐 token 触发整列表 diff；流结束后切到最终内容并渲染 Markdown。
    private var isStreaming: Bool {
        appManager.isLoading && chatManager.currentMessageID == item.id
    }

    private var display: ChatMessage {
        guard isStreaming else { return item }
        return ChatMessage(
            id: item.id,
            timestamp: item.timestamp,
            role: item.role,
            content: chatManager.currentContent,
            message: item.message,
            reason: chatManager.currentReason.isEmpty ? nil : chatManager.currentReason,
            result: chatManager.currentResult.isEmpty ? nil : chatManager.currentResult
        )
    }

    @MainActor
    private var quote: MessageEntity? {
        guard let messageID = display.message ?? appManager.askMessageID else { return nil }
        return MessagesManager.shared.query(id: messageID)
    }

    private var isUserMessage: Bool { display.role == "user" }

    var body: some View {
        let message = display
        VStack(alignment: .leading, spacing: 4) {
            if let quote {
                HStack {
                    Spacer()
                    QuoteView(message: quote.search)
                    Spacer()
                }
                .padding(.bottom, 5)
            }

            if !isUserMessage {
                ReasonButton(message: message)
            }

            if !message.content.removingAllWhitespace.isEmpty {
                HStack(alignment: .top) {
                    if isUserMessage { Spacer(minLength: 40) }

                    content(message.content)
                        .padding(12)
                        .foregroundColor(.primary)
                        .frame(alignment: isUserMessage ? .trailing : .leading)
                        .background26(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture(count: 2) {
                            NCONFIG.copy(message.content)
                            Toast.success(title: "复制成功")
                        }
                        .textSelection(.enabled)

                    if !isUserMessage { Spacer(minLength: 40) }
                }
            }

            HStack {
                if isUserMessage { Spacer() }
                Text(Self.timeFormatter.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if !isUserMessage { Spacer() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func content(_ text: String) -> some View {
        if isStreaming {
            Text(verbatim: text)
        } else {
            MarkdownCustomView(content: text)
        }
    }
}
