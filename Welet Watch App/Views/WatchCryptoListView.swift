//
//  WatchCryptoListView.swift
//  Welet Watch App
//
//  加密配置仅本机保存,不上云。
//

import SwiftUI

struct WatchCryptoListView: View {
    @EnvironmentObject private var store: WatchCryptoStore
    @State private var editing: WatchCryptoConfig?
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(store.configs.enumerated()), id: \.element.id) { index, config in
                    Button {
                        editing = config
                    } label: {
                        WatchCryptoRow(index: index, config: config)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            store.remove(config)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .navigationTitle("加密")
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
            .sheet(item: $editing) { config in
                WatchCryptoEditView(config: config)
            }
            .sheet(isPresented: $showAdd) {
                WatchCryptoEditView(config: nil)
            }
        }
    }
}

private struct WatchCryptoRow: View {
    let index: Int
    let config: WatchCryptoConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(index + 1). \(algorithmName) · \(config.mode)")
                .font(.caption.weight(.semibold))
            Text(maskedKey)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 2)
    }

    /// 前面全部打码,仅显示最后 5 位。
    private var maskedKey: String {
        let visibleCount = min(5, config.key.count)
        let maskedCount = config.key.count - visibleCount
        return String(repeating: "*", count: maskedCount) + String(config.key.suffix(visibleCount))
    }

    private var algorithmName: String {
        switch config.algorithm {
        case 16: "AES128"
        case 24: "AES192"
        case 32: "AES256"
        default: "AES?"
        }
    }
}
