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

    @State private var messages: [MessageEntity] = []
    @State private var allCount: Int = 0
    @State private var searchTask: Task<Void, Never>?
    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared
    @Default(.assistantAccouns) var assistantAccouns

    @State private var searching: Bool = false
    @State private var loadingMore: Bool = false

    private var messagePage: Int {
        messageManager.messagePage
    }

    var lastMessage: MessageEntity? {
        messages.elementFromEnd(5)
    }


    var body: some View {
        ZStack {
            Group {
                if messages.isEmpty {
                    emptyStateView
                } else {
                    WaterfallMessageView(
                        messages: messages,
                        allCount: allCount,
                        columnCount: manager.waterfallColumnCount,
                        isLoading: loadingMore,
                        searchText: manager.searchText,
                        assistantAccounsCount: assistantAccouns.count,
                        showAllTTL: false,
                        selectID: manager.selectID,
                        onDelete: { message in
                            let id = message.idText
                            let group = message.groupText
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.default) {
                                    messages.removeAll(where: { $0.id == id })
                                }
                            }
                            Task.detached(priority: .background) {
                                _ = await messageManager.delete(id: id, group: group)
                            }
                        },
                        onLoadMore: {
                            loadData(limit: messagePage, item: messages.last)
                        }
                    )
                }
            }

            // New-search spinner overlays the list instead of replacing it, so the
            // scroll position survives. Pagination uses the list's own bottom sentinel
            // (loadingMore), not this overlay.
            if searching {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.3)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .animation(.easeInOut(duration: 0.2), value: searching)
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
                    verbatim: "\(messages.count) / \(allCount > 5000 ? "5000+" : String(max(allCount, messages.count)))"
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

    // MARK: - 空状态

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

    func loadData(limit: Int = 50, item: MessageEntity? = nil) {
        searchTask?.cancel()

        let beforeDate = item?.createDate
        let isPaging = item != nil
        if isPaging {
            loadingMore = true
        } else {
            searching = true
        }
        searchTask = Task { @MainActor in
            let results = await messageManager.query(
                search: manager.searchText,
                group: group,
                limit: limit,
                before: beforeDate,
                beforeID: item?.idText
            )
            guard !Task.isCancelled else { return }

            if isPaging {
                let existingIDs = Set(self.messages.map(\.id))
                self.messages += results.0.filter { !existingIDs.contains($0.id) }
            } else {
                self.messages = results.0
            }
            self.allCount = results.1
            searching = false
            loadingMore = false
        }
    }
}

#Preview {
    NavigationStack {
        MessagSearchView()
    }
}
