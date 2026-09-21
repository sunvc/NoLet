//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptMarketView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 插件中心：浏览/搜索公共库脚本；mineOnly 时为「我的上传」管理

//  History:
//    Created by Neo on 2026/9/9.

import Defaults
import SwiftUI

struct ScriptMarketView: View {
    /// true = 只看当前 iCloud 用户自己上传的脚本（可删除）
    var mineOnly: Bool = false

    @Default(.scripts) private var localScripts

    @State private var items: [ScriptShare] = []
    @State private var cursor: ScriptMarketManager.Cursor?
    @State private var loading = false
    @State private var loadingMore = false
    @State private var loadError: String?
    @State private var searchText = ""
    @State private var modeFilter: ScriptData.Mode?
    @State private var showUpload = false

    private var installedShas: Set<String> {
        Set(localScripts.map(\.id))
    }

    var body: some View {
        listContent
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .navigationTitle(mineOnly ? "我的上传" : "插件中心")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SearchBarModifier(text: $searchText, enabled: !mineOnly))
            .toolbar {
                if mineOnly {
                    ToolbarItem {
                        Button {
                            showUpload = true
                        } label: {
                            Label("上传脚本", systemImage: "square.and.arrow.up")
                        }
                    }
                } else {
                    ToolbarItem {
                        Picker(selection: $modeFilter) {
                            Text("全部类型").tag(ScriptData.Mode?.none)
                            ForEach(ScriptData.Mode.allCases, id: \.self) { mode in
                                Label(mode.title, systemImage: mode.symbol)
                                    .tag(ScriptData.Mode?.some(mode))
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .pickerStyle(.menu)
                    }
                    ToolbarItem {
                        NavigationLink {
                            ScriptMarketView(mineOnly: true)
                        } label: {
                            Label("我的上传", systemImage: "person.crop.circle")
                        }
                    }
                    ToolbarItem {
                        Button {
                            showUpload = true
                        } label: {
                            Label("上传脚本", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showUpload) {
                ScriptMarketUploadView {
                    Task { await reload() }
                }
            }
            .task(id: mineOnly ? "mine" : listIdentity) {
                if mineOnly {
                    await reload()
                } else {
                    // 输入去抖：连续打字时旧任务被取消
                    let keyword = searchText
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    if !Task.isCancelled, keyword == searchText {
                        await reload()
                    }
                }
            }
    }

    private var listIdentity: String {
        "\(modeFilter?.rawValue ?? "all")#\(searchText)"
    }

    @ViewBuilder
    private var listContent: some View {
        List {
            if loading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if let loadError {
                MarketEmptyState(
                    title: "加载失败",
                    systemImage: "exclamationmark.icloud",
                    message: loadError
                )
                .listRowBackground(Color.clear)
            } else if items.isEmpty {
                MarketEmptyState(
                    title: mineOnly ? "还没有上传过脚本" : "没有找到脚本",
                    systemImage: "sparkles",
                    message: mineOnly ? "把你的脚本分享给其他用户吧" : "换个关键词或类型试试"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(items) { item in
                    NavigationLink {
                        ScriptShareDetailView(share: item, allowDelete: mineOnly) {
                            items.removeAll { $0.id == item.id }
                        }
                    } label: {
                        ScriptShareRow(item: item, installed: installedShas.contains(item.sha256))
                    }
                }
                if cursor != nil {
                    HStack {
                        Spacer()
                        ProgressView()
                            .onAppear { Task { await loadMore() } }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func reload() async {
        loading = true
        loadError = nil
        do {
            let result: (items: [ScriptShare], cursor: ScriptMarketManager.Cursor?)
            if mineOnly {
                result = (try await ScriptMarketManager.shared.mine(), nil)
            } else {
                result = try await ScriptMarketManager.shared.list(
                    mode: modeFilter, search: searchText
                )
            }
            items = result.items
            cursor = result.cursor
        } catch {
            loadError = error.localizedDescription
        }
        loading = false
    }

    private func loadMore() async {
        guard !loadingMore, let cursor else { return }
        loadingMore = true
        do {
            let result = try await ScriptMarketManager.shared.list(
                mode: modeFilter, search: searchText, cursor: cursor
            )
            let existing = Set(items.map(\.id))
            items.append(contentsOf: result.items.filter { !existing.contains($0.id) })
            self.cursor = result.cursor
        } catch {
            // 翻页失败保留已加载内容，下一次到底再试
            self.cursor = nil
        }
        loadingMore = false
    }
}

// MARK: - Search modifier

private struct SearchBarModifier: ViewModifier {
    @Binding var text: String
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            // 显式固定在导航栏抽屉里：iPad 分屏/旋转时避免系统在
            // toolbar/drawer 两种位置间切换（会打 search bar placement 警告）
            content.searchable(
                text: $text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索名称、简介或标签"
            )
        } else {
            content
        }
    }
}

// MARK: - Empty state (iOS 16 compatible)

private struct MarketEmptyState: View {
    let title: LocalizedStringKey
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Row

private struct ScriptShareRow: View {
    let item: ScriptShare
    let installed: Bool

    private var mode: ScriptData.Mode? { ScriptData.Mode(rawValue: item.mode) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode?.symbol ?? "applescript")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body)
                        .lineLimit(1)
                    if installed {
                        Text("已安装")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
                if !item.summary.isEmpty {
                    Text(item.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(meta)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var meta: String {
        let modeTitle = mode?.title ?? item.mode
        let author = item.authorName.isEmpty ? String(localized: "匿名用户") : item.authorName
        let date = item.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? ""
        return "\(modeTitle) · \(author) · \(date)"
    }
}
