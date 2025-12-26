//
//  SingleMessagesView.swift
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

struct SingleMessagesView: View {
    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.limitMessageLine) var limitMessageLine
    @Default(.assistantAccouns) var assistantAccouns

    @State private var isLoading: Bool = false

    @State private var showAllTTL: Bool = false

    @EnvironmentObject private var manager: AppManager
    @EnvironmentObject private var messageManager: MessagesManager

    @State private var showLoading: Bool = false
    @State private var scrollItem: String = ""

    @State private var selectMessage: Message? = nil
    @State private var messages: [Message] = []

    private var messagesCount: Int {
        messages.count
    }

    private var messagePage: Int {
        messageManager.messagePage
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(messages, id: \.id) { message in
                    MessageCard(
                        message: message,
                        searchText: "",
                        showAllTTL: showAllTTL,
                        showAvatar: showMessageAvatar,
                        limitMessageLine: limitMessageLine,
                        assistantAccounsCount: assistantAccouns.count,
                        selectID: manager.selectID
                    ) {
                        withAnimation(.easeInOut) {
                            manager.selectMessage = message
                        }
                    } delete: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.default) {
                                messages.removeAll(where: { $0.id == message.id })
                            }
                        }

                        Task.detached(priority: .background) {
                            _ = await messageManager.delete(message)
                        }
                        Toast.success(title: "删除成功")
                    }
                    .id(message.id)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                    .onAppear {
                        if messagesCount < messageManager.allCount && messages.last == message {
                            self.loadData(proxy: proxy, item: message)
                        }
                    }
                }

                if messagesCount == 0 && showLoading {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                .scaleEffect(2)
                                .padding(.vertical, 30)
                                .padding()

                            Text("数据加载中...")
                                .foregroundColor(.primary)
                                .font(.body)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(24)
                    .shadow(radius: 10)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.grouped)
            .animation(.easeInOut, value: messagesCount)
            .refreshable {
                self.loadData(proxy: proxy, limit: messagePage)
            }
            .onChange(of: messageManager.updateSign) { _ in
                loadData(proxy: proxy, limit: max(messagesCount, messagePage))
            }
        }
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view
                        .toolbar {
                            if !(messagesCount == 0 || messagesCount == messageManager.allCount) {
                                ToolbarItem(placement: .subtitle) {
                                    allMessageCount
                                }
                            }
                        }
                } else {
                    view
                        .safeAreaInset(edge: .bottom) {
                            HStack {
                                Spacer()
                                allMessageCount
                                    .padding(.horizontal, 10)
                                    .background26(.ultraThinMaterial, radius: 5)
                            }
                            .opacity((messagesCount == 0 || messagesCount == messageManager
                                    .allCount) ? 0 : 1)
                        }
                }
            }
        }
        .task(id: "singleData") {
            self.loadData()
            Task.detached(priority: .background) {
                guard let count = await messageManager.updateRead() else { return }

                // 清除徽章
                try await UNUserNotificationCenter.current().setBadgeCount(0)

                NLog.log("更新未读条数: \(count)")
            }
        }
    }

    private var allMessageCount: some View {
        Text(verbatim: "\(messagesCount) / \(max(messageManager.allCount, messagesCount))")
            .font(.caption)
            .foregroundStyle(.gray)
    }

    private func proxyTo(proxy: ScrollViewProxy, selectID: String?) {
        if let selectID = selectID {
            withAnimation {
                proxy.scrollTo(selectID, anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                manager.selectID = nil
                manager.selectGroup = nil
            }
        }
    }

    private func loadData(
        proxy: ScrollViewProxy? = nil,
        limit: Int = 50,
        item: Message? = nil
    ) {
        guard !showLoading else { return }
        showLoading = true

        Task {

            let results = await MessagesManager.shared.query(limit: limit, item?.createDate)

            await MainActor.run {
                if item == nil {
                    messages = results
                } else {
                    messages += results
                }
                if let selectID = manager.selectID {
                    proxy?.scrollTo(selectID, anchor: .center)
                    manager.selectID = nil
                    manager.selectGroup = nil
                }
                self.showLoading = false
            }
        }
    }
}

#Preview {
    SingleMessagesView()
}
