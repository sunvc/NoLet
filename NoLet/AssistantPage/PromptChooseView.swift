//
//  PromptChooseView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/28.
//

import Defaults
import Foundation
import GRDB
import SwiftUI

// MARK: - Views

/// 提示词选择视图
struct PromptChooseView: View {
    // MARK: - Properties

    @Binding var show: Bool
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var chatManager: NoLetChatManager

    @State private var prompts: [ChatPrompt] = []

    @State private var isAddingPrompt = false
    @State private var searchText = ""
    @State private var selectedPrompt: ChatPrompt? = nil

    @Default(.customReasoningEffort) private var customReasoningEffort

    private var filteredBuiltInPrompts: [ChatPrompt] {
        guard !searchText.isEmpty else { return prompts.filter { $0.inside } }
        return prompts.filter { $0.inside }.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredCustomPrompts: [ChatPrompt] {
        guard !searchText.isEmpty else { return prompts.filter { !$0.inside } }
        return prompts.filter { !$0.inside }.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hasSearchResults: Bool {
        !searchText.isEmpty && filteredBuiltInPrompts.isEmpty && filteredCustomPrompts.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if hasSearchResults {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView("没有找到相关提示词", systemImage: "magnifyingglass")
                    } else {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .padding()
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                Text("没有找到相关提示词")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding()
                                Spacer()
                            }
                        }.frame(height: 300)
                    }

                } else {
                    Section {
                        Picker(selection: $chatManager.reasoningEffort) {
                            ForEach(
                                ReasoningEffort.allCases(customReasoningEffort),
                                id: \.self
                            ) { item in
                                Text(item.rawValue)
                                    .tag(item)
                            }
                        } label: {
                            Label {
                                Text("推理能力")
                            } icon: {
                                Image(systemName: chatManager.reasoningEffort.symbol)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.tint, Color.primary)
                            }
                        }
                    }

                    Group {
                        if !filteredBuiltInPrompts.isEmpty {
                            PromptSection(
                                selectID: chatManager.chatPrompt?.id,
                                title: String(localized: "内置扩展功能"),
                                prompts: filteredBuiltInPrompts,
                                onPromptTap: handlePromptTap
                            )
                        }

                        if !filteredCustomPrompts.isEmpty {
                            PromptSection(
                                selectID: chatManager.chatPrompt?.id,
                                title: String(localized: "自定义扩展"),
                                prompts: filteredCustomPrompts,
                                onPromptTap: handlePromptTap
                            )
                        }
                    }
                    .environmentObject(chatManager)
                }
            }
            .sheet(isPresented: $isAddingPrompt) {
                AddPromptView(show: $isAddingPrompt)
                    .customPresentationCornerRadius(50)
            }
            .navigationTitle("选择功能")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer,
                prompt: "搜索扩展功能"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消", role: .cancel) {
                        self.show = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingPrompt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                loadData()
            }
            .onChange(of: chatManager.promptCount) { _ in
                loadData()
            }
        }
    }

    private func loadData() {
        Task.detached(priority: .background) {
            do {
                let results = try await DatabaseManager.shared.dbQueue.read { db in
                    try ChatPrompt.fetchAll(db)
                }
                await MainActor.run {
                    self.prompts = results
                }
            } catch {
                NLog.error(error.localizedDescription)
            }
        }
    }

    // MARK: - Methods

    private func handlePromptTap(_ prompt: ChatPrompt) {
        if chatManager.chatPrompt == prompt {
            chatManager.chatPrompt = nil
        } else {
            chatManager.chatPrompt = prompt
            AppManager.shared.open(sheet: nil)
        }
    }
}

// MARK: - PromptSection

private struct PromptSection: View {
    let selectID: String?
    let title: String
    let prompts: [ChatPrompt]
    let onPromptTap: (ChatPrompt) -> Void

    @State private var showDeleteAlert = false
    @State private var promptToDelete: ChatPrompt?

    var body: some View {
        Section(title) {
            ForEach(prompts) { prompt in
                PromptRowView(prompt: prompt, selectID: selectID)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPromptTap(prompt)
                    }
                    .modifier(PromptSwipeActions(
                        prompt: prompt,
                        showDeleteAlert: $showDeleteAlert,
                        promptToDelete: $promptToDelete
                    ))
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert, presenting: promptToDelete) { _ in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let prompt = promptToDelete {
                    Task.detached(priority: .userInitiated) {
                        do {
                            _ = try await DatabaseManager.shared.dbQueue.write { db in
                                try ChatPrompt
                                    .filter(Column("id") == prompt.id)
                                    .deleteAll(db)
                            }
                        } catch {
                            NLog.error("❌ 删除 ChatPrompt 失败: \(error)")
                        }
                    }
                }
            }
        } message: { prompt in
            Text("确定要删除\"\(prompt.title)\"提示词吗？此操作无法撤销。")
        }
    }
}

// MARK: - PromptRowView

private struct PromptRowView: View {
    let prompt: ChatPrompt
    var selectID: String?
    var body: some View {
        HStack(spacing: 12) {
            // 选中状态指示器
            Circle()
                .fill(prompt.id == selectID ? Color.blue : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .strokeBorder(
                            prompt.id == selectID ? Color.blue : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )

            // 提示词内容
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if prompt.inside {
                        Text("内置")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    if prompt.mode == .mcp {
                        Text(prompt.mode.name)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()
                }

                if !prompt.content.isEmpty {
                    Text(prompt.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

// MARK: - PromptSwipeActions

private struct PromptSwipeActions: ViewModifier {
    let prompt: ChatPrompt
    @Binding var showDeleteAlert: Bool
    @Binding var promptToDelete: ChatPrompt?

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                // 编辑按钮
                NavigationLink {
                    PromptDetailView(prompt: prompt)
                } label: {
                    Label("查看", systemImage: "eye")
                }
                .tint(.blue)
            }
            .if(!prompt.inside) {
                $0.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        promptToDelete = prompt
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
    }
}

// MARK: - 添加Prompt视图

struct AddPromptView: View {
    // MARK: - Properties

    @Binding var show: Bool

    @State private var title = ""
    @State private var content = ""
    @State private var address = ""

    // MARK: - View

    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("网络地址", text: $address)
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            .navigationTitle("添加 Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        self.show = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let chatprompt = ChatPrompt(
                            id: UUID().uuidString,
                            timestamp: Date(),
                            title: title,
                            content: content,
                            inside: false
                        )
                        Task.detached(priority: .userInitiated) {
                            do {
                                try await DatabaseManager.shared.dbQueue.write { db in
                                    try chatprompt.insert(db)
                                }
                                await MainActor.run {
                                    AppManager.shared.open(sheet: nil)
                                }

                            } catch {
                                NLog.error("❌ 插入 ChatPrompt 失败: \(error)")
                            }
                        }
                    }
                    .disabled(!(!title.isEmpty && !content.isEmpty))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("提示词选择") {
    PromptChooseView(show: .constant(true))
}
