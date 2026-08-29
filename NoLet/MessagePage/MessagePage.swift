//
//  MessagePage.swift
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

struct MessagePage: View {
    @ObservedObject private var manager = AppManager.shared
    @Default(.showGroup) private var showGroup
    @Default(.servers) private var servers
    @Default(.assistantAccouns) private var assistantAccouns
    @ObservedObject private var messageManager = MessagesManager.shared
    @State private var showDeleteView: Bool = false
    @FocusState private var searchFocused: Bool

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

    var body: some View {
        ZStack {
            if isSearching {
                searchResults
            } else if showGroup {
                MessageGroupView()
            } else {
                MessageFlatListView()
            }
        }
        .animation(.easeInOut, value: showGroup)
        .animation(.easeInOut, value: isSearching)
        .toolbarTitleMenu { groupButton }
        .searchable(text: $searchText, prompt: "搜索消息")
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view.searchToolbarBehavior(.minimize)
                } else {
                    view
                }
            }
        }
        .diff { view in
            Group {
                if #available(iOS 18.0, *) {
                    view.searchFocused($searchFocused)
                } else {
                    view
                }
            }
        }
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
        .deleteTips($showDeleteView)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: messageManager
                    .allCount <= 5 ? .topBarLeading : .secondaryAction) { exampleButton }
            } else {
                ToolbarItem(placement: .secondaryAction) { exampleButton }
            }

            if !isSearching {
                ToolbarItem(placement: .secondaryAction) {
                    groupButton
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                deleteButton
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
        .background(ContentBackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
        let total = resultCount > 5000 ? "5000+" : String(max(resultCount, results.count))
        return "\(results.count) / \(total)"
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
            _ = await messageManager.delete(id: id, group: group)
        }
    }

    // MARK: - 工具栏

    private var exampleButton: some View {
        Section {
            Button {
                manager.router = [.example]
                Haptic.impact()
            } label: {
                Label("使用示例", systemImage: "questionmark.bubble")
                    .symbolRenderingMode(.palette)
                    .customForegroundStyle(Color.accent, Color.primary)
            }
        }
    }

    private var groupButton: some View {
        Section {
            Button {
                self.showGroup.toggle()
                manager.selectGroup = nil
                manager.selectID = nil
                Haptic.impact()
            } label: {
                Label(
                    showGroup ? "列表模式" : "分组模式",
                    systemImage: showGroup ? "rectangle.3.group.bubble.left" : "checklist"
                )
                .symbolRenderingMode(.palette)
                .customForegroundStyle(.accent, .primary)
                .animation(.easeInOut, value: showGroup)
            }
        }
    }

    private var deleteButton: some View {
        Button {
            self.showDeleteView = true
        } label: {
            Label("删除消息", systemImage: "trash")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.green, Color.primary)
        }
    }
}

struct DeleteAlertViewModifier: ViewModifier{
    @Binding var show: Bool
    var date: Date
    var onClose: (()-> Void)? = nil
    @State private var count: Int = 0
    func body(content: Content) -> some View {
        content
            .alert("确认删除", isPresented: $show) {
                Button("取消", role: .cancel) {
                    self.show = false
                }
                Button("删除", role: .destructive) {
                    Task.detached(priority: .userInitiated) {
                        await MainActor.run {
                            self.onClose?()
                            self.show = false
                        }
                        await MessagesManager.shared.delete(date: date)
                        await MainActor.run {
                            Toast.success(title: "删除成功")
                        }
                    }
                }
            } message: {
                VStack {
                    Text("此操作将删除 \(date.formatString()) 之前的数据 [\(count)条数据], 且无法恢复。确定要继续吗？")
                        .padding(5)
                }
            }
            .task(id: show) {
                self.count = await MessagesManager.shared.count(before: date)
            }
    }
}

struct DeleteMessageViewModifier: ViewModifier {
    @Binding var show: Bool
    @State private var date = Date()
    @State private var maxDate = Date.now.addingTimeInterval(3600)
    @State private var showAlert = false
    @State private var showDate = false
    func body(content: Content) -> some View {
        content
            .popView(
                isPresented: $show,
                onDismiss: {
                    self.showDate = false
                },
                content: {
                    VStack {
                        HStack {
                            Button(role: .destructive) {
                                self.showAlert = false
                                self.show = false
                            } label: {
                                Text("取消")
                            }
                            .padding(10)
                            .frame(minWidth: 60)
                            .glassCard(borderColor: .blue)

                            Spacer()

                            Button {
                                self.showAlert = true
                            } label: {
                                Text("确定")
                            }
                            .padding(10)
                            .frame(minWidth: 60)
                            .glassCard(borderColor: .pink)
                        }
                        .padding(10)

                        DatePicker(
                            selection: Binding(
                                get: { date.zeroDate() },
                                set: { newDate in
                                    date = newDate.zeroDate()
                                }
                            ),
                            in: ...maxDate,
                            displayedComponents: [.date, .hourAndMinute]
                        ) { }
                        .datePickerStyle(.graphical)

                    }
                    .frame(maxWidth: min(380, UIScreen.main.bounds.width * 0.9))
                    .padding(10)
                    .glassCard()
                    .modifier(DeleteAlertViewModifier(show: $showAlert, date: date, onClose: {
                        self.show = false
                    }))
                    .onAppear{
                        self.showDate = true
                        self.date = Date.now.zeroDate()
                        self.maxDate = Date.now.addingTimeInterval(100).zeroDate()
                    }
                }
            )

    }
}

extension View {
    @ViewBuilder
    func deleteTips(_ show: Binding<Bool>) -> some View {
        modifier(DeleteMessageViewModifier(show: show))
    }

    @ViewBuilder
    func deleteTips(_ show: Binding<Bool>, date: Date) -> some View {
        modifier(DeleteAlertViewModifier(show: show, date: date))
    }
}

#Preview {
    ContentView()
}
