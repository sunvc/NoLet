//
//  MessageGroupView.swift
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

struct MessageGroupView: View {
    @ObservedObject private var messageManager = MessagesManager.shared
    @ObservedObject private var manager = AppManager.shared

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(messageManager.groupMessages, id: \.idText) { message in
                    let id = message.idText
                    let group = message.groupText
                    MessageRow(
                        message: message,
                        unread: messageManager.groupUnread[group] ?? 0,
                        onTap: {
                            manager.router = [.messageDetail(group)]
                            Haptic.impact()
                        },
                        onDelete: {
                            withAnimation(.default) {
                                messageManager.groupMessages
                                    .removeAll(where: { $0.idText == id })
                            }
                            Task.detached(priority: .background) {
                                _ = await MessagesManager.shared.delete(
                                    id: id, group: group, in: true
                                )
                            }
                        }
                    )
                    .id(message.groupText)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                    .accessibilityElement(children: .ignore)
                    .accessibilityValue(String("\(message.groupText)"))
                    .accessibilityLabel("分组消息")
                    .accessibilityHint("点击进入分组列表")
                }
            }
            .navigationTitle("分组消息")
            .scrollContentBackground(.hidden)
            .background(
                ContentBackgroundView()
                    .overlay(
                        emptyStateView
                            .opacity(messageManager.groupMessages.isEmpty ? 1 : 0)
                    )
            )
            .listStyle(.grouped)
            .onChange(of: messageManager.allCount) { _ in
                if let selectGroup = manager.selectGroup {
                    proxyTo(proxy: proxy, selectGroup: selectGroup)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("暂无消息")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func proxyTo(proxy: ScrollViewProxy, selectGroup: String?) {
        if let value = selectGroup {
            withAnimation {
                proxy.scrollTo(value, anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                manager.router = [.messageDetail(value)]
            }
        }
    }
}

struct MessageRow: View {
    var message: MessageEntity
    var unread: Int
    var onTap: () -> Void
    var onDelete: () -> Void

    @State private var bodyPreview: String = ""
    @State private var timeText: String = ""

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        f.locale = .current
        return f
    }()

    var body: some View {
        HStack {
            if unread > 0 {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }

            AvatarView(icon: message.icon)
                .frame(width: 45, height: 45)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading) {
                HStack {
                    Text(message.groupText)
                        .font(.headline.bold())
                        .foregroundStyle(.textBlack)

                    Spacer()

                    Text(timeText)
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }

                groupBody
                    .font(.footnote)
                    .lineLimit(2)
                    .foregroundStyle(.gray)
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
                .imageScale(.small)
        }
        .padding(8)
        .glassCard(15)
        .padding(.vertical, 8)
        .padding(.bottom, 3)
        .padding(.horizontal, 15)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .swipeActions(edge: .leading) {
            Button {
                let group = message.groupText
                Task.detached(priority: .userInitiated) {
                    await MessagesManager.shared.markAllRead(group: group)
                }
            } label: {
                Label("标记", systemImage: unread == 0 ? "envelope.open" : "envelope")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.primary)

            }.tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.primary)
            }.tint(.red)
        }
        .task(id: message.idText) { await prepare() }
    }

    /// Parse the markdown preview once per row (off the main thread) and cache the
    /// time string. The unread badge is passed in from a single GROUP BY query, so
    /// no per-row DB query fires as cells appear during scrolling.
    private func prepare() async {
        timeText = Self.relativeFormatter.localizedString(
            for: message.createDate ?? .now, relativeTo: Date()
        )
        let body = message.bodyText
        guard !body.isEmpty else { return }
        let preview = await Task.detached(priority: .userInitiated) {
            PBMarkdown.plain(body).replacingOccurrences(of: " ", with: "")
        }.value
        if !Task.isCancelled { bodyPreview = preview }
    }

    private var groupBody: some View {
        var text = Text(verbatim: "")

        if let title = message.title {
            text = Text(verbatim: "\(title);").foregroundColor(.blue)
        }

        if let subtitle = message.subtitle {
            text = text + Text(verbatim: "\(subtitle);").foregroundColor(.gray)
        }

        if !bodyPreview.isEmpty {
            text = text + Text(verbatim: bodyPreview).foregroundColor(.primary)
        }

        return text
    }
}

extension Date {
    func agoFormatString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = .current
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    MessageGroupView()
}
