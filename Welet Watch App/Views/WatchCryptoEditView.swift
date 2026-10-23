//
//  WatchCryptoEditView.swift
//  Welet Watch App
//

import SwiftUI

struct WatchCryptoEditView: View {
    @EnvironmentObject private var store: WatchCryptoStore
    @Environment(\.dismiss) private var dismiss

    let config: WatchCryptoConfig?

    private let algorithms = [16, 24, 32]

    @State private var algorithm = 32
    @State private var key = ""

    private var keyLengthValid: Bool {
        key.utf8.count == algorithm
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("算法") {
                    Picker("算法", selection: $algorithm) {
                        ForEach(algorithms, id: \.self) { bits in
                            Text(algorithmName(bits)).tag(bits)
                        }
                    }
                    .onChange(of: algorithm) {
                        if !key.isEmpty { key = String(key.prefix(algorithm)) }
                    }
                }
                Section("KEY（\(algorithm) 字符）") {
                    TextField("密钥", text: $key)
                        .autocorrectionDisabled()
                    Button("随机生成") {
                        key = Domap.generateRandomString(algorithm)
                    }
                    .font(.caption2)
                    if !key.isEmpty && !keyLengthValid {
                        Text("需要 \(algorithm) 个字符,当前 \(key.utf8.count)")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Text("密钥仅保存在手表本机,不会上传 iCloud")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(config == nil ? "添加配置" : "编辑配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!keyLengthValid)
                }
            }
        }
        .onAppear(perform: fillIfNeeded)
    }

    private func fillIfNeeded() {
        guard let config else { return }
        algorithm = config.algorithm
        key = config.key
    }

    private func algorithmName(_ bits: Int) -> String {
        switch bits {
        case 16: "AES128"
        case 24: "AES192"
        default: "AES256"
        }
    }

    private func save() {
        let model = WatchCryptoConfig(
            id: config?.id ?? UUID().uuidString,
            algorithm: algorithm,
            mode: "GCM",
            key: key
        )
        store.save(model)
        dismiss()
    }
}
