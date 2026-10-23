//
//  WatchServerListView.swift
//  Welet Watch App
//
//  服务器仅本机保存,不上云。
//

import SwiftUI

struct WatchServerListView: View {
    @EnvironmentObject private var store: WatchServerStore
    @State private var editing: PushServerModel?
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.servers) { server in
                    Button {
                        editing = server
                    } label: {
                        WatchServerRow(server: server)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            store.remove(server)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .navigationTitle("服务器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                WatchServerEditView(server: nil)
            }
            .sheet(item: $editing) { server in
                WatchServerEditView(server: server)
            }
        }
    }
}

private struct WatchServerRow: View {
    let server: PushServerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(server.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if server.sign != nil {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                }
            }
            if !server.key.isEmpty {
                Text(String(server.key.suffix(8)))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
