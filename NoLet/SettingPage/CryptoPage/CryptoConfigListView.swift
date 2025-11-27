//
//  CryptoConfigListView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/8/3.
//

import Defaults
import SwiftUI

struct CryptoConfigListView: View {
    @Default(.cryptoConfigs) var cryptoConfigs
    @State private var showAddView: Bool = false
    @EnvironmentObject private var manager: AppManager

    var body: some View {
        List {
            Section {
                ForEach(cryptoConfigs.indices, id: \.self) { index in
                    cryptoConfigCard(item: cryptoConfigs[index], index: index)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                }
            } header: {
                HStack {
                    Text("算法列表")
                    Spacer()
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("算法配置")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    cryptoConfigs.append(CryptoModelConfig.creteNewModel())
                    Haptic.impact()
                } label: {
                    Label("新增配置", systemImage: "plus.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.router.append(.web(url: NCONFIG.encryURL.url))
                    Haptic.impact()
                } label: {
                    Label {
                        Text("查看文档")
                    } icon: {
                        Image(systemName: "questionmark.app.dashed")
                    }
                }
            }
        }
    }

    @ViewBuilder
    func cryptoConfigCard(item: CryptoModelConfig, index: Int) -> some View {
        HStack(spacing: 20) {
            VStack {
                Text(String(format: "%02d", index))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.shield")
                        .foregroundStyle(.blue)
                    Text(verbatim: "-")
                    Text(verbatim: item.algorithm.name)
                    Text(verbatim: "-")
                    Text(verbatim: item.mode.rawValue)
                    Spacer(minLength: 0)
                }.lineLimit(1)
                Divider()
                HStack(spacing: 10) {
                    Text(verbatim: "KEY:")
                        .foregroundStyle(.gray)
                        .padding(.trailing, 5)
                    Text(maskString(item.key))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                    Spacer(minLength: 0)
                }
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            Menu {
                Section {
                    Button {
                        AppManager.shared.sheetPage = .crypto(item)
                    } label: {
                        Label("编辑", systemImage: "highlighter")
                    }.tint(.green)
                }

                if let config = item.obfuscator() {
                    Section {
                        Button {
                            let local = PBScheme.pb.scheme(host: .crypto, params: ["text": config])
                            Task { @MainActor in
                                AppManager.shared.sheetPage = .quickResponseCode(
                                    text: local.absoluteString,
                                    title: String(localized: "配置文件"),
                                    preview: String(localized: "分享配置")
                                )
                            }
                        } label: {
                            Label("分享", systemImage: "qrcode")
                        }
                        .tint(.orange)
                    }
                }
                Section {
                    Button {
                        Clipboard.set(item.key)
                        Toast.copy(title: "复制成功")
                    } label: {
                        Label("复制KEY", systemImage: "doc.on.doc")
                            .customForegroundStyle(.accent, .primary)
                    }
                }
                Section {
                    Button {
                        let data = cryptoExampleHandler(config: item, index: index)
                        Clipboard.set(data)
                        Toast.copy(title: "复制成功")
                    } label: {
                        Label("复制Python示例", systemImage: "doc.on.doc")
                    }.tint(.green)
                }

            } label: {
                Image(systemName: "menucard")
                    .imageScale(.large)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
        }
        .padding(10)
        .background26(.message, radius: 15)
        .swipeActions {
            Button(role: .destructive) {
                self.cryptoConfigs.removeAll(where: { $0.id == item.id })
                if self.cryptoConfigs.count == 0 {
                    self.cryptoConfigs.append(CryptoModelConfig.creteNewModel())
                }

            } label: {
                Label("删除", systemImage: "trash")
            }.tint(.red)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                localized: "\(String(format: "%02d", index))号密钥"
            ) + item.algorithm.name + item.mode.rawValue
        )
        .accessibilityAction(named: "分享配置") {
            if let config = item.obfuscator() {
                let local = PBScheme.pb.scheme(host: .crypto, params: ["text": config])
                DispatchQueue.main.async {
                    AppManager.shared.sheetPage = .quickResponseCode(
                        text: local.absoluteString,
                        title: String(localized: "配置文件"),
                        preview: String(localized: "分享配置")
                    )
                }
            }
        }
        .accessibilityAction(named: "编辑") {
            AppManager.shared.sheetPage = .crypto(item)
        }
        .accessibilityAction(named: "复制") {
            let data = cryptoExampleHandler(config: item, index: index)
            Clipboard.set(data)
            Toast.copy(title: "复制成功")
        }
    }

    func cryptoExampleHandler(config: CryptoModelConfig, index: Int) -> String {
        let server = Defaults[.servers][0]

        let tips = CryptoAlgorithm.allCases.compactMap { item in
            "\(item.name)-\(Int(item.name.suffix(3))! / 8)"
        }.joined(separator: " | ")

        return """
            # Documentation: \(NCONFIG.encryURL)
            # python demo: \(String(localized: "使用AES加密数据，并发送到服务器"))
            # pip3 install pycryptodome

            import os
            import json
            import base64
            import requests
            from Crypto.Cipher import AES


            # \(String(localized: "JSON数据"))
            json_example = json.dumps(\(NCONFIG.testData))

            # \(String(localized: "KEY长度:")) \(tips)
            key = b"\(config.key)"
            # \(String(localized: "IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。"))
            nonce = os.urandom(12)

            # \(String(localized: "加密"))
            cipher = AES.new(key, AES.MODE_GCM, nonce)
            padded_data = json_example.encode()
            encrypted_data, tag = cipher.encrypt_and_digest(padded_data)
            encrypted_data =  nonce + encrypted_data + tag

            # \(String(localized: "将加密后的数据转换为Base64编码"))
            encrypted_base64 = base64.b64encode(encrypted_data).decode()

            print("\(String(localized: "加密后的数据（Base64编码"))", encrypted_base64)


            res = requests.get("\(server.url)/\(server
            .key)/test", params = {"ciphertext": encrypted_base64, "cipherNumber":\(index)})

            print(res.text)
            """
    }

    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) + str }
        return str.prefix(3) + String(repeating: "*", count: 3) + str.suffix(5)
    }
}
