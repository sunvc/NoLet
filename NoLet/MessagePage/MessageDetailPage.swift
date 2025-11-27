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

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: AppManager
    @StateObject private var messageManager = MessagesManager.shared

    @Default(.showMessageAvatar) var showMessageAvatar

    // 分页相关状态
    @State private var messages: [Message] = []
    @State private var allCount: Int = 1_000_000

    @State private var isLoading: Bool = false
    @State private var showAllTTL: Bool = false
    @State private var searchText: String = ""

    var body: some View {
        Group {
            if searchText.isEmpty {
                ScrollViewReader { proxy in
                    List {
                        ForEach(messages, id: \.id) { message in
                            MessageCard(
                                message: message,
                                searchText: searchText,
                                showAllTTL: showAllTTL,
                                showAvatar: showMessageAvatar
                            ) {
                                withAnimation(.easeInOut.speed(10)) {
                                    manager.selectMessage = message
                                }
                            } delete: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.default) {
                                        messages.removeAll(where: { $0.id == message.id })
                                    }
                                }

                                Task.detached(priority: .background) {
                                    _ = await MessagesManager.shared.delete(message)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                            .id(message.id)
                            .onAppear {
                                if messages.count < allCount && messages.last == message {
                                    loadData(proxy: proxy, item: message)
                                }
                            }
                        }
                    }
                    .listStyle(.grouped)
                    .animation(.easeInOut, value: messages)
                    .environmentObject(messageManager)
                    .onChange(of: messageManager.updateSign) { _ in
                        loadData(proxy: proxy, limit: max(messages.count, 150))
                    }
                }
            } else {
                SearchMessageView(group: group)
            }
        }
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            manager.searchText = searchText
        }
        .onChange(of: searchText) { value in
            if value.isEmpty {
                manager.searchText = ""
            }
        }

        .refreshable {
            loadData(limit: min(messages.count, 50))
        }
        .toolbar {
            if #available(iOS 26.0, *) {
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
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view.searchToolbarBehavior(.minimize)
                } else {
                    view
                }
            }
        }
        .task {
            loadData()

            Task.detached(priority: .background) {
                try? await DatabaseManager.shared.dbQueue.write { db in
                    // 更新指定 group 的未读消息为已读
                    let count = try Message
                        .filter(Message.Columns.group == group)
                        .filter(Message.Columns.read == false)
                        .fetchCount(db)

                    guard count > 0 else { return }

                    try Message
                        .filter(Message.Columns.group == group)
                        .filter(Message.Columns.read == false)
                        .updateAll(db, [Message.Columns.read.set(to: true)])

                    let unRead = try Message
                        .filter(Message.Columns.read == false)
                        .fetchCount(db)
                    UNUserNotificationCenter.current().setBadgeCount(unRead)
                }
            }
        }
    }

    private func loadData(proxy: ScrollViewProxy? = nil, limit: Int = 50, item: Message? = nil) {
        Task.detached(priority: .userInitiated) {
            let results = await MessagesManager.shared.query(
                group: self.group,
                limit: limit,
                item?.createDate
            )
            let count = MessagesManager.shared.count(group: self.group)
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
        }
    }
}

#Preview {
    MessageDetailPage(group: "")
}
