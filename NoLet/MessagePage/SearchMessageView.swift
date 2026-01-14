//
//  SearchMessageView.swift
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

struct SearchMessageView: View {
    var group: String?

    @Environment(\.colorScheme) var colorScheme
    @State private var messages: [Message] = []
    @State private var allCount: Int = 0
    @State private var searchTask: Task<Void, Never>?
    @StateObject private var manager = AppManager.shared
    @StateObject private var messageManager = MessagesManager.shared
    @Default(.limitMessageLine) var limitMessageLine
    @Default(.assistantAccouns) var assistantAccouns

    @State private var searched: Bool = false

    private var messagePage: Int {
        messageManager.messagePage
    }

    var lastMessage: Message? {
        messages.elementFromEnd(5)
    }

    var body: some View {
        List {
            if searched{
                HStack {
                    Spacer()
                    Text("搜索中...")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
            }else if messages.count == 0 && manager.searchText.isEmpty {
                HStack {
                    Spacer()
                    Text("搜索历史消息")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
            } else if messages.count == 0 && !manager.searchText.isEmpty {
                HStack {
                    Spacer()
                    Text("没有找到数据")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
            } else {
                ForEach(messages, id: \.id) { message in
                    MessageCard(
                        message: message,
                        searchText: manager.searchText,
                        showGroup: true,
                        limitMessageLine: limitMessageLine,
                        assistantAccounsCount: assistantAccouns.count,
                        selectID: manager.selectID
                    ) {
                        self.hideKeyboard()
                        withAnimation(.easeInOut) {
                            manager.selectMessage = message
                        }
                    } delete: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.default) {
                                messages.removeAll(where: { $0.id == message.id })
                            }
                        }

                        Task.detached(priority: .background) {
                            _ = await messageManager.delete(message)
                        }
                    }
                    .id(message.id)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                    .onAppear {
                        if messages.count < allCount && lastMessage == message {
                            loadData(limit: messagePage, item: message)
                        }
                    }
                }
            }

            Spacer(minLength: 30)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
        }
        .listStyle(.grouped)
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
        .onChange(of: manager.searchText) { _ in
            loadData(limit: messagePage)
        }
    }

    func loadData(limit: Int = 30, item: Message? = nil) {
        searchTask?.cancel()

        searchTask = Task.detached(priority: .userInitiated) {
//            try? await Task.sleep(nanoseconds: 200_000_000) // 防抖延迟
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
                    self.messages += results.0
                }
                self.allCount = results.1
                self.searched = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchMessageView()
    }
}
