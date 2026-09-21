//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptMarketUploadView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: 插件中心上传表单：选本地脚本 → 填名称/简介/标签 → 校验后传公共库

//  History:
//    Created by Neo on 2026/9/9.

import Defaults
import SwiftUI

struct ScriptMarketUploadView: View {
    var onUploaded: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Default(.scripts) private var scripts

    @State private var selectedID = ""
    @State private var name = ""
    @State private var summary = ""
    @State private var tags: [TagModel] = []

    private var selected: ScriptData? {
        scripts.first { $0.id == selectedID }
    }

    private var tagValues: [String] {
        tags.compactMap {
            let v = $0.value.trimmingCharacters(in: .whitespaces)
            return v.isEmpty ? nil : v
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                formContent
            }
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .navigationTitle("上传脚本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                uploadButton
            }
            .onAppear {
                if selectedID.isEmpty, let first = sortedScripts.first {
                    selectedID = first.id
                    name = defaultName(first)
                }
            }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        if scripts.isEmpty {
            Section {
                Text("本地还没有脚本，先在脚本列表中新建一个。")
                    .foregroundStyle(.secondary)
            }
        } else {
            scriptSection
            nameSection
            summarySection
            tagsSection
        }
    }

    private var scriptSection: some View {
        Section("选择本地脚本") {
            Picker(selection: $selectedID) {
                Text("请选择").tag("")
                ForEach(sortedScripts, id: \.id) { script in
                    Label {
                        Text("\(script.name)（\(script.mode.title)）")
                    } icon: {
                        Image(systemName: script.mode.symbol)
                    }
                    .tag(script.id)
                }
            } label: {
                Text("脚本")
            }
            .onChange(of: selectedID) { _ in
                if name.isEmpty, let selected {
                    name = defaultName(selected)
                }
            }
        }
    }

    private var nameSection: some View {
        Section("名称") {
            TextField("例如：企业微信告警转发", text: $name)
        }
    }

    private var summarySection: some View {
        Section(
            header: Text("简介"),
            footer: Text("一句话说明这个脚本做什么，会展示在插件中心列表。")
        ) {
            TextField("脚本用途简介", text: $summary, axis: .vertical)
                .lineLimit(2 ... 4)
        }
    }

    private var tagsSection: some View {
        Section(
            header: Text("标签"),
            footer: Text("输入标签后按逗号分隔，便于其他用户搜索。")
        ) {
            TagField(tags: $tags)
        }
    }

    private var uploadButton: some View {
        AnimatedButton(
            normal: .init(title: "上传到云端", symbolImage: "icloud.and.arrow.up")
        ) { handler in
            guard let selected else {
                Toast.info(title: "请选择要上传的脚本")
                return
            }
            let displayName = name.trimmingCharacters(in: .whitespaces)
            guard !displayName.isEmpty else {
                Toast.info(title: "请填写名称")
                return
            }
            await handler.loading(title: "校验并上传")
            do {
                try await ScriptMarketManager.shared.upload(
                    local: selected,
                    displayName: displayName,
                    summary: summary.trimmingCharacters(in: .whitespaces),
                    tags: tagValues
                )
                await handler.succeed(symbolImage: "icloud.and.arrow.up.fill")
                onUploaded()
                dismiss()
            } catch {
                await handler.fail()
                logger.error("\(error.localizedDescription)")
                Toast.shared.present(title: error.localizedDescription, symbol: .error)
            }
        }
        .disabled(scripts.isEmpty)
        .padding()
    }

    private var sortedScripts: [ScriptData] {
        scripts.sorted { $0.createDate > $1.createDate }
    }

    private func defaultName(_ script: ScriptData) -> String {
        script.name.hasSuffix(".js")
            ? String(script.name.dropLast(3))
            : script.name
    }
}
