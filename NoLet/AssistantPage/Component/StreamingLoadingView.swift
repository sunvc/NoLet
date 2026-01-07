//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - StreamingLoadingView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/7 08:54.
    

import SwiftUI

struct StreamingLoadingView: View {
    var showLoading: Bool

    @EnvironmentObject private var chatManager: NoLetChatManager
    // 使用 TimelineView 自动驱动动画，无需手动管理 Timer
    var body: some View {
        if showLoading {
            Button {
                chatManager.cancellableRequest?.cancel()
            } label: {
                HStack(spacing: 8) {
                    // 图标动画：增加一个呼吸效果
                    Image(systemName: "brain")
                        .foregroundColor(.orange)
                        .symbolEffect(.pulse) // iOS 17+ 呼吸感

                    TimelineView(.periodic(from: .now, by: 0.5)) { context in
                        let dotCount = Int(context.date.timeIntervalSinceReferenceDate * 2) % 4
                        let dots = String(repeating: ".", count: dotCount)

                        HStack(alignment: .bottom, spacing: 0) {
                            Text(chatManager.currentContent.isEmpty ? "思考中" : "回答中")
                            // 固定点号的容器，防止文字左右抖动
                            Text(dots)
                                .frame(width: 15, alignment: .leading)
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    }

                    Image(systemName: "xmark.circle.fill")
                        .padding(5)
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: 180)
            }

        } else {
            Menu {
                if chatManager.chatGroup != nil {
                    Section {
                        Button(action: {
                            chatManager.cancellableRequest?.cancel()
                            chatManager.setGroup()
                            Haptic.impact()
                        }) {
                            Label("新对话", systemImage: "plus.message")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, .primary)
                        }
                    }
                }

                Section {
                    Button {
                        chatManager.showAllHistory = true
                        Haptic.impact()

                    } label: {
                        Label("历史对话", systemImage: "clock.arrow.circlepath")
                            .customForegroundStyle(.accent, .primary)
                    }
                }

                if chatManager.chatGroup != nil {
                    Section {
                        Button {
                            if let id = chatManager.chatGroup?.id {
                                Task.detached(priority: .background) {
                                    await chatManager.delete(groupID: id)
                                }
                            }

                        } label: {
                            Label("删除对话", systemImage: "trash")
                        }.tint(.red)
                    }
                }

                if chatManager.chatPrompt != nil {
                    Section {
                        Button {
                            chatManager.chatPrompt = nil
                        } label: {
                            Label("取消扩展功能", systemImage: "xmark.circle")
                        }.tint(.orange)
                    }
                }

                if chatManager.chatMessages.count != 0 {
                    Section {
                        Button {
                            Task {
                                let success = await chatManager.setPoint()
                                Toast.success(title: success ? "清除成功" : "清除失败")
                            }

                        } label: {
                            Label("清除上下文", systemImage: "square.fill.text.grid.1x2")
                                .customForegroundStyle(.red, .primary)
                        }
                    }
                }

            } label: {
                HStack {
                    VStack(spacing: 0) {
                        HStack {
                            Text(chatManager.chatGroup?.name.trimmingSpaceAndNewLines ?? "新对话")
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.trailing, 3)
                                .font(.footnote)
                        }

                        if let prompt = chatManager.chatPrompt {
                            HStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text(prompt.title)
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                            .padding(.leading, 5)
                        }
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
