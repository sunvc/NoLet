//
//  SelectMessageView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/2.
//
import Defaults
import Kingfisher
import OpenAI
import SwiftUI

enum SelectMessageViewMode: Int, Equatable {
    case translate
    case abstract
    case raw
}

struct SelectMessageView: View {
    var message: Message
    var dismiss: () -> Void
    @StateObject private var chatManager = openChatManager.shared
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.translateLang) var translateLang

    @State private var scaleFactor: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0

    // 设定基础字体大小
    @ScaledMetric(relativeTo: .body) var baseTitleSize: CGFloat = 17
    @ScaledMetric(relativeTo: .subheadline) var baseSubtitleSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) var basedateSize: CGFloat = 13

    @StateObject private var manager = AppManager.shared

    @State private var isDismiss: Bool = false
    @State private var messageShowMode: SelectMessageViewMode = .raw
    @State private var translateResult: String = ""

    @State private var abstractResult: String = ""

    @State private var showAssistantSetting: Bool = false

    @State private var showOther: Bool = false
    @State private var showURL: Bool = false

    @State private var cancels: CancellableRequest? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack {
                        if let image = message.image {
                            AsyncPhotoView(url: image)
                                .contextMenu {
                                    Button {
                                        Task {
                                            if let file = await ImageManager.downloadImage(image),
                                               let uiimage = UIImage(contentsOfFile: file)
                                            {
                                                uiimage
                                                    .bat_save(intoAlbum: nil) { success, status in
                                                        if status == .authorized || status ==
                                                            .limited
                                                        {
                                                            if success {
                                                                Toast.success(title: "保存成功")
                                                            } else {
                                                                Toast.question(title: "保存失败")
                                                            }
                                                        } else {
                                                            Toast.error(title: "没有相册权限")
                                                        }
                                                    }
                                            }
                                        }
                                    } label: {
                                        Label(
                                            "保存图片",
                                            systemImage: "square.and.arrow.down.on.square"
                                        )
                                    }
                                }
                        }
                    }
                    .padding(.top, UIApplication.shared.topSafeAreaHeight)
                    .zIndex(1)

                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(message.createDate.formatString())

                                if let host = message.host {
                                    Text(host.removeHTTPPrefix())
                                }
                            }
                            .font(.system(size: basedateSize * scaleFactor))

                            Spacer()
                        }
                        .padding(.vertical)

                        if messageShowMode == .abstract {
                            VStack {
                                if abstractResult.isEmpty {
                                    Label("正在处理中...", systemImage: "rays")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
                                        .symbolEffect(.rotate)
                                } else {
                                    MarkdownCustomView(
                                        content: abstractResult,
                                        searchText: "",
                                        scaleFactor: scaleFactor
                                    )
                                    .font(.body)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay {
                                ColoredBorder(cornerRadius: 15)
                            }
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    Clipboard.set(abstractResult)
                                    Toast.copy()
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .padding(.trailing)
                                        .offset(x: 0, y: -10)
                                }
                            }
                        }

                        if messageShowMode == .translate {
                            VStack {
                                if translateResult.isEmpty {
                                    Label("正在处理中...", systemImage: "rays")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
                                        .symbolEffect(.rotate)
                                } else {
                                    MarkdownCustomView(
                                        content: translateResult,
                                        searchText: "",
                                        scaleFactor: scaleFactor
                                    )
                                    .font(.body)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 5)
                                }
                            }.overlay(alignment: .topTrailing) {
                                Button {
                                    Clipboard.set(translateResult)
                                    Toast.copy()
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .padding(.trailing)
                                        .offset(x: 0, y: -10)
                                }
                            }

                        } else {
                            if let title = message.title {
                                HStack {
                                    Spacer(minLength: 0)
                                    Text(title)
                                        .font(.system(size: baseTitleSize * scaleFactor))
                                        .fontWeight(.bold)
                                        .textSelection(.enabled)
                                    Spacer(minLength: 0)
                                }
                            }

                            if let subtitle = message.subtitle {
                                HStack {
                                    Spacer(minLength: 0)
                                    Text(subtitle)
                                        .font(.system(size: baseSubtitleSize * scaleFactor))
                                        .fontWeight(.bold)
                                        .textSelection(.enabled)
                                    Spacer(minLength: 0)
                                }
                            }

                            Line()
                                .stroke(
                                    .gray,
                                    style: StrokeStyle(
                                        lineWidth: 1,
                                        lineCap: .butt,
                                        lineJoin: .miter,
                                        dash: [5, 3]
                                    )
                                )
                                .padding(.horizontal, 3)

                            if let body = message.body, !body.isEmpty {
                                HStack {
                                    MarkdownCustomView(
                                        content: body,
                                        searchText: "",
                                        scaleFactor: scaleFactor
                                    )
                                    Spacer(minLength: 0)
                                }
                            }

                            if message.url != nil || message.image != nil {
                                Divider().padding(.top, 10)

                                DisclosureGroup(String("URL"), isExpanded: $showURL) {
                                    if let url = message.url {
                                        URLParamsView(url: url)
                                    }

                                    if let url = message.image {
                                        URLParamsView(url: url)
                                    }
                                }
                            }

                            if let other = message.other, !other.isEmpty {
                                Divider()
                                    .padding(.top, 10)
                                DisclosureGroup("其他字段", isExpanded: $showOther) {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Button {
                                                Clipboard.set(other)
                                            } label: {
                                                Image(systemName: "doc.on.clipboard")
                                            }
                                        }

                                        HStack {
                                            MarkdownCustomView(
                                                content: other,
                                                searchText: "",
                                                scaleFactor: scaleFactor
                                            )
                                            .textSelection(.enabled)
                                            Spacer(minLength: 0)
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.gray.opacity(0.1))
                                    )
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScaleValue
                                lastScaleValue = value
                                scaleFactor *= delta
                                scaleFactor = min(max(scaleFactor, 1.0), 3.0) // 限制最小/最大缩放倍数
                            }
                            .onEnded { _ in
                                lastScaleValue = 1.0
                            }
                    )
                }
                .frame(width: windowWidth)
                .padding(.top, 30)
                .padding(.bottom, 150)
                .onChange(of: translateLang) { _ in
                    self.translateResult = ""
                    self.abstractResult = ""
                    self.messageShowMode = .raw
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("选择翻译语言", selection: $translateLang) {
                        ForEach(Multilingual.commonLanguages, id: \.id) { country in
                            Text(verbatim: "\(country.flag)  \(country.name)")
                                .tag(country)
                        }
                    }
                    .pickerStyle(.menu)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            self.dismiss()
                        }
                        Haptic.impact(.light)
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Menu {
                        Section {
                            if let other = message.other, !other.isEmpty {
                                Button {
                                    Clipboard.set(other)
                                    Toast.copy(title: "复制成功")
                                    Haptic.impact()
                                } label: {
                                    Label("复制其他字段", systemImage: "doc.on.doc")
                                        .customForegroundStyle(.green, .primary)
                                    
                                }
                            }
                        }

                        Section {
                            if let image = message.image, !image.isEmpty {
                                Button {
                                    Clipboard.set(image)
                                    Toast.copy(title: "复制成功")
                                    Haptic.impact()
                                } label: {
                                    Label("复制图片地址", systemImage: "doc.on.doc")
                                        .customForegroundStyle(.green, .primary)
                                }
                            }
                        }

                        Section {
                            if let url = message.url, !url.isEmpty {
                                Button {
                                    Clipboard.set(url)
                                    Toast.copy(title: "复制成功")
                                    Haptic.impact()
                                } label: {
                                    Label("复制跳转地址", systemImage: "doc.on.doc")
                                        .customForegroundStyle(.green, .primary)
                                }
                            }
                        }

                        Section {
                            if let content = message.title, !content.isEmpty {
                                Button {
                                    Clipboard.set(content)
                                    Toast.copy(title: "复制成功")
                                    Haptic.impact()
                                } label: {
                                    Label("复制标题", systemImage: "doc.on.doc")
                                        .customForegroundStyle(.green, .primary)
                                }
                            }
                        }
                        Section {
                            if let content = message.subtitle, !content.isEmpty {
                                Button {
                                    Clipboard.set(content)
                                    Toast.copy(title: "复制成功")
                                    Haptic.impact()
                                } label: {
                                    Label("复制副标题", systemImage: "doc.on.doc")
                                        .customForegroundStyle(.green, .primary)
                                }
                            }
                        }
                        
                        
                        Section{
                            if let image = message.image{
                                Button {
                                    Task {
                                        if let file = await ImageManager.downloadImage(image),
                                           let uiimage = UIImage(contentsOfFile: file)
                                        {
                                            uiimage
                                                .bat_save(intoAlbum: nil) { success, status in
                                                    if status == .authorized || status ==
                                                        .limited
                                                    {
                                                        if success {
                                                            Toast.success(title: "保存成功")
                                                        } else {
                                                            Toast.question(title: "保存失败")
                                                        }
                                                    } else {
                                                        Toast.error(title: "没有相册权限")
                                                    }
                                                }
                                        }
                                    }
                                } label: {
                                    Label(
                                        "保存图片",
                                        systemImage: "square.and.arrow.down.on.square"
                                    )
                                    .customForegroundStyle(.green, .primary)
                                }
                            }
                        }

                        Section {
                            if let content = message.body, !content.isEmpty {
                                Button {
                                    Clipboard.set(content)
                                    Toast.copy(title: "复制成功")
                                    Haptic.impact()
                                } label: {
                                    Label("复制内容", systemImage: "doc.on.doc")
                                        .customForegroundStyle(.green, .primary)
                                }
                            }
                        }

                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .foregroundColor(.primary)
                    }
                }

                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        if messageShowMode == .translate {
                            self.messageShowMode = .raw
                        } else {
                            self.messageShowMode = .translate
                            translateMessage()
                        }
                        Haptic.impact()

                    } label: {
                        HStack {
                            if #available(iOS 17.4, *) {
                                Image(systemName: messageShowMode == .translate ? "eye.slash" :
                                    "translate")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.accentColor, Color.primary)

                            } else {
                                Image(systemName: messageShowMode == .translate ? "eye.slash" :
                                    "globe.europe.africa")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.accentColor, Color.primary)
                            }

                            Text(messageShowMode == .translate ? "隐藏" : "翻译")
                        }
                        .contentShape(Rectangle())
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        if self.messageShowMode == .abstract {
                            self.messageShowMode = .raw
                        } else {
                            self.messageShowMode = .abstract
                            abstractMessage(message.search.trimmingSpaceAndNewLines)
                        }
                        Haptic.impact()
                    } label: {
                        HStack {
                            Image(systemName: messageShowMode == .abstract ? "eye.slash" :
                                "doc.text.magnifyingglass")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                            Text(messageShowMode == .abstract ? "隐藏" : "总结")
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background26(.background, radius: 0)
            .animation(.spring(), value: messageShowMode)
            .onAppear { self.hideKeyboard() }
            .onDisappear { chatManager.cancellableRequest?.cancelRequest() }
            .sheet(isPresented: $showAssistantSetting) {
                NavigationStack {
                    AssistantSettingsView()
                }
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    func URLParamsView(url: String) -> some View {
        Group {
            VStack(spacing: 1) {
                VStack {
                    HStack(spacing: 30) {
                        Spacer()

                        Button {
                            Clipboard.set(url)
                            Toast.copy()
                            Haptic.impact()
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                        }
                    }

                    let urlText = NSAttributedString(string: "\n\(url)", attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: Color.yellow,
                        .link: url,
                    ])

                    TextView(text: urlText)

//                    MarkdownCustomView.highlightedText(searchText: "", text: url)
//                        .font(.system(size: baseSubtitleSize * scaleFactor))
//                        .fontWeight(.bold)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .textSelection(.enabled)
//                        .onTapGesture {
//                            if let fileURL = URL(string: url) {
//                                AppManager.openURL(url: fileURL, .safari)
//                            }
//                            Haptic.impact()
//                        }
                }
            }
            .foregroundStyle(.accent)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.1))
            )

            Divider()
        }
    }

    private func translateMessage() {
        cancels?.cancelRequest()

        guard translateResult.isEmpty else { return }

        var datas = ""

        if let title = message.title, !title.isEmpty {
            datas += "\(title) <br>"
        }

        if let subtitle = message.subtitle, !subtitle.isEmpty {
            datas += "\(subtitle) <br>"
        }

        if let body = message.body, !body.isEmpty {
            datas += "\(body)"
        }

        guard assistantAccouns.first(where: { $0.current }) != nil else {
            Toast.error(title: "需要配置大模型")
            translateResult = String(localized: "❗️需要配置大模型")

            return
        }

        cancels = chatManager
            .chatsStream(text: datas, tips: .translate(translateLang.name)) { partialResult in
                switch partialResult {
                case .success(let result):
                    if let res = result.choices.first?.delta.content {
                        DispatchQueue.main.async {
                            self.translateResult += res
                            Haptic.selection(limitFrequency: true)
                        }
                    }
                case .failure(let error):
                    // Handle chunk error here
                    NLog.error(error)
                    Toast.error(title: "发生错误\(error.localizedDescription)")
                }

            } completion: { err in
                if err != nil {
                    DispatchQueue.main.async {
                        translateResult = ""
                    }
                }
            }
    }

    private func abstractMessage(_ text: String) {
        cancels?.cancelRequest()
        guard abstractResult.isEmpty else { return }

        guard assistantAccouns.first(where: { $0.current }) != nil else {
            Toast.error(title: "需要配置大模型")
            abstractResult = String(localized: "❗️需要配置大模型")
            return
        }

        cancels = chatManager
            .chatsStream(text: text, tips: .abstract(translateLang.name)) { partialResult in
                switch partialResult {
                case .success(let result):
                    if let res = result.choices.first?.delta.content {
                        DispatchQueue.main.async {
                            abstractResult += res
                            Haptic.selection(limitFrequency: true)
                        }
                    }
                case .failure(let error):
                    // Handle chunk error here
                    NLog.error(error)
                    Toast.error(title: "发生错误\(error.localizedDescription)")
                }

            } completion: { err in
                if err != nil {
                    DispatchQueue.main.async {
                        abstractResult = ""
                    }
                }
            }
    }
}

#Preview {
    SelectMessageView(message: Message(
        id: UUID().uuidString,
        group: "",
        createDate: .now,
        title: "123",
        subtitle: "123",
        body: """
            # 123

            ### 1231231231
            """,
        icon: nil,
        url: nil,
        image: "https://s3.wzs.app/og.png",
        from: nil,
        host: nil,
        level: 1,
        ttl: 7,
        read: true,
        other: ""
    )) {}
}
