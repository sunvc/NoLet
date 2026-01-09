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
    @StateObject private var messageManager = MessagesManager.shared

    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.limitMessageLine) var limitMessageLine
    @Default(.assistantAccouns) var assistantAccouns

    // 分页相关状态
    @State private var messages: [Message] = []
    @State private var allCount: Int = 1_000_000

    @State private var isLoading: Bool = false
    @State private var showAllTTL: Bool = false
    @State private var searchText: String = ""
    
    private var messagePage:Int {
        messageManager.messagePage    
    }

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
                                showAvatar: showMessageAvatar,
                                limitMessageLine: limitMessageLine,
                                assistantAccounsCount: assistantAccouns.count,
                                selectID: manager.selectID
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
                            .id(message.id)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
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
                    .refreshable {
                        self.loadData(proxy: proxy, limit:  messagePage)
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

    private func loadData(proxy: ScrollViewProxy? = nil, limit: Int = 20, item: Message? = nil) {
        Task{
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
        }
    }
}

#Preview {
    MessageDetailPage(group: "")
}
