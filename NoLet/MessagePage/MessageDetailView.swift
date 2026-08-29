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
    @ObservedObject private var messageManager = MessagesManager.shared

    @Default(.assistantAccouns) var assistantAccouns

    @FetchRequest private var messages: FetchedResults<MessageEntity>

    @State private var showAllTTL: Bool = false

    // 搜索框输入(输入过程中不触发查询)
    @State private var searchText: String = ""
    // 已提交的关键字:点击键盘「搜索」后才更新,非空即搜索模式
    @State private var submitted: String = ""
    @State private var results: [MessageEntity] = []
    @State private var resultCount: Int = 0
    @State private var searching: Bool = false
    @State private var loadingMore: Bool = false
    @State private var moreTask: Task<Void, Never>?

    private var pageSize: Int { messageManager.messagePage }
    private var isSearching: Bool { !submitted.isEmpty }

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

            // 浏览/搜索是两套数据源,切换时重建列表以重置分页哨兵和滚动位置
            Group {
                if isSearching {
                    searchResults
                } else {
                    browseList
                }
            }
            .id(isSearching)
        }
        .searchable(text: $searchText, prompt: "搜索当前分组")
        .onSubmit(of: .search) {
            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard keyword != submitted else { return }
            searching = true
            submitted = keyword
        }
        .onChange(of: searchText) { value in
            // 点取消/清空输入框:退出搜索回到浏览
            if value.isEmpty {
                submitted = ""
            }
        }
        .task(id: submitted) {
            await runSearch()
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
                    Text(verbatim: countText)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - 浏览

    private var browseList: some View {
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
    }

    // MARK: - 搜索结果

    @ViewBuilder
    private var searchResults: some View {
        ZStack {
            if results.isEmpty {
                if searching {
                    DataLoadingView(text: "搜索中...")
                } else {
                    noResultView
                }
            } else {
                WaterfallMessageView(
                    messages: results,
                    allCount: resultCount,
                    columnCount: manager.waterfallColumnCount,
                    isLoading: loadingMore,
                    searchText: submitted,
                    assistantAccounsCount: assistantAccouns.count,
                    showAllTTL: false,
                    selectID: nil,
                    onDelete: deleteResult,
                    onLoadMore: loadMore
                )

                if loadingMore {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                }
            }

            // 已有结果时重新搜索:遮罩提示,保留滚动位置
            if searching && !results.isEmpty {
                searchingOverlay
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Text(verbatim: countText)
                    .font(.caption)
                    .padding(3)
                    .foregroundStyle(.red)
                    .background26(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal)
        }
    }

    private var searchingOverlay: some View {
        ProgressView {
            Text("搜索中...")
                .font(.caption)
        }
        .progressViewStyle(.circular)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    private var noResultView: some View {
        ScrollView {
            VStack {
                Spacer()
                Text("没有找到数据")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollDismissesKeyboard(.interactively)
    }

    private var countText: String {
        if isSearching {
            let total = resultCount > 5000 ? "5000+" : String(max(resultCount, results.count))
            return "\(results.count)/\(total)"
        }
        return "\(messages.count)"
    }

    /// 由 `.task(id: submitted)` 驱动:提交关键字后才执行;重新提交会取消上一次搜索。
    @MainActor
    private func runSearch() async {
        moreTask?.cancel()
        guard isSearching else {
            results = []
            resultCount = 0
            searching = false
            loadingMore = false
            return
        }

        searching = true
        loadingMore = false
        let (rows, total) = await messageManager.query(
            search: submitted,
            group: group,
            limit: pageSize
        )
        if Task.isCancelled { return }

        results = rows
        resultCount = total
        searching = false
    }

    private func loadMore() {
        guard !searching, !loadingMore, let last = results.last else { return }
        loadingMore = true
        let keyword = submitted
        moreTask = Task { @MainActor in
            let (rows, total) = await messageManager.query(
                search: keyword,
                group: group,
                limit: pageSize,
                before: last.createDate,
                beforeID: last.idText
            )
            // 翻页在途时用户提交了新关键字/取消:结果作废,由新搜索接管。
            guard !Task.isCancelled, keyword == submitted else { return }
            let existingIDs = Set(results.map(\.idText))
            results += rows.filter { !existingIDs.contains($0.idText) }
            resultCount = total
            loadingMore = false
        }
    }

    private func deleteResult(_ message: MessageEntity) {
        let id = message.idText
        let group = message.groupText
        withAnimation(.default) {
            results.removeAll { $0.idText == id }
        }
        Task.detached(priority: .background) {
            _ = await MessagesManager.shared.delete(id: id, group: group)
        }
    }

    // MARK: - 深链滚动

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
