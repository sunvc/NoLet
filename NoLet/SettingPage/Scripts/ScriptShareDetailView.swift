//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptShareDetailView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 插件中心脚本详情：查看元信息/源码，确认后安装；作者可删除

//  History:
//    Created by Neo on 2026/9/9.

import Defaults
import SwiftUI

struct ScriptShareDetailView: View {
    /// 列表带来的元信息（不含源码）
    let share: ScriptShare
    /// 「我的上传」进入时允许删除
    var allowDelete: Bool = false
    /// 删除成功后的回调（用于列表即时移除）
    var onDeleted: (() -> Void)? = nil

    @Default(.scripts) private var scripts
    @Environment(\.dismiss) private var dismiss

    @State private var full: ScriptShare?
    @State private var loading = true
    @State private var loadError: String?
    @State private var installing = false
    @State private var showDeleteConfirm = false
    @State private var deleting = false

    private var mode: ScriptData.Mode? { ScriptData.Mode(rawValue: share.mode) }
    private var installed: Bool { scripts.contains { $0.id == share.sha256 } }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    private var tempFile: URL? {
        guard let full, let source = full.source else { return nil }
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("script-market", isDirectory: true)
            .appendingPathComponent(full.id, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var fileName = share.name
        if !fileName.hasSuffix(".js") { fileName += ".js" }
        let url = dir.appendingPathComponent(fileName)
        try? source.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(share.name, systemImage: mode?.symbol ?? "applescript")
                        .font(.headline)
                    if !share.summary.isEmpty {
                        Text(share.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section("信息") {
                row("类型", mode?.title ?? share.mode)
                row("作者", share.authorName.isEmpty ? String(localized: "匿名用户") : share.authorName)
                if let date = share.createdAt {
                    row("发布时间", date.formatted(date: .abbreviated, time: .omitted))
                }
                row("大小", Self.byteFormatter.string(fromByteCount: Int64(share.size)))
                row("SHA256", String(share.sha256.prefix(8)))
                if !share.tags.isEmpty {
                    row("标签", share.tags.joined(separator: ", "))
                }
            }
            Section {
                if loading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let loadError {
                    Text(loadError).foregroundStyle(.red).font(.footnote)
                } else if let tempFile {
                    NavigationLink {
                        ScriptPreview(file: tempFile, readOnly: true)
                    } label: {
                        Label("查看完整源码", systemImage: "doc.text.magnifyingglass")
                    }
                }
            } footer: {
                Text("脚本来自其他用户，运行时具备网络请求等能力。安装前请务必查看源码确认安全。")
            }
            if allowDelete {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            if deleting { ProgressView() } else { Text("删除云端脚本") }
                            Spacer()
                        }
                    }
                    .disabled(deleting)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle("脚本详情")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            installBar
        }
        .task {
            await loadDetail()
        }
        .alert("确认删除云端脚本？", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { Task { await deleteShare() } }
        } message: {
            Text("删除后其他用户将无法在插件中心看到它，已安装的用户不受影响。")
        }
    }

    @ViewBuilder
    private var installBar: some View {
        HStack {
            Button {
                Task { await install() }
            } label: {
                HStack {
                    Spacer()
                    if installing {
                        ProgressView().tint(.white)
                    } else {
                        Label(installed ? "已安装" : "安装到我的脚本",
                              systemImage: installed ? "checkmark.circle.fill" : "square.and.arrow.down")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading || loadError != nil || installing || installed)
        }
        .padding()
        .background(.bar)
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }

    private func loadDetail() async {
        loading = true
        do {
            full = try await ScriptMarketManager.shared.detail(id: share.id)
        } catch {
            loadError = error.localizedDescription
        }
        loading = false
    }

    private func install() async {
        guard let full else { return }
        installing = true
        do {
            try await ScriptMarketManager.shared.install(full)
            Toast.shared.present(title: String(localized: "安装成功"), symbol: .success)
        } catch {
            Toast.shared.present(title: error.localizedDescription, symbol: .error)
        }
        installing = false
    }

    private func deleteShare() async {
        deleting = true
        do {
            try await ScriptMarketManager.shared.delete(share)
            Toast.shared.present(title: String(localized: "已删除"), symbol: .success)
            onDeleted?()
            dismiss()
        } catch {
            Toast.shared.present(title: error.localizedDescription, symbol: .error)
            deleting = false
        }
    }
}
