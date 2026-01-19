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

    private var quote: Message? {
        guard let messageID = AppManager.shared.askMessageID else { return nil }
        return MessagesManager.shared.query(id: messageID)
    }

    var body: some View {
        VStack{
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

                                MarkdownCustomView(content: message.request)
                                    .padding()
                                    .foregroundColor(.primary)
                                    .background(Color.blue.opacity(0.2))
                                    .onTapGesture(count: 2) {
                                        Clipboard.set(message.request)
                                        Toast.success(title: "复制成功")
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }

                ReasonButton(message: message)

                if !message.content.removingAllWhitespace.isEmpty {
                    HStack {
                        MarkdownCustomView(content: message.content)
                            .padding()
                            .foregroundColor(.primary)
                            .background(.message)
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .onTapGesture(count: 2) {
                                Clipboard.set(message.content)
                                Toast.success(title: "复制成功")
                            }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
            }footer: {
                HStack {
                    Text("字符计数: \(message.content.count)")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    Spacer()
                    Text("\(message.timestamp.formatString())")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
            }
        }
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
            Text(verbatim: "\(message.removingAllWhitespace)")
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

struct MCPResultView: View {
    var text: String

    var body: some View {
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
        )
    )
}
