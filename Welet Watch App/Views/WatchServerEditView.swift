//
//  WatchServerEditView.swift
//  Welet Watch App
//
//  服务器仅保存在手表本机,不上云。
//

import SwiftUI

struct WatchServerEditView: View {
    @EnvironmentObject private var store: WatchServerStore
    @Environment(\.dismiss) private var dismiss

    let server: PushServerModel?

    @State private var url = ""
    @State private var key = ""
    @State private var sign = ""

    private var isValid: Bool {
        guard let url = URL(string: url),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme)
        else { return false }
        return url.host != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("地址") {
                    TextField("https://…", text: $url)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                }
                Section("Key(可选)") {
                    TextField("设备 Key", text: $key)
                        .autocorrectionDisabled()
                }
                Section("签名") {
                    TextField("可选", text: $sign, axis: .vertical)
                        .lineLimit(2 ... 4)
                        .autocorrectionDisabled()
                }
                Section {
                    Text("服务器仅保存在手表本机,不会上传 iCloud")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(server == nil ? "添加服务器" : "编辑服务器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear(perform: fillIfNeeded)
    }

    private func fillIfNeeded() {
        guard let server else { return }
        url = server.url
        key = server.key
        sign = server.sign ?? ""
    }

    private func save() {
        let model = PushServerModel(
            id: server?.id ?? UUID().uuidString,
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            key: key.trimmingCharacters(in: .whitespacesAndNewlines),
            sign: sign.isEmpty ? nil : sign
        )
        store.save(model)
        dismiss()
    }
}
