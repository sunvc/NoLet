//
//  MarkdownCustomView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/3/26.
//

import cmark_gfm
import cmark_gfm_extensions
import Foundation
import Kingfisher
import MarkdownUI
import Splash
import SwiftUI
import WebKit


struct MarkdownCustomView: View {
    @Environment(\.colorScheme) var colorScheme

    var content: String
    var searchText: String
    var scaleFactor: CGFloat
    var select: Bool

    private var codeHighlightColorScheme: Splash.Theme {
        colorScheme == .dark ? .wwdc17(withFont: .init(size: 16)) :
            .sunset(withFont: .init(size: 16))
    }

    init(
        content: String,
        searchText: String = "",
        scaleFactor: CGFloat = 1.0,
        select: Bool = false
    ) {
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText = searchText
        self.scaleFactor = scaleFactor
        self.select = select
    }

    @ScaledMetric(relativeTo: .callout) var baseSize: CGFloat = 17

    var body: some View {
        Group {
            if !searchText.isEmpty || select {
                SelectableMarkdown(content, highlightText: searchText, highlightColor: .red)
            } else {
                Markdown(content)
                    .textSelection(.enabled)
            }
        }
        .markdownImageProvider(WebImageProvider())
        .markdownInlineImageProvider(WebInlineImageProvider())
        .environment(\.openURL, OpenURLAction { url in
            AppManager.openURL(url: url, .safari)
            return .handled
        })
        .markdownCodeSyntaxHighlighter(.splash(theme: codeHighlightColorScheme))
        .markdownTheme(MarkdownTheme.defaultTheme(baseSize, scaleFactor: scaleFactor))
    }
}

struct WebImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        WebImageView(url: url)
    }
}

struct WebInlineImageProvider: InlineImageProvider {
    func image(with url: URL, label _: String) async throws -> Image {
        let maxWidth = await MainActor.run { UIScreen.main.bounds.width - 30 }
        guard let thumb = await ImageManager.thumbImage(
            url.absoluteString, maxPixel: maxWidth
        ) else {
            throw NSError(
                domain: "WebInlineImageProvider",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No Image!"]
            )
        }
        return Image(uiImage: thumb)
    }
}

enum ImagePhase: Sendable {
    case empty
    case success(UIImage)
    case failure(String)
}

struct WebImageView: View {
    var url: URL?
    @State private var image: UIImage?
    @State private var status: ImagePhase = .empty
    var body: some View {
        switch status {
        case .empty:
            Label("正在处理中...", systemImage: "rays")
                .task {
                    // 结构化任务:cell 消失即取消,不再用 detached 孤儿任务。
                    await loadImage(url: url)
                }
        case .success(let image):
            ResizeToFit(idealSize: image.size) {
                Image(uiImage: image)
                    .resizable()
                    .contextMenu {
                        saveToAlbumButton(albumName: nil, imageURL: nil, image: image)
                    }
            }
        case .failure(let error):
            Text(verbatim: error)
        @unknown default:
            Text("图片未加载")
        }
    }

    func loadImage(url: URL?) async {
        guard let url else {
            status = .failure(String(localized: "地址错误"))
            return
        }
        // 下采样到屏宽,正文大图不再全像素解码常驻内存。
        if let thumb = await ImageManager.thumbImage(
            url.absoluteString,
            maxPixel: UIScreen.main.bounds.width
        ) {
            guard !Task.isCancelled else { return }
            image = thumb
            status = .success(thumb)
        } else {
            status = .failure(String(localized: "加载失败"))
        }
    }
}

struct HighlightedText: View {
    var text: String
    var searchText: String?
    var body: some View {
        if let searchText, !searchText.isEmpty {
            MarkdownCustomView(content: text, searchText: searchText)
        } else {
            Text(text)
        }
    }
}

#Preview {
    ContentView()
}
