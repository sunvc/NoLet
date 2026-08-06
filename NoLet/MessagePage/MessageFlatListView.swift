//
//  MessageFlatListView.swift
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

struct MessageFlatListView: View {
    @Default(.assistantAccouns) var assistantAccouns

    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared

    @FetchRequest(fetchRequest: MessageEntity.messageFetchRequest())
    private var messages: FetchedResults<MessageEntity>

    @State private var showAllTTL: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            WaterfallMessageView(
                messages: messages,
                allCount: messages.count,
                columnCount: manager.waterfallColumnCount,
                isLoading: false,
                searchText: "",
                assistantAccounsCount: assistantAccouns.count,
                showAllTTL: showAllTTL,
                selectID: manager.selectID,
                onDelete: { message in
                    let id = message.idText
                    let group = message.groupText
                    Task.detached(priority: .background) {
                        _ = await messageManager.delete(id: id, group: group)
                    }
                    Toast.success(title: "删除成功")
                },
                onLoadMore: {}
            )
            .onChange(of: manager.selectID) { selectID in
                scrollTo(selectID, proxy: proxy)
            }
            .onAppear {
                scrollTo(manager.selectID, proxy: proxy)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle("消息列表")
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view
                        .toolbar {
                            if !messages.isEmpty {
                                ToolbarItem(placement: .subtitle) {
                                    allMessageCount(messages.count)
                                }
                            }
                        }
                } else {
                    view
                        .safeAreaInset(edge: .bottom) {
                            HStack {
                                Spacer()
                                allMessageCount(messages.count)
                                    .padding(.horizontal, 10)
                                    .background26(.ultraThinMaterial, radius: 5)
                            }
                            .opacity(messages.isEmpty ? 0 : 1)
                        }
                }
            }
        }
        .task {
            await messageManager.updateRead()
        }
    }

    private func scrollTo(_ selectID: String?, proxy: ScrollViewProxy) {
        guard let selectID else { return }
        withAnimation { proxy.scrollTo(selectID, anchor: .center) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            manager.selectID = nil
            manager.selectGroup = nil
        }
    }

    private func allMessageCount(_ count: Int) -> some View {
        Text(verbatim: "\(count)")
            .font(.caption)
            .foregroundStyle(.gray)
    }
}

extension Array {
    func elementFromEnd(_ index: Int) -> Element? {
        let targetIndex = count - index
        guard targetIndex >= 0 else { return nil }
        return self[targetIndex]
    }
}

struct DataLoadingView: View {
    var text: String = .init(localized: "数据加载中...")
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(2)
                .padding(.vertical, 30)
                .padding()

            Text(text)
                .foregroundColor(.primary)
                .font(.body)
                .bold()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MessageFlatListView()
}
