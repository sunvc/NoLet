//
//  WatchMessageDetailView.swift
//  Welet Watch App
//

import SwiftUI

struct WatchMessageDetailView: View {
    @EnvironmentObject private var store: WatchMessageStore
    let message: CloudMessage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if let title = message.title {
                    Text(title)
                        .font(.headline)
                }
                if let subtitle = message.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(message.body)
                    .font(.body)
                if let group = message.group, !group.isEmpty {
                    Label(group, systemImage: "folder")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let url = message.url, !url.isEmpty {
                    Text(url)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .lineLimit(3)
                }
                Text(message.createDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await store.markRead(message) }
        }
    }
}
