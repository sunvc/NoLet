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
import SwiftUI

struct ChatInputView: View {
    @ObservedObject private var chatManager = NoLetChatManager.shared
    @ObservedObject private var manager = AppManager.shared
    @Binding var text: String

    let onSend: (String) -> Void

    @FocusState private var isFocusedInput: Bool

    @State private var selectedPromptIndex: Int?
    @State private var focused: Bool = false

    private var quote: MessageEntity? {
        guard let messageID = manager.askMessageID else { return nil }
        return MessagesManager.shared.query(id: messageID)
    }

    @State private var show: Bool = false
    var body: some View {
        VStack {
            HStack {
                PromptLabelView()
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                if !chatManager.isFocusedInput && manager.sizeClass == .compact {
                    TabBarBackButtonView(x: 100)
                }
                if !manager.isLoading {
                    inputField
                        .offset(x: show ? 0 : 500)
                    
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal)
            .animation(.default, value: text)
        }
        .padding(.bottom, isFocusedInput ? (.isiOSAppOnMac ? 30 : 10) : 30)
        .onAppear{
            withAnimation(.spring(
                response: 0.3, 
                dampingFraction: 0.5,
                blendDuration: 0
            )) {
                self.show = true
            }
            
        }
        .onDisappear{
            withAnimation(.spring(
                response: 0.3, 
                dampingFraction: 0.5,
                blendDuration: 0
            )) {
                self.show = false
            }
        }
    }

    // MARK: - Subviews

    private var inputField: some View {
        HStack {
            TextField("请伞兵开始发言", text: $text, axis: .vertical)
                .lineLimit(5)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .focused($isFocusedInput)
                .frame(minHeight: 50)
                .onChange(of: isFocusedInput) { value in
                    withAnimation {
                        chatManager.isFocusedInput = value
                    }
                }

            if !text.isEmpty {
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .background26(Color.white, radius: 20)
                }
                .transition(.scale)
                .keyboardShortcut(.return, modifiers: [.command])
            } else {
                Image(systemName: "puzzlepiece.extension")
                    .foregroundStyle(chatManager.chatPrompt != nil ? .green : .gray)
                    .font(.title2)
                    .transition(.scale)
                    .padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 15))
                    .onTapGesture {
                        chatManager.showPromptChooseView = true
                        Haptic.impact()
                    }
            }
        }
        .background26(Color(.systemGray6), radius: 17)
    }

    func sendMessage() {
        self.text = text.trimmingCharacters(in: .whitespaces)
        if text.removingAllWhitespace.count > 0 {
            onSend(text)
            isFocusedInput = false
        } else {
            Toast.error(title: "至少1个字符")
        }
    }

    @ViewBuilder
    func PromptLabelView() -> some View {
        HStack(spacing: 10) {
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
                }
            }
        }
        .padding(.horizontal)
    }
}

