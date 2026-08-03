//
//  MessageDetailView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/2/13.
//

import Defaults
import SwiftUI

struct MessageDetailView: View {
    let group: String

    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared

    @Default(.assistantAccouns) var assistantAccouns

    @State private var messages: [Message] = []
    @State private var allCount: Int = 9_999_999

    @State private var isLoading: Bool = false
    @State private var showAllTTL: Bool = false
    @State private var searchText: String = ""

    private var messagePage: Int {
        messageManager.messagePage
    }

    var lastMessage: Message? {
        messages.elementFromEnd(5)
    }

    @State private var loadData: Bool = false

    var body: some View {
        ZStack {
            ContentBackgroundView()
                .ignoresSafeArea()

            Group {
                if searchText.isEmpty {
                    ScrollViewReader { proxy in
                        WaterfallMessageView(
                            messages: messages,
                            allCount: allCount,
                            columnCount: manager.waterfallColumnCount,
                            isLoading: loadData,
                            searchText: searchText,
                            assistantAccounsCount: assistantAccouns.count,
                            showAllTTL: showAllTTL,
                            selectID: manager.selectID,
                            onDelete: { message in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.default) {
                                        messages.removeAll(where: { $0.id == message.id })
                                    }
                                }
                                Task.detached(priority: .background) {
                                    _ = await MessagesManager.shared.delete(message)
                                }
                            },
                            onLoadMore: {
                                loadData(proxy: proxy, item: messages.last)
                            }
                        )
                        .scrollDismissesKeyboard(.interactively)
                        .scrollContentBackground(.hidden)
                        .animation(.easeInOut, value: messages)
                        .refreshable {
                            self.loadData(proxy: proxy, limit: messagePage)
                        }
                        .onChange(of: messageManager.updateSign) { _ in
                            loadData(proxy: proxy, limit: max(messages.count, messagePage))
                        }
                    }
                } else {
                    MessagSearchView(group: group)
                }
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { value in
            if value.isEmpty{
                manager.searchText = value
            }
        }
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view
                        .searchToolbarBehavior(.minimize)
                } else {
                    view
                }
            }
        }
        .onSubmit(of: .search) {
            if manager.searchText != searchText {
                manager.searchText = searchText
            }
        }
        .onDisappear{
            manager.searchText = ""
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }

            ToolbarItem {
                Button {
                    withAnimation {
                        self.showAllTTL.toggle()
                    }
                    Haptic.impact()
                } label: {
                    Text(verbatim: "\(messages.count)/\(allCount)")
                        .font(.caption)
                }
            }
        }
        .task {
            loadData()
        }
        .onDisappear {
            Task.detached(priority: .background) {
                let unreadInGroup = await MessageDBManager.shared.unreadCount(group: group)
                guard unreadInGroup > 0 else { return }
                await MessageDBManager.shared.markAllRead(group: group)
                let unRead = await MessageDBManager.shared.unreadCount()
                await MainActor.run {
                    UNUserNotificationCenter.current().setBadgeCount(unRead)
                }
            }
        }
    }

    private func loadData(
        proxy: ScrollViewProxy? = nil,
        limit: Int = 50,
        item: Message? = nil
    ) {
        Task {
            guard !self.loadData else { return }
            self.loadData = true
            let results = await MessagesManager.shared.query(
                group: self.group,
                limit: limit,
                item?.createDate
            )

            let count = await MessagesManager.shared.count(group: self.group)
            await MainActor.run {
                self.allCount = count
                if item == nil {
                    self.messages = results
                } else {
                    let existingIDs = Set(self.messages.map(\.id))
                    self.messages += results.filter { !existingIDs.contains($0.id) }
                }
                if let selectID = manager.selectID {
                    withAnimation {
                        proxy?.scrollTo(selectID, anchor: .center)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        manager.selectID = nil
                        manager.selectGroup = nil
                    }
                }
            }
            self.loadData = false
        }
    }
}

#Preview {
    MessageDetailView(group: "")
}
