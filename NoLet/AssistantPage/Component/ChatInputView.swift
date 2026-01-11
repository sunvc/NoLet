//
//  ChatInputView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/28.
//

import Combine
import Defaults
import GRDB
import SwiftUI

struct ChatInputView: View {
    @EnvironmentObject private var chatManager: NoLetChatManager
    @EnvironmentObject private var manager: AppManager
    @Binding var text: String

    let onSend: (String) -> Void

    @FocusState private var isFocusedInput: Bool

    @State private var selectedPromptIndex: Int?

    private var quote: Message? {
        guard let messageID = manager.askMessageID else { return nil }
        return MessagesManager.shared.query(id: messageID)
    }

    var body: some View {
        VStack {
            HStack {
                PromptLabelView()
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                if !isFocusedInput && !.ISPAD {
                    backupButton()
                }

                inputField
                    .disabled(manager.isLoading)
                    .opacity(manager.isLoading ? 0 : 1)
            }
            .padding(.horizontal)
            .animation(.default, value: text)
        }
        .padding(.bottom, isFocusedInput ? 10 : 30)
        .overlay(alignment: .bottomTrailing) { 
            
        }
        
    }

    // MARK: - Subviews

    private var inputField: some View {
        HStack {
            TextField("给智能助手发消息", text: $text, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .focused($isFocusedInput)
                .frame(minHeight: 50)
                .onChange(of: isFocusedInput) { value in
                    chatManager.isFocusedInput = value
                }

            if !text.isEmpty {
                // 发送按钮
                Button(action: {
                    self.text = text.trimmingCharacters(in: .whitespaces)
                    if text.trimmingSpaceAndNewLines.count > 0 {
                        onSend(text)
                        isFocusedInput = false
                    } else {
                        Toast.error(title: "至少1个字符")
                    }

                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .background26(Color.white, radius: 20)
                }
                .transition(.scale)
            } else {
                Image(systemName: "puzzlepiece.extension")
                    .foregroundStyle(chatManager.chatPrompt != nil ? .green : .gray)
                    .font(.title2)
                    .padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 15))
                    .onTapGesture {
                        chatManager.showPromptChooseView = true
                        Haptic.impact()
                    }
            }
        }
        .background26(Color(.systemGray6), radius: 17)
    }

    @ViewBuilder
    func PromptLabelView() -> some View {
        HStack(spacing: 10) {
            if !chatManager.reasoningEffort.emptyData{
                Menu { 
                    Button(role: .destructive) {
                        chatManager.reasoningEffort = .minimal
                    } label: {
                        Label("清除", systemImage: "eraser")
                            .customForegroundStyle(.accent, .primary)
                    }
                } label: { 
                    QuoteView(message: String(localized: "深度思考"))
                }

                
            }
            Spacer()

            if let quote = quote {
                Menu {
                    Button(role: .destructive) {
                        AppManager.shared.askMessageID = nil
                    } label: {
                        Label("清除", systemImage: "eraser")
                            .customForegroundStyle(.accent, .primary)
                    }
                } label: {
                    QuoteView(message: quote.search)
                        .onAppear {
                            Task.detached(priority: .background) {
                                try? await DatabaseManager.shared.dbQueue.write { db in
                                    Task { @MainActor in
                                        NoLetChatManager.shared.setGroup()
                                    }

                                    // 尝试查找 quote.id 对应的 group
                                    if let group = try ChatGroup.fetchOne(db, key: quote.id) {
                                        // 如果存在，就设为 current
                                        Task { @MainActor in
                                            chatManager.setGroup(group: group)
                                        }
                                    } else {
                                        // 如果不存在，创建一个新的
                                        let group = ChatGroup(
                                            id: quote.id,
                                            timestamp: .now,
                                            name: quote.search.trimmingSpaceAndNewLines,
                                            host: "",
                                            current: true
                                        )
                                        try group.insert(db)
                                        Task { @MainActor in
                                            chatManager.setGroup(group: group)
                                        }
                                    }
                                }
                            }
                        }
                        .onDisappear {
                            Task { @MainActor in
                                chatManager.setGroup()
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    func backupButton() -> some View {
        if manager.historyPage == .setting {
            Button {
                manager.page = .setting
                Task.detached {
                    await Haptic.impact()
                    await Tone.play(.share)
                }
            } label: {
                Label("设置", systemImage: "gear.badge.questionmark")
                    .symbolRenderingMode(.palette)
                    .customForegroundStyle(.green, .primary)
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .transition(.move(edge: .leading))
            }.button26(.borderless)
        } else {
            Button {
                manager.page = .message
                Task.detached {
                    await Haptic.impact()
                    await Tone.play(.share)
                }
            } label: {
                Label("消息", systemImage: "ellipsis.message")
                    .symbolRenderingMode(.palette)
                    .customForegroundStyle(.green, .primary)
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .transition(.move(edge: .leading))
            }.button26(.borderless)
        }
    }
}
