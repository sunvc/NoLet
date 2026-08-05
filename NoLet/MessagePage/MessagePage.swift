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
import GRDB

struct MessagePage: View {
    @ObservedObject private var manager = AppManager.shared
    @Default(.showGroup) private var showGroup
    @Default(.servers) private var servers
    @ObservedObject private var messageManager = MessagesManager.shared
    @State private var showDeleteAction: Bool = false
    @State private var searchText: String = ""
    @State private var showDeleteView: Bool = false
    @FocusState private var searchFocused: Bool
    @State private var selectedDate = Date()
    @State private var maxDate = Date()

    var body: some View {
        ZStack {
            if !searchText.isEmpty || searchFocused {
                MessagSearchView()
            } else {
                if showGroup {
                    MessageGroupView()
                } else {
                    MessageFlatListView()
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
        .onSubmit(of: .search) {
            manager.searchText = searchText
        }
        .onChange(of: searchText) { value in
            if value.isEmpty{
                manager.searchText = value
            }
        }
        .deleteTips($showDeleteView)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: messageManager
                    .allCount <= 5 ? .topBarLeading : .secondaryAction) { exampleButton }
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
                        await MessagesManager.shared.delete(date: date)
                        await MainActor.run {
                            self.onClose?()
                            self.show = false
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
                if let count = try? DatabaseManager.shared.dbQueue.read({ db in
                    return try Message
                        .filter(Message.Columns.createDate < date)
                        .fetchCount(db)
                }){
                    self.count = count
                }
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
