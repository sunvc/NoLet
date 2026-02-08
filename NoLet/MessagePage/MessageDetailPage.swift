//
//  MessageDetailPage.swift
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
import GRDB
import SwiftUI

struct MessageDetailPage: View {
    let group: String

    @EnvironmentObject private var manager: AppManager
    @Environment(\.horizontalSizeClass) var sizeClass
    @StateObject private var messageManager = MessagesManager.shared

    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.assistantAccouns) var assistantAccouns

    // 分页相关状态
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

    var columns: [GridItem] {
        return Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: sizeClass == .compact ? 1 : 2
        )
    }

    @State private var loadData: Bool = false

    var body: some View {
        Group {
            if searchText.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(messages, id: \.id) { message in
                                MessageCard(
                                    message: message,
                                    searchText: searchText,
                                    showAllTTL: showAllTTL,
                                    showAvatar: showMessageAvatar,
                                    assistantAccounsCount: assistantAccouns.count,
                                    selectID: manager.selectID
                                ) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.default) {
                                            messages.removeAll(where: { $0.id == message.id })
                                        }
                                    }

                                    Task.detached(priority: .background) {
                                        _ = await MessagesManager.shared.delete(message)
                                    }
                                }
                                .id(message.id)
                                .onAppear {
                                    if messages.count < allCount && lastMessage == message {
                                        loadData(proxy: proxy, item: message)
                                    }
                                }
                            }
                        }
                        if loadData {
                            DataLoadingView()
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollContentBackground(.hidden)
                    .background(.gray.opacity(0.1))
                    .animation(.easeInOut, value: messages)
                    .environmentObject(messageManager)
                    .refreshable {
                        self.loadData(proxy: proxy, limit: messagePage)
                    }
                    .onChange(of: messageManager.updateSign) { _ in
                        loadData(proxy: proxy, limit: max(messages.count, messagePage))
                    }
                }
            } else {
                SearchMessageView(group: group)
            }
        }
        .searchable(text: $searchText)
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
            manager.searchText = searchText
        }
        .onChange(of: searchText) { value in
            if value.isEmpty {
                manager.searchText = ""
            }
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
                try? await DatabaseManager.shared.dbQueue.write { db in
                    // 更新指定 group 的未读消息为已读
                    let count = try Message
                        .filter(Message.Columns.group == group)
                        .filter(Message.Columns.isRead == false)
                        .fetchCount(db)

                    guard count > 0 else { return }

                    try Message
                        .filter(Message.Columns.group == group)
                        .filter(Message.Columns.isRead == false)
                        .updateAll(db, [Message.Columns.isRead.set(to: true)])

                    let unRead = try Message
                        .filter(Message.Columns.isRead == false)
                        .fetchCount(db)
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
                    self.messages += results
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
    MessageDetailPage(group: "")
}
