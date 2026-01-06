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
    @EnvironmentObject private var manager: AppManager
    @Default(.showGroup) private var showGroup
    @Default(.servers) private var servers
    @StateObject private var messageManager = MessagesManager.shared
    @State private var showDeleteAction: Bool = false
    @State private var searchText: String = ""
    @State private var selectAction: MessageAction? = nil

    var body: some View {
        ZStack {
            if showGroup {
                GroupMessagesView()
            } else {
                SingleMessagesView()
            }
            
            if #unavailable(iOS 26.0) {
                if !manager.searchText.isEmpty {
                    SearchMessageView()
                }
            }
        }
        .navigationTitle("消息")
        .animation(.easeInOut, value: showGroup)
        .toolbarTitleMenu{
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
                    .symbolEffect(delay: 0)
                }
            }
        }
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view
                } else {
                    view
                        .searchable(text: $searchText)
                        .onChange(of: searchText) { value in
                            if value.isEmpty {
                                manager.searchText = ""
                            }
                        }
                        .onSubmit(of: .search) {
                            manager.searchText = searchText
                        }
                }
            }
        }
        .alert(
            "确认删除",
            isPresented: Binding(get: { selectAction != nil }, set: { _ in selectAction = nil })
        ) {
            Button("取消", role: .cancel) {
                self.selectAction = nil
            }
            Button("删除", role: .destructive) {
                if let mode = selectAction {
                    Task.detached(priority: .userInitiated) {
                        await messageManager.delete(date: mode.date)
                        await MainActor.run {
                            self.selectAction = nil
                        }
                    }
                }
            }
        } message: {
            if let selectAction {
                Text("此操作将删除 \(selectAction.title) 数据，且无法恢复。确定要继续吗？")
            }
        }
        .environmentObject(messageManager)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: messageManager.allCount <= 3 ? .topBarLeading : .secondaryAction) {
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
            }else{
                ToolbarItem(placement: .secondaryAction) {
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
            }
            
            
            ToolbarItem(placement: .secondaryAction) {
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
                        .symbolEffect(delay: 0)
                    }
                }
            }
            
            
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    ForEach(MessageAction.allCases, id: \.self) { item in
                        if item == .cancel {
                            Section {
                                Button(role: .destructive) {} label: {
                                    Label(item.title, systemImage: "xmark.seal")
                                        .symbolRenderingMode(.palette)
                                        .customForegroundStyle(.accent, .primary)
                                }
                            }
                        } else {
                            Section {
                                Button {
                                    self.selectAction = item
                                } label: {
                                    Label(item.title, systemImage: "trash")
                                        .symbolRenderingMode(.palette)
                                        .customForegroundStyle(.accent, .primary)
                                }
                            }
                        }
                    }
                } label: {
                    Label("按条件删除消息", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
