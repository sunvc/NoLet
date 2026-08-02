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

import SwiftUI

struct ChatMessageSection {
    var id: String = UUID().uuidString
    var title: String
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

    @ObservedObject private var chatManager = NoLetChatManager.shared
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10)]) {
                    if chatGroups.isEmpty {
                        emptyView
                    } else {
                        ForEach(chatGroupSection, id: \.id) { section in
                            chatView(section: section)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
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
                            await ChatGroupDBManager.shared.rename(
                                id: chatgroup.id,
                                newName: text,
                                makeCurrent: false
                            )
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
                ToolbarItem {
                    Menu {
                        Button {
                            Task {
                                await ChatGroupDBManager.shared.deleteAll()
                                await MainActor.run {
                                    Haptic.impact()
                                    chatGroups = []
                                }
                            }
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
                        chatgroup.name.removingAllWhitespace,
                        systemImage: getleftIconName(group: chatgroup.id)
                    )
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
            let groups = await ChatGroupDBManager.shared.fetchAll()
            await MainActor.run {
                self.chatGroups = groups
            }
        }
    }

    private func getleftIconName(group: String) -> String {
        let count = ChatMessageDBManager.shared.countSync(inGroup: group)
        return count == 0 ? "rectangle.3.group.bubble" : "message.badge.circle"
    }

    fileprivate enum ChatTimeSection: CaseIterable {
        case today
        case yesterday
        case dayBeforeYesterday
        case twoDaysAgo
        case oneWeek
        case twoWeeks
        case oneMonth
        case threeMonth
        case halfYear
        case earlier
        
        var title: String {
            switch self {
            case .today: String(localized: "今天")
            case .yesterday: String(localized: "昨天")
            case .dayBeforeYesterday: String(localized: "前天")
            case .twoDaysAgo: String(localized: "2天前")
            case .oneWeek: String(localized: "一周前")
            case .twoWeeks: String(localized: "两周前")
            case .oneMonth: String(localized: "1月前")
            case .threeMonth: String(localized: "3月前")
            case .halfYear: String(localized: "半年前")
            case .earlier: String(localized: "更早")
            }
        }
        
        static func match(date: Date, calendar: Calendar, todayStart: Date) -> Self {
            guard
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart),
                let d1 = calendar.date(byAdding: .day, value: -1, to: todayStart),
                let d2 = calendar.date(byAdding: .day, value: -2, to: todayStart),
                let d3 = calendar.date(byAdding: .day, value: -3, to: todayStart),
                let d7 = calendar.date(byAdding: .day, value: -7, to: todayStart),
                let d14 = calendar.date(byAdding: .day, value: -14, to: todayStart),
                let m1 = calendar.date(byAdding: .month, value: -1, to: todayStart),
                let m3 = calendar.date(byAdding: .month, value: -3, to: todayStart),
                let m6 = calendar.date(byAdding: .month, value: -6, to: todayStart)
            else { return .earlier }
            
            switch date {
            case todayStart..<tomorrow: return .today
            case d1..<todayStart: return .yesterday
            case d2..<d1: return .dayBeforeYesterday
            case d3..<d2: return .twoDaysAgo
            case d7..<d3: return .oneWeek
            case d14..<d7: return .twoWeeks
            case m1..<d14: return .oneMonth
            case m3..<m1: return .threeMonth
            case m6..<m3: return .halfYear
            default: return .earlier
            }
        }
    }

    private func getGroupedMessages(allMessages: [ChatGroup]) -> [ChatMessageSection] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        var bucket: [ChatTimeSection: [ChatGroup]] = [:]
        
        allMessages.forEach { msg in
            let sectionType = ChatTimeSection.match(date: msg.timestamp, calendar: calendar, todayStart: todayStart)
            bucket[sectionType, default: []].append(msg)
        }
        
        return ChatTimeSection.allCases.compactMap { sectionType in
            guard let list = bucket[sectionType], !list.isEmpty else { return nil }
            return ChatMessageSection(title: sectionType.title, messages: list)
        }
    }
}

#Preview {
    ChatGroupHistoryView(show: .constant(false))
}
