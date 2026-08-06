//
//  NotificationActionsView.swift
//  NoLet
//
//  自定义通知快捷操作（UNNotificationCategory / UNNotificationAction）
//

import Defaults
import SwiftUI
import UserNotifications

struct NotificationActionsView: View {
    @Default(.customNotificationCategories) private var categories

    @State private var showAddCategory = false

    var body: some View {
        List {
            Section {
                ForEach(categories, id: \.id) { category in
                    NavigationLink {
                        NotificationCategoryDetailView(category: category)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2")
                                .frame(width: 28)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.identifier.rawValue)
                                    .font(.body.monospaced())
                                Text("\(category.actions.count) 个操作")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCategory)

                if categories.isEmpty {
                    Text("暂无自定义分类，点击右上角创建")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("自定义分类")
            } footer: {
                Text("每个分类使用唯一字母代号作为 identifier，推送时将 category 设为该代号即可。进入分类可添加内置操作或自定义操作。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle("快捷动作")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(availableIdentifiers.isEmpty)
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView { identifier in
                categories.append(NotificationCategoryModel(identifier: identifier, actions: []))
            }
        }        .onChange(of: categories) { _ in
            Identifiers.setCategories()
        }
    }

    private var availableIdentifiers: [NotificationCategoryIdentifier] {
        let used = Set(categories.map(\.identifier))
        return NotificationCategoryIdentifier.allCases.filter { !used.contains($0) }
    }

    private func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
}




