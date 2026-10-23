//
//  WatchMessageListView.swift
//  Welet Watch App
//

import SwiftUI

struct WatchMessageListView: View {
    @EnvironmentObject private var store: WatchMessageStore

    var body: some View {
        NavigationStack {
            Group {
                if store.messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }
            }
            .navigationTitle("消息")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await store.refresh() }
    }

    private var messageList: some View {
        List {
            ForEach(store.messages) { message in
                NavigationLink {
                    WatchMessageDetailView(message: message)
                } label: {
                    WatchMessageRow(message: message)
                }
            }
        }
        .refreshable { await store.refresh() }
        .overlay {
            if store.isRefreshing && store.messages.isEmpty {
                ProgressView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: store.iCloudReady ? "tray" : "icloud.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(store.iCloudReady ? "暂无消息" : "请在 iCloud 中登录")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("刷新") {
                Task { await store.refresh() }
            }
            .font(.footnote)
        }
        .padding()
    }
}

private struct WatchMessageRow: View {
    let message: CloudMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                if !message.read {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
                Text(message.title ?? message.body.prefixLine)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(message.createDate, style: .relative)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            if message.title != nil {
                Text(message.body)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let group = message.group, !group.isEmpty, group != "默认" {
                Text(group)
                    .font(.system(size: 9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.secondary.opacity(0.2)))
            }
        }
        .padding(.vertical, 2)
    }
}

private extension String {
    var prefixLine: String {
        components(separatedBy: .newlines).first(where: { !$0.isEmpty }) ?? self
    }
}
