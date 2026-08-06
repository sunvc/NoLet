//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - NotificationCategoryDetailView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/21 21:19.
    
import Defaults
import SwiftUI

struct NotificationCategoryDetailView: View {
    let category: NotificationCategoryModel

    @Default(.scripts) private var scripts
    @Default(.customNotificationCategories) private var categories

    @State private var editing: NotificationActionModel?
    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                if category.actions.isEmpty {
                    Text("暂无操作，点击右上角添加")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(category.actions) { item in
                    Button {
                        if !item.isBuiltIn {
                            editing = item
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.displayIcon.isEmpty ? "app" : item.displayIcon)
                                .frame(width: 28)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayTitle)
                                HStack(spacing: 6) {
                                    Text(item.identifier).font(.caption).monospaced()
                                    Text("·").font(.caption)
                                    Text(item.isBuiltIn ? "内置" : "自定义")
                                        .font(.caption)
                                    if let scriptName = item.scriptName {
                                        Text("·").font(.caption)
                                        Label(scriptName, systemImage: "applescript").font(.caption)
                                    }
                                }
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !item.isBuiltIn {
                                Image(systemName: "pencil").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete(perform: delete)
            } header: {
                Text("操作")
            } footer: {
                Text("按此顺序显示在通知横幅上。内置操作为系统预设，自定义操作可绑定 action 类型脚本。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle(category.identifier.rawValue)
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
            NotificationActionEditor(
                action: nil,
                usedBuiltInIds: Set(category.actions.compactMap(\.builtInId)),
                usedIdentifiers: allActionIdentifiers,
                scripts: actionScripts
            ) { saved in
                update { $0.actions.append(saved) }
            }
        }
        .sheet(item: $editing) { item in
            NotificationActionEditor(
                action: item,
                usedBuiltInIds: [],
                usedIdentifiers: allActionIdentifiers,
                scripts: actionScripts
            ) { saved in
                update { model in
                    if let index = model.actions.firstIndex(where: { $0.id == item.id }) {
                        model.actions[index] = saved
                    }
                }
            }
        }
    }

    private var actionScripts: [ScriptData] {
        scripts.filter { $0.mode == .action }.sorted { $0.createDate > $1.createDate }
    }

    private var allActionIdentifiers: Set<String> {
        Set(categories.flatMap { $0.actions.map(\.identifier) })
    }

    private func update(_ mutate: (inout NotificationCategoryModel) -> Void) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        mutate(&categories[index])
    }

    private func delete(at offsets: IndexSet) {
        update { $0.actions.remove(atOffsets: offsets) }
    }
}
