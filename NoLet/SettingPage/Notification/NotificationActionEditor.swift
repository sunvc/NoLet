//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - NotificationActionEditor.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/21 21:19.
    
import SwiftUI


struct NotificationActionEditor: View {
    let action: NotificationActionModel?
    /// 当前分类已添加过的内置操作，新建时不可重复选择
    let usedBuiltInIds: Set<String>
    /// 所有分类中已占用的 action identifier，新建自定义操作时不可重复
    let usedIdentifiers: Set<String>
    let scripts: [ScriptData]
    let onSave: (NotificationActionModel) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var useBuiltIn = false
    @State private var selectedBuiltIn: Identifiers.Action?
    @State private var identifier = ""
    @State private var title = ""
    @State private var icon = ""
    @State private var iconValid = true
    @State private var scriptName: String?

    private var isEditing: Bool { action != nil }
    private var editingBuiltIn: Bool { action?.isBuiltIn == true }

    var body: some View {
        NavigationStack {
            Form {
                if isEditing && editingBuiltIn {
                    builtInPreview(action!.builtInAction!)
                } else if isEditing {
                    customFields
                } else {
                    Section {
                        Picker(selection: $useBuiltIn) {
                            Text("内置操作").tag(true)
                            Text("自定义操作").tag(false)
                        } label: {
                            Label {
                                Text("类型")
                            } icon: {
                                Image(systemName: "square.grid.2x2")
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    if useBuiltIn {
                        Section {
                            Picker(selection: $selectedBuiltIn) {
                                Text("请选择").tag(Identifiers.Action?.none)
                                ForEach(availableBuiltIns, id: \.self) { action in
                                    Label {
                                        Text(action.title)
                                    } icon: {
                                        Image(systemName: action.icon)
                                    }
                                    .tag(Identifiers.Action?.some(action))
                                }
                            } label: {
                                Text("操作")
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        } header: {
                            Text("内置操作")
                        } footer: {
                            Text(availableBuiltIns.isEmpty ? "所有内置操作均已添加。" : "选择一个系统预设操作。")
                        }
                    } else {
                        customFields
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "编辑操作" : "添加操作")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let action {
                    useBuiltIn = action.isBuiltIn
                    selectedBuiltIn = action.builtInAction
                    identifier = action.identifier
                    title = action.title
                    icon = action.icon
                    iconValid = icon.isEmpty || UIImage(systemName: icon) != nil
                    scriptName = action.scriptName
                }
            }
        }
    }

    @ViewBuilder
    private func builtInPreview(_ action: Identifiers.Action) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .frame(width: 28)
                    .foregroundStyle(.tint)
                Text(action.title)
                Spacer()
                Text("内置").font(.caption).foregroundStyle(.secondary)
            }
        } footer: {
            Text("内置操作不可编辑，仅可从分类中移除。")
        }
    }

    private var customFields: some View {
        Group {
            Section {
                TextField("例如：confirm", text: $identifier)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(isEditing)
            } header: {
                Text("标识")
            } footer: {
                Text(identifierFooter)
                    .foregroundStyle(identifierFooterColor)
            }
            Section(header: Text("标题"), footer: Text("显示在通知按钮上的文字")) {
                TextField("例如：确认", text: $title)
            }
            Section(header: Text("图标（可选）"), footer: Text(iconValid ? "SF Symbols 名称" : "该符号不存在，请检查名称")) {
                TextField("例如：checkmark", text: $icon)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: icon) { newValue in
                        iconValid = newValue.isEmpty || UIImage(systemName: newValue) != nil
                    }
                if !icon.isEmpty && iconValid {
                    HStack {
                        Spacer()
                        Image(systemName: icon)
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        Spacer()
                    }
                }
            }
            Section(header: Text("绑定脚本"), footer: Text("为该操作关联一个 action 类型的脚本（由通知扩展处理）。不选则仅打开 App。")) {
                Picker(selection: $scriptName) {
                    Text("无").tag(String?.none)
                    ForEach(scripts, id: \.id) { script in
                        Text(script.name).tag(String?.some(script.name))
                    }
                } label: {
                    Label {
                        Text("脚本")
                    } icon: {
                        Image(systemName: "applescript")
                    }
                }
                if scripts.isEmpty {
                    Text("还没有 action 类型的脚本，请到「脚本管理」中添加。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var availableBuiltIns: [Identifiers.Action] {
        Identifiers.Action.allCases.filter { !usedBuiltInIds.contains($0.rawValue) }
    }

    private var trimmedIdentifier: String {
        identifier.trimmingCharacters(in: .whitespaces)
    }

    private var identifierValid: Bool {
        guard trimmedIdentifier.range(of: #"^[A-Za-z0-9_]+$"#, options: .regularExpression) != nil else {
            return false
        }
        if let action, action.identifier == trimmedIdentifier { return true }
        return !usedIdentifiers.contains(trimmedIdentifier)
            && !Identifiers.Action.allCases.contains(where: { $0.rawValue == trimmedIdentifier })
    }

    private var identifierFooter: String {
        if trimmedIdentifier.isEmpty {
            return String(localized: "仅支持字母、数字和下划线，需全局唯一")
        }
        if trimmedIdentifier.range(of: #"^[A-Za-z0-9_]+$"#, options: .regularExpression) == nil {
            return String(localized: "仅支持字母、数字和下划线")
        }
        if !identifierValid {
            return String(localized: "该标识已被占用，请更换")
        }
        return String(localized: "通知内据此标识处理操作，创建后不可修改")
    }

    private var identifierFooterColor: Color {
        trimmedIdentifier.isEmpty || identifierValid ? .secondary : .red
    }

    private var canSave: Bool {
        if isEditing && editingBuiltIn { return false }
        if useBuiltIn {
            return selectedBuiltIn != nil
        }
        return identifierValid
            && !title.trimmingCharacters(in: .whitespaces).isEmpty
            && iconValid
    }

    private func save() {
        if useBuiltIn, let selectedBuiltIn {
            onSave(selectedBuiltIn.model)
        } else {
            onSave(NotificationActionModel(
                id: action?.id ?? .init(),
                identifier: trimmedIdentifier,
                builtInId: nil,
                title: title.trimmingCharacters(in: .whitespaces),
                icon: icon.trimmingCharacters(in: .whitespaces),
                scriptName: scriptName
            ))
        }
        dismiss()
    }
}
