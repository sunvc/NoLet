//
//  AddOrChangeChatAccount.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/4.
//
import Defaults
import SwiftUI

struct NoLetChatAccountDetail: View {
    
    @Binding var account: AssistantAccount?
    @EnvironmentObject var chatManager: NoLetChatManager
    @State private var data: AssistantAccount
    @Default(.assistantAccouns) var assistantAccouns
    @State private var isSecured: Bool = true
    @State private var isTestingAPI = false
    @State private var isAdd: Bool = false

    let title: String

    @State private var buttonState: AnimatedButton.buttonState = .normal

    init(account: Binding<AssistantAccount?>, isAdd: Bool = false) {
        _account = account
        self.isAdd = isAdd
        let accountData = account.wrappedValue ?? AssistantAccount.data
        _data = State(wrappedValue: accountData)

        title = isAdd
            ? String(localized: "增加新资料")
            : String(localized: "修改资料")
    }

    var body: some View {
        NavigationStack {
            List {
                Section("输入别名") {
                    baseNameField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)

                Section("请求地址(api.openai.com)") {
                    baseHostField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                Section("请求路径: /v1") {
                    basePathField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)

                Section("模型名称: (gpt-4o-mini)") {
                    baseModelField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)

                Section("请求密钥") {
                    apiKeyField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)

                Section {
                    HStack {
                        Spacer()
                        AnimatedButton(
                            state: $buttonState,
                            normal:
                            .init(
                                title: String(localized: "测试后保存"),
                                background: .blue,
                                symbolImage: "person.crop.square.filled.and.at.rectangle"
                            ),
                            success:
                            .init(
                                title: String(localized: "测试/保存成功"),
                                background: .green,
                                symbolImage: "checkmark.circle"
                            ),
                            fail:
                            .init(
                                title: String(localized: "连接失败"),
                                background: .red,
                                symbolImage: "xmark.circle"
                            ),
                            loadings: [
                                .init(title: String(localized: "测试中..."), background: .cyan),
                            ]
                        ) { view in
                            await view.next(.loading(1))

                            data.trimAssistantAccountParameters()

                            if data.key.isEmpty || data.host.isEmpty || isTestingAPI {
                                try? await Task.sleep(for: .seconds(1))
                                await view.next(.fail)
                                return
                            }

                            self.isTestingAPI = true
                            let success = await chatManager.test(account: data)

                            await view.next(success ? .success : .fail)
                            await MainActor.run {
                                self.isTestingAPI = false
                            }
                            if success {
                                await MainActor.run {
                                    self.saveOrChangeData()
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }

            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.account = nil
                    } label: {
                        Text("取消")
                    }.tint(.red)
                        .disabled(isTestingAPI)
                }

            }
            .disabled(isTestingAPI)
        }
    }

    private func saveOrChangeData() {
        data.trimAssistantAccountParameters()

        if data.host.isEmpty || data.key.isEmpty || data.model.isEmpty {
            Toast.info(title: "参数不能为空")
            return
        }

        if assistantAccouns.count == 0 {
            data.current = true
        }

        if let index = assistantAccouns.firstIndex(where: { $0.id == data.id }) {
            assistantAccouns[index] = data
            Toast.success(title: "添加成功")
            AppManager.shared.open(sheet: nil)
            return
        } else {
            if assistantAccouns
                .filter({
                    $0.host == data.host && $0.basePath == data.basePath && $0.model == data
                        .model && $0
                        .key == data.key }).count > 0
            {
                Toast.error(title: "重复数据")
                return
            }

            assistantAccouns.insert(data, at: 0)
            Toast.success(title: "修改成功")
            AppManager.shared.open(sheet: nil)
        }
    }

    private var apiKeyField: some View {
        HStack {
            Group {
                if isSecured {
                    SecureField(String("API Key"), text: $data.key)
                        .textContentType(.password)
                } else {
                    TextField(String("API Key"), text: $data.key)
                        .textContentType(.none)
                }
            }
            .autocapitalization(.none)
            .customField(icon: "key.icloud") {
                if let text = Clipboard.getText(), !text.isEmpty {
                    self.data.key = text
                }
            }

            Image(systemName: isSecured ? "eye.slash" : "eye")
                .foregroundColor(isSecured ? .gray : .primary)
                .onTapGesture {
                    isSecured.toggle()
                    Haptic.impact()
                }
        }
    }

    private var baseNameField: some View {
        TextField(String("Name"), text: $data.name)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(icon: "atom") {
                if let text = Clipboard.getText(), !text.isEmpty {
                    self.data.name = text
                }
            }
    }

    private var baseHostField: some View {
        TextField(String("Host"), text: $data.host)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(icon: "network") {
                if let text = Clipboard.getText(), !text.isEmpty {
                    let (host, path) = parseAPI(from: text)
                    self.data.host = host
                    if let path = path, !path.isEmpty {
                        self.data.basePath = path
                    }
                }
            }
    }

    private var basePathField: some View {
        TextField(String("BasePath"), text: $data.basePath)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "point.filled.topleft.down.curvedto.point.bottomright.up"
            ) {
                if let text = Clipboard.getText(), !text.isEmpty {
                    self.data.basePath = text
                }
            }
    }

    private var baseModelField: some View {
        TextField(String("Model"), text: $data.model)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(icon: "slider.horizontal.2.square.badge.arrow.down") {
                if let text = Clipboard.getText() {
                    self.data.model = text
                }
            }
    }

    func parseAPI(from input: String) -> (host: String, basePath: String?) {
        // 自动补全 scheme
        let normalizedInput: String
        if input.contains("://") {
            normalizedInput = input
        } else {
            normalizedInput = "https://" + input
        }

        guard let url = URL(string: normalizedInput), let host = url.host else {
            return (input, nil)
        }

        let path = url.path

        // 必须有有效 path
        guard !path.isEmpty, path != "/" else {
            return (input, nil)
        }

        let marker = "/chat/completions"

        let basePath: String
        if let range = path.range(of: marker) {
            basePath = String(path[..<range.lowerBound])
        } else {
            basePath = path
        }

        return (host, basePath)
    }
}
