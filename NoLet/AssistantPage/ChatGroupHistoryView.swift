//
//  ChatGroupHistoryView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/2/25.
//

import GRDB
import SwiftUI

struct ChatMessageSection {
    var id: String = UUID().uuidString
    var title: String // 分组名称，例如 "[今天]"
    var messages: [ChatGroup]
}

struct ChatGroupHistoryView: View {
    @State private var chatGroups: [ChatGroup] = []

    var chatGroupSection: [ChatMessageSection] {
        getGroupedMessages(allMessages: chatGroups)
    }

    @Binding var show: Bool
    @State private var text: String = ""
    @State private var showChangeGroupName: Bool = false

    @State private var selectdChatGroup: ChatGroup? = nil

    @EnvironmentObject private var chatManager: NoLetChatManager
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 10, pinnedViews: .sectionHeaders) {
                        if chatGroups.isEmpty {
                            emptyView
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(chatGroupSection, id: \.id) { section in
                                chatView(section: section)
                                    .listRowInsets(EdgeInsets(
                                        top: 10,
                                        leading: 0,
                                        bottom: 0,
                                        trailing: 0
                                    ))
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .listStyle(.grouped)
            }
            .navigationTitle("最近使用")
            .searchable(text: $text)
            .popView(isPresented: $showChangeGroupName) {
                withAnimation {
                    showChangeGroupName = false
                    self.selectdChatGroup = nil
                }
            } content: {
                if let chatgroup = selectdChatGroup {
                    CustomAlertWithTextField($showChangeGroupName, text: chatgroup.name) { text in
                        Task.detached(priority: .background) {
                            do {
                                try await DatabaseManager.shared.dbQueue.write { db in
                                    if var group = try ChatGroup
                                        .filter(ChatGroup.Columns.id == chatgroup.id)
                                        .fetchOne(db)
                                    {
                                        group.name = text
                                        try group.update(db)
                                    }
                                }
                            } catch {
                                logger.error("❌ 更新 group.name 失败: \(error)")
                            }
                        }
                    }

                } else {
                    Spacer()
                        .onAppear {
                            self.showChangeGroupName = false
                            self.selectdChatGroup = nil
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Label("关闭", systemImage: "xmark")
                        .VButton(onRelease: { _ in
                            self.show.toggle()
                            return true
                        })
                }

                ToolbarItem {
                    Menu {
                        Button {
                            _ = try? DatabaseManager.shared.dbQueue.write { db in
                                try ChatGroup.deleteAll(db)
                            }
                            Haptic.impact()
                            chatGroups = []
                        } label: {
                            Label("删除所有分组", systemImage: "trash")
                                .customForegroundStyle(.red, .primary)
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
            .task {
                loadGroups()
            }
        }
    }

    @ViewBuilder
    private func chatView(section: ChatMessageSection) -> some View {
        Section {
            ForEach(section.messages, id: \.id) { chatgroup in
                HStack {
                    Label(
                        chatgroup.name.trimmingSpaceAndNewLines,
                        systemImage: getleftIconName(group: chatgroup.id)
                    )
                    .fontWeight(.medium)
                    .lineLimit(1) // 限制为单行
                    .truncationMode(.tail) // 超出部分用省略号
                    .padding(.vertical, 10)
                    .padding(.leading, 10)
                    .foregroundColor(chatManager.chatGroup == chatgroup ? .green : .primary)
                    Spacer()

                    Image(systemName: "chevron.right")
                        .imageScale(.large)
                        .foregroundColor(chatManager.chatGroup == chatgroup ? .green : .gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 10)
                .onTapGesture {
                    chatManager.setGroup(group: chatgroup)
                    self.show.toggle()
                }
                .swipeActions(edge: .leading) {
                    Button {
                        self.selectdChatGroup = chatgroup
                        self.showChangeGroupName = true
                    } label: {
                        Label("重命名", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }.tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        Task.detached(priority: .background) {
                            await chatManager.delete(groupID: chatgroup.id)
                            await loadGroups()
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }.tint(.red)
                }
            }
        } header: {
            HStack {
                Text(section.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .padding(.leading)

                Spacer()
            }
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
        }
    }

    private var emptyView: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Image(systemName: "plus.message")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)
                Spacer()
            }
            .padding(.top, 50)
            .padding(.bottom, 20)
            HStack {
                Spacer()
                Text("无聊天")
                    .font(.title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom)
            HStack(alignment: .center) {
                Spacer()
                Text("当您与智能助手对话时，您的对话将显示在此处")
                    .font(.body)
                    .multilineTextAlignment(.center)
                Spacer()

            }.padding(.bottom)
            HStack {
                Spacer()
                Button(role: .destructive) {
                    chatManager.setGroup()
                    chatManager.chatMessages = []
                    self.show.toggle()
                    Haptic.impact()
                } label: {
                    Text("开始新聊天")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }

                Spacer()
            }
        }.padding()
    }

    private func loadGroups() {
        Task.detached(priority: .background) {
            do {
                let groups = try await DatabaseManager.shared.dbQueue.read { db in
                    try ChatGroup.order(ChatGroup.Columns.timestamp.desc).fetchAll(db)
                }
                await MainActor.run {
                    self.chatGroups = groups
                }
            } catch {
                logger.error("❌ \(error)")
            }
        }
    }

    private func getleftIconName(group: String) -> String {
        let count = try? DatabaseManager.shared.dbQueue.read { db in
            try ChatMessage
                .filter(ChatMessage.Columns.message == group)
                .fetchCount(db)
        }
        return (count ?? 0) == 0 ? "rectangle.3.group.bubble" : "message.badge.circle"
    }

    private func getGroupedMessages(allMessages: [ChatGroup]) -> [ChatMessageSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func day(_ value: Int, _ component: Calendar.Component = .day) -> Date {
            calendar.date(byAdding: .month, value: value, to: today)!
        }

        let timeIntervals: [(String, Date, Date)] = [
            (String(localized: "今天"), today, day(1)),
            (String(localized: "昨天"), day(-1), today),
            (String(localized: "前天"), day(-2), day(-1)),
            (String(localized: "2天前"), day(-3), day(-2)),
            (String(localized: "一周前"), day(-7), day(-3)),
            (String(localized: "两周前"), day(-14), day(-7)),
            (String(localized: "1月前"), day(-1, .month), day(-14, .month)),
            (String(localized: "3月前"), day(-3, .month), day(-1, .month)),
            (String(localized: "半年前"), day(-6, .month), day(-3, .month)),
        ]

        return timeIntervals.compactMap { title, start, end in
            let messages = allMessages.filter {
                $0.timestamp >= start && $0.timestamp < end
            }
            return messages.isEmpty
                ? nil
                : ChatMessageSection(title: title, messages: messages)
        }
    }
}

#Preview {
    ChatGroupHistoryView(show: .constant(false))
}
