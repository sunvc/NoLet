//
//  ChatMessageView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/28.
//

import Defaults
import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    let isLoading: Bool

    private var quote: Message? {
        guard let messageID = AppManager.shared.askMessageID else { return nil }
        return MessagesManager.shared.query(id: messageID)
    }

    var body: some View {
        VStack {
            Section {
                if message.request.count > 0 || quote != nil {
                    VStack {
                        if let quote = quote {
                            HStack {
                                Spacer()
                                QuoteView(message: quote.search)
                                Spacer()
                            }
                            .padding(.bottom, 5)
                        }
                        if message.request.count > 0 {
                            HStack {
                                Spacer()

                                userMessageView
                                    .if(isLoading) { $0.lineLimit(2) }
                                    .assistantMenu(message.request)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }

                ReasonButton(message: message)

                if !message.content.isEmpty {
                    HStack {
                        assistantMessageView
                            .assistantMenu(message.content)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
            } header: {
                timestampView
            } footer: {
                if let result = message.result, let text = result.text() {
                    VStack {
                        DisclosureGroup {
                            HStack {
                                Text(verbatim: text)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical)
                            .padding(.horizontal, 10)
                            .background26(.ultraThinMaterial)
                            .clipShape(UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 10,
                                bottomTrailingRadius: 10,
                                topTrailingRadius: 0,
                                style: .continuous
                            ))
                        } label: {
                            HStack {
                                Text("工具执行结果")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - View Components

    /// 时间戳视图
    private var timestampView: some View {
        HStack {
            Spacer()
            Text("\(message.timestamp.formatString())" + "\n")
                .font(.caption2)
                .foregroundStyle(.gray)
                .padding(.horizontal)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }

    /// 用户消息视图
    private var userMessageView: some View {
        MarkdownCustomView(content: message.request)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .overlay {
                Color.blue.opacity(0.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    /// AI助手消息视图
    private var assistantMessageView: some View {
        MarkdownCustomView(content: message.content)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

extension View {
    func assistantMenu(_ text: String) -> some View {
        onTapGesture(count: 2) {
            Clipboard.set(text)
            Toast.success(title: "复制成功")
        }
        .contextMenu {
            Section {
                Button(action: {
                    Clipboard.set(text)
                    Toast.success(title: "复制成功")
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                        .customForegroundStyle(.accent, .primary)
                }
            }
        }
    }
}

struct QuoteView: View {
    var message: String

    var body: some View {
        HStack(spacing: 5) {
            Text(verbatim: "\(message.trimmingSpaceAndNewLines)")
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.caption2)

            Image(systemName: "quote.bubble")
                .foregroundColor(.gray)
                .padding(.leading, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


#Preview {
    ChatMessageView(
        message: ChatMessage(
            id: "",
            timestamp: .now,
            chat: "",
            request: "",
            content: "",
            message: ""
        ),
        isLoading: false
    )
}
