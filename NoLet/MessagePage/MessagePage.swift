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
    @FocusState private var searchFocused: Bool
   
    var body: some View {
        ZStack {
            if !manager.searchText.isEmpty || searchFocused {
                SearchMessageView()
            } else {
                if showGroup {
                    GroupMessagesView()
                } else {
                    SingleMessagesView()
                }
            }
        }
        .animation(.easeInOut, value: showGroup)
        .toolbarTitleMenu { groupButton }
        .searchable(text: $searchText)
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
        .onChange(of: searchText) { value in
            if value.isEmpty {
                manager.searchText = ""
            }
        }
        .onSubmit(of: .search) {
            manager.searchText = searchText
        }
        .deleteTips($selectAction)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: messageManager
                    .allCount <= 3 ? .topBarLeading : .secondaryAction) { exampleButton }
            } else {
                ToolbarItem(placement: .secondaryAction) { exampleButton }
            }

            if manager.searchText.isEmpty && !searchFocused {
                ToolbarItem(placement: .secondaryAction) {
                    groupButton
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                deleteButton
            }
        }
        .environmentObject(messageManager)
    }

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
            Label("删除消息", systemImage: "trash")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.green, Color.primary)
        }
    }
}

extension View {
    @ViewBuilder
    func deleteTips(_ selectAction: Binding<MessageAction?>) -> some View {
        alert(
            "确认删除",
            isPresented: Binding(
                get: { selectAction.wrappedValue != nil },
                set: { _ in selectAction.wrappedValue = nil }
            )
        ) {
            Button("取消", role: .cancel) {
                selectAction.wrappedValue = nil
            }
            Button("删除", role: .destructive) {
                if let mode = selectAction.wrappedValue {
                    Task.detached(priority: .userInitiated) {
                        await MessagesManager.shared.delete(date: mode.date)
                        await MainActor.run {
                            selectAction.wrappedValue = nil
                        }
                        Toast.success(title: "删除成功")
                    }
                }
            }
        } message: {
            if let selectAction = selectAction.wrappedValue {
                Text("此操作将删除 \(selectAction.title) 数据，且无法恢复。确定要继续吗？")
            }
        }
    }
}


#Preview {
    ContentView()
}
