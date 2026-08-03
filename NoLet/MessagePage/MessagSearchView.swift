//
//  MessagSearchView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import Defaults
import SwiftUI

struct MessagSearchView: View {
    var group: String?

    @Environment(\.colorScheme) var colorScheme

    @State private var messages: [Message] = []
    @State private var allCount: Int = 0
    @State private var searchTask: Task<Void, Never>?
    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared
    @Default(.assistantAccouns) var assistantAccouns

    @State private var searched: Bool = false

    private var messagePage: Int {
        messageManager.messagePage
    }

    var lastMessage: Message? {
        messages.elementFromEnd(5)
    }


    var body: some View {
        Group {
            if searched {
                searchingView
            } else if messages.isEmpty {
                emptyStateView
            } else {
                WaterfallMessageView(
                    messages: messages,
                    allCount: allCount,
                    columnCount: manager.waterfallColumnCount,
                    isLoading: false,
                    searchText: manager.searchText,
                    assistantAccounsCount: assistantAccouns.count,
                    showAllTTL: false,
                    selectID: manager.selectID,
                    onDelete: { message in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.default) {
                                messages.removeAll(where: { $0.id == message.id })
                            }
                        }
                        Task.detached(priority: .background) {
                            _ = await messageManager.delete(message)
                        }
                    },
                    onLoadMore: {
                        loadData(limit: messagePage, item: messages.last)
                    }
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .animation(.interactiveSpring, value: messages.count)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .if(colorScheme == .light) { view in
            view.background(.ultraThinMaterial)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Text(
                    verbatim: "\(messages.count) / \(max(allCount, messages.count))"
                )
                .font(.caption)
                .padding(3)
                .foregroundStyle(.red)
                .background26(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.allCount = messageManager.allCount
            }
        }
        .onChange(of: manager.searchText){value in 
            loadData(limit: messagePage)
        }
    }

    // MARK: - 搜索/空状态

    private var searchingView: some View {
        ScrollView {
            VStack {
                Spacer()
                Text("搜索中...")
                    .font(.title3.bold())
                    .foregroundStyle(.green)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack {
                Spacer()
                if manager.searchText.isEmpty {
                    Text("搜索历史消息")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                } else {
                    Text("没有找到数据")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func loadData(limit: Int = 30, item: Message? = nil) {
        searchTask?.cancel()

        searchTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.searched = true
            }

            let results: ([Message], Int)

            results = await messageManager.query(
                search: manager.searchText,
                group: group,
                limit: limit,
                item?.createDate
            )

            await MainActor.run {
                if item == nil {
                    self.messages = results.0
                } else {
                    let existingIDs = Set(self.messages.map(\.id))
                    self.messages += results.0.filter { !existingIDs.contains($0.id) }
                }
                self.allCount = results.1
                self.searched = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        MessagSearchView()
    }
}
