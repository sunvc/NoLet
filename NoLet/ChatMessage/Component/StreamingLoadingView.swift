//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - StreamingLoadingView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo 2026/1/7 08:54.

import SwiftUI

struct StreamingLoadingView: View {
    var showLoading: Bool

    @ObservedObject private var chatManager = NoLetChatManager.shared

    var body: some View {
        if showLoading {
            Button {
                chatManager.cancellableRequest?.cancel()
            } label: {
                HStack(spacing: 8) {
                    Spinner(tint: Color.orange, lineWidth: 3)
                        .frame(width: 20, height: 20, alignment: .center)

                    HStack(alignment: .bottom, spacing: 0) {
                        Text(chatManager.currentContent.isEmpty ? "思考中" : "回答中")
                        Text(verbatim: "...")
                            .frame(width: 15, alignment: .leading)
                    }
                    .foregroundColor(.secondary)
                    .font(.subheadline)

                    Image(systemName: "xmark.circle.fill")
                        .padding(5)
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: 180)
            }

        } else {
            Menu {
                if !chatManager.chatMessages.isEmpty {
                    Section {
                        Button(action: {
                            chatManager.cancellableRequest?.cancel()
                            chatManager.clear()
                            Haptic.impact()
                        }) {
                            Label("新对话", systemImage: "plus.message")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, .primary)
                        }
                    }
                }

                if chatManager.chatPrompt != nil {
                    Section {
                        Button {
                            chatManager.chatPrompt = nil
                        } label: {
                            Label("取消扩展", systemImage: "xmark.circle")
                        }.tint(.orange)
                    }
                } else {
                    Section {
                        Button {
                            chatManager.showPromptChooseView = true
                            Haptic.impact()
                        } label: {
                            Label("选择扩展", systemImage: "puzzlepiece.extension")
                        }.tint(.orange)
                    }
                }

                if !chatManager.chatMessages.isEmpty {
                    Section {
                        Button {
                            let success = chatManager.setPoint()
                            Toast.success(title: success ? "清除成功" : "清除失败")
                        } label: {
                            Label("清除上下文", systemImage: "square.fill.text.grid.1x2")
                                .customForegroundStyle(.red, .primary)
                        }
                    }
                }

            } label: {
                HStack {
                    Text(String(localized: "新对话"))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.trailing, 3)
                        .font(.footnote)

                    if chatManager.chatPrompt != nil {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                    }

                    Image(systemName: "chevron.down")
                        .imageScale(.large)
                        .foregroundStyle(.gray.opacity(0.5))
                        .imageScale(.small)
                }
                .frame(maxWidth: 200)
            }
        }
    }
}
