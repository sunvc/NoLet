//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - AddCategoryView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/21 21:20.
    
import SwiftUI
import Defaults

struct AddCategoryView: View {
    let onSave: (NotificationCategoryIdentifier) -> Void

    @Environment(\.dismiss) private var dismiss
    @Default(.customNotificationCategories) private var categories

    @State private var selection: NotificationCategoryIdentifier?

    var body: some View {
        NavigationStack {
            List(availableIdentifiers) { item in
                Button {
                    selection = item
                } label: {
                    HStack {
                        Text(item.rawValue)
                            .font(.body.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection == item {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .navigationTitle("选择标识")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        if let selection {
                            onSave(selection)
                        }
                        dismiss()
                    }
                    .disabled(selection == nil)
                }
            }
        }
    }

    private var availableIdentifiers: [NotificationCategoryIdentifier] {
        let used = Set(categories.map(\.identifier))
        return NotificationCategoryIdentifier.allCases.filter { !used.contains($0) }
    }
}
