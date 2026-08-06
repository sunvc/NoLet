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

import CoreData
import Defaults
import SwiftUI

struct MessageDetailView: View {
    let group: String

    @ObservedObject private var manager = AppManager.shared

    @Default(.assistantAccouns) var assistantAccouns

    @FetchRequest private var messages: FetchedResults<MessageEntity>

    @State private var showAllTTL: Bool = false
    @State private var searchText: String = ""

    init(group: String) {
        self.group = group
        _messages = FetchRequest(
            fetchRequest: MessageEntity.messageFetchRequest(
                predicate: NSPredicate(format: "group == %@", group)
            )
        )
    }

    var body: some View {
        ZStack {
            ContentBackgroundView()
                .ignoresSafeArea()

            Group {
                if searchText.isEmpty {
                    ScrollViewReader { proxy in
                        WaterfallMessageView(
                            messages: messages,
                            allCount: messages.count,
                            columnCount: manager.waterfallColumnCount,
                            isLoading: false,
                            searchText: searchText,
                            assistantAccounsCount: assistantAccouns.count,
                            showAllTTL: showAllTTL,
                            selectID: manager.selectID,
                            onDelete: { message in
                                let id = message.idText
                                let group = message.groupText
                                Task.detached(priority: .background) {
                                    _ = await MessagesManager.shared.delete(id: id, group: group)
                                }
                            },
                            onLoadMore: {}
                        )
                        .animation(.easeInOut, value: messages.count)
                        .onChange(of: manager.selectID) { selectID in
                            scrollTo(selectID, proxy: proxy)
                        }
                        .onAppear {
                            scrollTo(manager.selectID, proxy: proxy)
                        }
                    }
                } else {
                    MessagSearchView(group: group)
                }
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { value in
            if value.isEmpty {
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
        .onDisappear {
            manager.searchText = ""
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
                    Text(verbatim: "\(messages.count)")
                        .font(.caption)
                }
            }
        }
    }

    private func scrollTo(_ selectID: String?, proxy: ScrollViewProxy) {
        guard let selectID else { return }
        withAnimation { proxy.scrollTo(selectID, anchor: .center) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            manager.selectID = nil
            manager.selectGroup = nil
        }
    }
}

#Preview {
    MessageDetailView(group: "")
}
