//
//  ExampleView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo 2024/8/9.
//

import Defaults
import SwiftUI

struct ExampleView: View {
    @EnvironmentObject private var manager: AppManager
    @State private var username: String = ""
    @State private var title: String = ""
    @State private var pickerSelection: PushServerModel? = nil
    @State private var showAlart = false
    @Default(.servers) var servers
    @Default(.cryptoConfigs) var cryptoConfigs

    var server: String {
        (pickerSelection?.server ?? "\(NCONFIG.server)/Key") + "/"
    }

    var body: some View {
        List {
            if servers.count > 1 {
                Section {
                    HStack {
                        Spacer()

                        Picker(selection: $pickerSelection, label: Text("切换服务器")) {
                            ForEach(servers, id: \.id) { server in
                                Text(server.name)
                                    .tag(server)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            ForEach(createExample(cryptoData: cryptoConfigs.config()), id: \.id) { item in
                let resultURL = server + item.params

                Section {
                    HStack {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .padding(.trailing, 5)

                            Text(item.title)
                                .font(.headline)
                                .fontWeight(.bold)
                        }.VButton(onRelease: { _ in
                            AppManager.shared.open(sheet: .quickResponseCode(
                                text: resultURL,
                                title: item.title,
                                preview: item.title
                            ))
                            return true
                        })

                        Spacer()

                        Image(systemName: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .padding(.horizontal)
                            .VButton(onRelease: { _ in
                                UIPasteboard.general.string = resultURL
                                Toast.copy(title: "复制成功")
                                return true
                            })
                        if pickerSelection != nil {
                            Image(systemName: "safari")
                                .scaleEffect(1.3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .VButton(onRelease: { _ in
                                    if resultURL.hasHttp, let url = URL(string: resultURL) {
                                        UIApplication.shared.open(url)
                                    }
                                    return true
                                })
                        }
                    }
                    Text(verbatim: resultURL).font(.caption)

                } header: {
                    item.header
                        .textCase(.none)
                        .font(.footnote)

                } footer: {
                    VStack(alignment: .leading) {
                        item.footer
                        Divider()
                            .background(Color.blue)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("使用示例")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Section {
                    Button {
                        manager.router.append(.web(url: NCONFIG.pushHelp.url))
                        Haptic.impact()
                    } label: {
                        Label {
                            Text("使用文档")
                        } icon: {
                            Image(systemName: "questionmark.app.dashed")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.blue, Color.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let server = servers.first, pickerSelection == nil {
                pickerSelection = server
            }
        }
    }
}

extension ExampleView {
    func createExample(cryptoData: CryptoModelConfig) -> [PushExampleModel] {
        let ciphertext = CryptoManager(cryptoData).encrypt(NCONFIG.testData)?.replacingOccurrences(
            of: "+",
            with: "%2B"
        ) ?? ""

        return [
            PushExampleModel(
                header: Text("点击右上角按钮可以复制测试URL、预览推送效果"),
                footer: Text("""
                    ‼️参数可单独使用
                    * /内容 或者 /标题/内容
                    * group: 分组名，不传显示 `默认`
                    * badge： 自定义角标 可选值 -1...
                    * ttl: 消息保存时间 可选值 0...
                    """),
                title: String(localized: "基本用法示例"),
                params: String(localized: "标题/副标题/内容?group=默认&badge=1&ttl=1"),
                index: 1
            ),

            PushExampleModel(
                header: Spacer(),
                footer: Text("GET方法需要URIConponent编码"),
                title: String(localized: "Markdown样式"),
                params: "?markdown=%7C%20Name%20%20%20%7C%20Age%20%7C%20City%20%20%20%20%20%20%7C%0A%7C--------%7C-----%7C-----------%7C%0A%7C%20Alice%20%20%7C%2024%20%20%7C%20New%20York%20%20%7C%0A%7C%20Bob%20%20%20%20%7C%2030%20%20%7C%20San%20Francisco%20%7C%0A%7C%20Carol%20%20%7C%2028%20%20%7C%20London%20%20%20%20%7C%0A",
                index: 2
            ),

            PushExampleModel(
                header:
                HStack {
                    Button {
                        manager.router = [.example, .sound]
                    } label: {
                        Text("铃声列表")
                            .font(.callout)
                            .padding(.horizontal, 10)
                    }
                    Spacer()
                },
                footer: Text("可以为推送设置不同的铃声"),
                title: String(localized: "推送铃声"),
                params: "\(String(localized: "推送内容"))?sound=double",
                index: 3
            ),

            PushExampleModel(
                header:
                HStack {
                    Button {
                        manager.open(sheet: .cloudIcon)
                    } label: {
                        Text("云图标")
                            .font(.callout)
                            .padding(.horizontal, 10)
                    }

                    Text("自定义推送显示的logo")
                    Spacer()
                },
                footer: Text("支持文字图标、Emoji图标、自定义背景"),
                title: String(localized: "自定义icon"),
                params: "\(String(localized: "推送内容"))?icon=\(NCONFIG.logoImage)",
                index: 5
            ),

            PushExampleModel(
                header: Text("下拉消息会显示图片"),
                footer: Text("携带一个image,会自动下载缓存"),
                title: String(localized: "携带图片"),
                params: "?title=\(String(localized: "标题"))&body=\(String(localized: "内容"))&image=\(NCONFIG.logoImage)",
                index: 6
            ),

            PushExampleModel(
                header: Text("可对通知设置中断级别"),
                footer: Text("""
                    可选参数值:
                    - passive：仅添加到列表，不会亮屏提醒
                    - active： 默认值，系统会立即亮屏显示通知。
                    - timeSensitive:  时效性通知,专注模式下可显示通知。
                    - critical: ‼️重要提醒，静音或专注模式可正常提醒
                    * 参数可使用 0-10代替，具体查看文档
                    """),
                title: String(localized: "通知类型"),
                params: "\(String(localized: "重要提醒通知,70%音量"))?level=critical&volume=7",
                index: 7
            ),

            PushExampleModel(
                header: Text("URLScheme或者网址"),
                footer: Text("点击跳转app"),
                title: String(localized: "跳转第三方"),
                params: "\(String(localized: "推送内容"))?url=weixin://",
                index: 8
            ),

            PushExampleModel(
                header: Text("持续响铃"),
                footer: Text("通知铃声将持续播放30s，同时收到多个将按顺序依次响铃"),
                title: String(localized: "持续响铃"),
                params: "\(String(localized: "持续响铃"))?call=1",
                index: 9
            ),

            PushExampleModel(
                header:
                HStack {
                    Text("需要在")
                    Button {
                        manager.router = [.example, .crypto]
                    } label: {
                        Text("算法配置")
                            .font(.callout)
                            .padding(.horizontal, 10)
                    }
                    Text("中进行配置")
                },
                footer: Text("加密后请求需要注意特殊字符的处理"),
                title: String(localized: "端到端加密推送"),
                params: "?ciphertext=\(ciphertext)",
                index: 10
            ),
        ]
    }
}

extension NCONFIG {
    static var testData: String {
        "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"typewriter\"}"
    }
}

// MARK: - PushExampleModel

struct PushExampleModel: Identifiable {
    var id = UUID().uuidString
    var header, footer: AnyView
    var title: String
    var params: String
    var index: Int

    init<Header: View, Footer: View>(
        header: Header,
        footer: Footer,
        title: String,
        params: String,
        index: Int
    ) {
        self.header = AnyView(header)
        self.footer = AnyView(footer)
        self.title = title
        self.params = params
        self.index = index
    }
}

#Preview {
    NavigationStack {
        ExampleView()
            .environmentObject(AppManager.shared)
    }
}
