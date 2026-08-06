//
//  WaterfallMessageView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//

//  Description:
//    瀑布流消息列表共享组件 — 封装单列/多列分流、分页哨兵、空态/加载态

//  History:
//    Created by Neo on 2026/7/24.

import SwiftUI

// MARK: - ScrollOffset PreferenceKey

struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Constants

private let waterfallSpacing: CGFloat = 5

// MARK: - WaterfallMessageView

struct WaterfallMessageView<M: RandomAccessCollection>: View where M.Element == MessageEntity {
    let messages: M
    let allCount: Int
    let columnCount: Int
    let isLoading: Bool
    let searchText: String
    let assistantAccounsCount: Int
    let showAllTTL: Bool
    let selectID: String?
    let onDelete: (MessageEntity) -> Void
    let onLoadMore: () -> Void

    @State private var paginationTriggered = false

    private var isSingleColumn: Bool { columnCount <= 1 }

    var body: some View {
        Group {
            if messages.isEmpty && isLoading {
                DataLoadingView()
            } else if messages.isEmpty {
                emptyStateView
            } else if isSingleColumn {
                singleColumnContent
            } else {
                multiColumnContent
            }
        }
        .onChange(of: messages.count) { _ in
            paginationTriggered = false
        }
    }

    // MARK: - 单列（LazyVStack + onAppear 分页）

    private var singleColumnContent: some View {
        ScrollView {
            LazyVStack(spacing: waterfallSpacing) {
                ForEach(messages, id: \.objectID) { message in
                    MessageCardView(
                        message: message,
                        searchText: searchText,
                        showAllTTL: showAllTTL,
                        assistantAccounsCount: assistantAccounsCount,
                        selectID: selectID,
                        delete: { onDelete(message) }
                    )
                    .id(message.idText)
                }
                loadMoreSentinel
            }

        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .coordinateSpace(name: "waterfallScroll")
    }

    // MARK: - 多列（LazyVGrid，懒加载避免一次性实例化全部卡片）

    private var multiColumnContent: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: waterfallSpacing),
                    count: columnCount
                ),
                spacing: waterfallSpacing
            ) {
                ForEach(messages, id: \.objectID) { message in
                    MessageCardView(
                        message: message,
                        searchText: searchText,
                        showAllTTL: showAllTTL,
                        assistantAccounsCount: assistantAccounsCount,
                        selectID: selectID,
                        delete: { onDelete(message) }
                    )
                    .id(message.idText)
                }
                loadMoreSentinel
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .coordinateSpace(name: "waterfallScroll")
    }

    // MARK: - 哨兵

    private var loadMoreSentinel: some View {
        Color.clear
            .frame(height: 1)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("waterfallScroll")).maxY
                    )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { maxY in
                guard !paginationTriggered, !isLoading, messages.count < allCount else { return }
                if maxY > 0, maxY < UIScreen.main.bounds.height + 200 {
                    paginationTriggered = true
                    onLoadMore()
                }
            }
    }

    // MARK: - 空态

    private var emptyStateView: some View {
        ScrollView {
            VStack {
                Spacer()
                HStack{
                    Spacer()
                    Text("暂无消息")
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            }
            .frame(height: 300)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .coordinateSpace(name: "waterfallScroll")
    }
}
