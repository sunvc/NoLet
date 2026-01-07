//
//  AddCryptoConfigView.swift
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

struct ChangeCryptoConfigView: View {
    @State private var cryptoConfig: CryptoModelConfig

    init(item: CryptoModelConfig) {
        _cryptoConfig = State(wrappedValue: item)
    }

    var expectKeyLength: Int { cryptoConfig.algorithm.rawValue }

    @FocusState private var keyFocus

    @State private var sharkText: String = ""
    @FocusState private var sharkfocused: Bool
    @State private var success: Bool = false
    @Default(.cryptoConfigs) var cryptoConfigs
    var title: String {
        return cryptoConfigs
            .contains(cryptoConfig) ? String(localized: "修改配置") : String(localized: "新增配置")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $sharkText)
                        .overlay {
                            if !success {
                                Capsule()
                                    .stroke(Color.gray, lineWidth: 2)
                            }
                        }
                        .focused($sharkfocused)
                        .overlay {
                            if sharkText.isEmpty {
                                Text("粘贴到此处,自动识别")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(10)
                        .overlay {
                            if success {
                                ColoredBorder(cornerRadius: 10, padding: 10)
                            }
                        }
                        .frame(maxHeight: 150)
                        .onChange(of: sharkfocused) { value in
                            guard !value else { return }
                            self.handler(self.sharkText)
                        }

                } header: {
                    HStack {
                        Text("导入配置")
                        PasteButton(payloadType: String.self) { strings in
                            if let str = strings.first {
                                self.sharkText = str
                                self.handler(sharkText)
                            }
                        }
                    }
                }
                Section {
                    Picker(selection: $cryptoConfig.algorithm) {
                        ForEach(CryptoAlgorithm.allCases, id: \.self) { item in
                            Text(item.name).tag(item)
                        }
                    } label: {
                        Label("算法", systemImage: cryptoConfig.algorithm.Icon)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                    }

                } header: {
                    Text("选择加密算法")
                        .textCase(.none)
                }

                Section {
                    Picker(selection: $cryptoConfig.mode) {
                        ForEach(CryptoMode.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    } label: {
                        Label("模式", systemImage: cryptoConfig.mode.Icon)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                    }
                }

                Section {
                    HStack {
                        Button {
                            Clipboard.set(cryptoConfig.key)
                            Toast.copy(title: "复制成功")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    cryptoConfig.key.count == expectKeyLength ? Color
                                        .primary : .red,
                                    cryptoConfig.key.count == expectKeyLength ? Color
                                        .accent : .red
                                )
                        }
                        Spacer()

                        TextField(
                            String(format: String(localized: "输入%d位数的key"), expectKeyLength),
                            text: Binding(get: {
                                cryptoConfig.key
                            }, set: { value in
                                cryptoConfig.key = String(value.prefix(expectKeyLength))
                            })
                        )
                        .focused($keyFocus)
                    }

                } header: {
                    HStack {
                        Text(verbatim: "KEY:")
                            .padding(.trailing, 5)
                        Spacer()
                        Text(verbatim: "\(expectKeyLength - cryptoConfig.key.count)")
                    }
                }

                Section {
                    Button {
                        if cryptoConfig.key.count != expectKeyLength {
                            Toast.error(title: "参数长度不正确")
                            return
                        }

                        if !Defaults[.cryptoConfigs].contains(where: { $0 == cryptoConfig }) {
                            var cryptoConfig = cryptoConfig
                            cryptoConfig.id = UUID().uuidString
                            Defaults[.cryptoConfigs].append(cryptoConfig)
                        }

                        AppManager.shared.open(sheet: nil)
                       
                    } label: {
                        HStack {
                            Spacer()
                            Label {
                                Text("保存")
                            } icon: {
                                Image(systemName: "externaldrive.badge.checkmark")
                                    .foregroundStyle(Color.accent, Color.primary)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 5)
                            Spacer()
                        }
                    }
                    .button26(BorderedProminentButtonStyle())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("清除") {
                        cryptoConfig.key = ""
                    }
                    Spacer()
                    Button("完成") {
                        self.hideKeyboard()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppManager.shared.open(sheet: nil)
                    } label: {
                        Label("关闭", systemImage: "xmark")
                    }.tint(.red)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        cryptoConfig.key = CryptoModelConfig.random(cryptoConfig.length)
                        Haptic.impact()
                    } label: {
                        Label("随机生成密钥", systemImage: "dice")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                            .textCase(.none)
                    }
                }
            }
        }
    }

    func handler(_ text: String) {
        let data = AppManager.shared.outParamsHandler(address: text)
        var result: String {
            switch data {
            case .text(let string): string
            case .crypto(let string): string
            default: ""
            }
        }
        if let config = CryptoModelConfig(inputText: result) {
            cryptoConfig = config
            success = true

        } else {
            success = false
            sharkText = ""
            Toast.error(title: "数据不正确")
        }
    }
}

#Preview {
    ChangeCryptoConfigView(item: CryptoModelConfig.creteNewModel())
}
