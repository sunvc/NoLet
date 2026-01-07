//
//  ChatListView.swift
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

struct ChatMessageListView: View {
    @EnvironmentObject private var chatManager: NoLetChatManager
    @EnvironmentObject private var manager: AppManager

    @State private var showHistory: Bool = false

    @State private var messageCount: Int = 10

    let chatLastMessageID = "currentChatMessageId"

    let throttler = Throttler(delay: 0.3)

    @State private var offsetY: CGFloat = 0

    var suffixCount: Int {
        min(chatManager.chatMessages.count, 10)
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                if chatManager.chatMessages.count > suffixCount {
                    Button {
                        self.showHistory.toggle()
                    } label: {
                        HStack {
                            Spacer()
                            Text(verbatim: "\(suffixCount)/\(chatManager.chatMessages.count)")
                                .padding(.trailing, 10)
                            Text("点击查看更多")

                            Spacer()
                        }
                        .padding(.vertical)
                        .contentShape(Rectangle())
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    }
                }

                ForEach(chatManager.chatMessages.suffix(10), id: \.id) { message in
                    ChatMessageView(message: message, isLoading: manager.isLoading)
                        .id(message.id)
                }

                VStack {
                    if manager.isLoading {
                        ChatMessageView(
                            message: chatManager.currentChatMessage,
                            isLoading: manager.isLoading
                        )
                    }

                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray)
                        .opacity(0.001)
                        .frame(height: 120)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(
                                        key: OffsetKey.self,
                                        value: proxy.frame(in: .global).maxY
                                    )
                            }
                        )
                        .onPreferenceChange(OffsetKey.self) { newValue in
                            offsetY = newValue
                        }
                        .id(chatLastMessageID)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chatManager.isFocusedInput) { focused in
                if focused {
                    scrollToBottom(
                        proxy: scrollViewProxy,
                        delay: 0.3,
                        duration: 0.3
                    )
                }
            }

            .onChange(of: chatManager.currentContent) { _ in
                throttler.throttle {
                    scrollToBottom(proxy: scrollViewProxy)
                }
            }

            .onChange(of: chatManager.currentReason) { _ in
                throttler.throttle {
                    scrollToBottom(proxy: scrollViewProxy)
                }
            }

            .onChange(of: manager.isLoading) { _ in
                scrollToBottom(
                    proxy: scrollViewProxy,
                    animated: false,
                    delay: 0.3
                )
            }
            .sheet(isPresented: $showHistory) {
                if let chatgroup = chatManager.chatGroup {
                    HistoryMessage(showHistory: $showHistory, group: chatgroup.id)
                        .customPresentationCornerRadius(20)
                } else {
                    Spacer()
                        .onAppear {
                            self.showHistory.toggle()
                        }
                }
            }
            .task(id: chatLastMessageID) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollViewProxy.scrollTo(chatLastMessageID, anchor: .bottom)
                }
            }
        }
    }

    private func scrollToBottom(
        proxy: ScrollViewProxy,
        animated: Bool = true,
        delay: Double = 0,
        duration: Double = 0.1
    ) {
        guard offsetY < 900 else { return }

        let performScroll = {
            if animated {
                withAnimation(.snappy(duration: duration)) {
                    proxy.scrollTo(chatLastMessageID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(chatLastMessageID, anchor: .bottom)
            }
        }

        if delay > 0 {
            Task {
                try? await Task.sleep(
                    nanoseconds: UInt64(delay * 1_000_000_000)
                )
                performScroll()
            }
        } else {
            performScroll()
        }
    }
}

class Throttler {
    private var lastExecution: Date = .distantPast
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private var pendingWorkItem: DispatchWorkItem?

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func throttle(_ action: @escaping () -> Void) {
        let now = Date()
        let timeSinceLastExecution = now.timeIntervalSince(lastExecution)

        if timeSinceLastExecution >= delay {
            // 超过 1 秒，立即执行
            lastExecution = now
            action()
        } else {
            // 取消之前的任务，确保 1 秒内只执行最后一次
            pendingWorkItem?.cancel()

            let workItem = DispatchWorkItem {
                self.lastExecution = Date()
                action()
            }

            pendingWorkItem = workItem
            queue.asyncAfter(deadline: .now() + delay - timeSinceLastExecution, execute: workItem)
        }
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
