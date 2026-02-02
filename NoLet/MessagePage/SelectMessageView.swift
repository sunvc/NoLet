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
import MarkdownUI
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
    @StateObject private var chatManager = NoLetChatManager.shared
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
    @State private var showCopy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack {
                        if let image = message.image {
                            AsyncPhotoView(url: image)
                                .contextMenu {
                                    saveToAlbumButton(albumName: nil, imageURL: image, image: nil)
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
                                    HStack {
                                        Spacer()
                                        Spinner(tint: Color.green, lineWidth: 3)
                                            .frame(width: 20, height: 20, alignment: .center)
                                        Text("正在处理中...")
                                        Spacer()
                                    }
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
                                        .offset(x: 0, y: -20)
                                }
                            }
                        }

                        if messageShowMode == .translate {
                            VStack {
                                if translateResult.isEmpty {
                                    HStack {
                                        Spacer()
                                        Spinner(tint: Color.green, lineWidth: 3)
                                            .frame(width: 20, height: 20, alignment: .center)
                                        Text("正在处理中...")
                                        Spacer()
                                    }
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
                            }
                            .overlay(alignment: .topTrailing) {
                                if !translateResult.isEmpty {
                                    Button {
                                        Clipboard.set(translateResult)
                                        Toast.copy()
                                    } label: {
                                        Image(systemName: "doc.on.clipboard")
                                            .padding(.trailing)
                                            .offset(x: 0, y: -10)
                                    }
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
                                        scaleFactor: scaleFactor,
                                        select: showCopy
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
                    .simultaneousGesture(
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
                    Label("复制", systemImage: "doc.on.doc")
                        .foregroundColor(showCopy ? .red : .primary)
                        .onTapGesture {
                            self.showCopy.toggle()
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
                            chatManager.cancellableRequest?.cancel()
                            chatManager.cancellableRequest = Task.detached(priority: .high) {
                                await translateMessage()
                            }
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
                            chatManager.cancellableRequest?.cancel()
                            chatManager.cancellableRequest = Task.detached(priority: .high) {
                                await abstractMessage(message.search.removingAllWhitespace)
                            }
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
            .onDisappear { chatManager.cancellableRequest?.cancel() }
            .sheet(isPresented: $showAssistantSetting) {
                NavigationStack {
                    NoLetChatSettingsView()
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


                    MarkdownCustomView(
                        content: url,
                        searchText: "",
                        scaleFactor: scaleFactor,
                        select: true
                    )
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

    private func translateMessage() async {
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

        do {
            let results = chatManager.chatsStream(text: datas, tips: .translate(translateLang.name))
            for try await result in results {
                if let outputItem = result.choices.first?.delta.content {
                    Task { @MainActor in
                        self.translateResult += outputItem
                        Haptic.selection(limitFrequency: true)
                    }
                }
            }

        } catch {
            logger.error("\(error)")
            DispatchQueue.main.async {
                translateResult = ""
            }
        }
    }

    private func abstractMessage(_ text: String) async {
        guard abstractResult.isEmpty else { return }

        guard assistantAccouns.first(where: { $0.current }) != nil else {
            Toast.error(title: "需要配置大模型")
            abstractResult = String(localized: "❗️需要配置大模型")
            return
        }

        do {
            let results = chatManager.chatsStream(text: text, tips: .abstract(translateLang.name))
            for try await result in results {
                if let outputItem = result.choices.first?.delta.content {
                    Task { @MainActor in
                        abstractResult += outputItem
                        Haptic.selection(limitFrequency: true)
                    }
                }
            }

        } catch {
            // Handle chunk error here
            logger.error("\(error)")
            Toast.error(title: "发生错误")
        }
    }
}

#Preview {
    SelectMessageView(message: Message(
        id: UUID().uuidString,
        createDate: .now,
        group: "",
        title: "123",
        subtitle: "123",
        body: """
            # 123

            ### 1231231231
            """,
        image: "https://s3.wzs.app/og.png",
        level: 1,
        ttl: 7,
        isRead: true,
        other: ""
    )) {}
}
