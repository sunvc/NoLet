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
import Foundation
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
        min(chatManager.currentMessagesCount, 10)
    }

    let height = UIScreen.main.bounds.height

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(.vertical) {
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

                ForEach(chatManager.chatMessages, id: \.id) { message in
                    ChatMessageView(message: message)
                        .id(message.id)
                }

                Rectangle()
                    .fill(Color.clear)
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
                        Task { @MainActor in
                            offsetY = newValue
                        }
                    }
                    .id(chatLastMessageID)
            }

            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chatManager.isFocusedInput) { _ in
                proxy(scrollViewProxy)
            }

            .onChange(of: chatManager.currentContent) { _ in
                if offsetY - height < 100 {
                    throttler.throttle {
                        proxy(scrollViewProxy)
                    }
                }
            }
            .onChange(of: chatManager.chatGroup) { _ in
                proxy(scrollViewProxy)
            }
            .onChange(of: manager.isLoading) { _ in
                proxy(scrollViewProxy)
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
                proxy(scrollViewProxy)
            }
        }
    }

    func proxy(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo(chatLastMessageID, anchor: .bottom)
            }
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
