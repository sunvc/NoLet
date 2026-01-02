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

    private var codeHighlightColorScheme: Splash.Theme {
        colorScheme == .dark ? .wwdc17(withFont: .init(size: 16)) :
            .sunset(withFont: .init(size: 16))
    }

    init(content: String, searchText: String = "", scaleFactor: CGFloat = 1.0) {
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.searchText = searchText
        self.scaleFactor = scaleFactor
    }

    @ScaledMetric(relativeTo: .callout) var baseSize: CGFloat = 17

    var body: some View {
        if !searchText.isEmpty {
    
            HighlightedText( text: PBMarkdown.plain(content), searchText: searchText)
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))

        } else {
            Markdown(content)
                .markdownImageProvider(WebImageProvider())
                .markdownInlineImageProvider(WebInlineImageProvider())
                .environment(\.openURL, OpenURLAction { url in
                    AppManager.openURL(url: url, .safari)
                    return .handled // 表示链接已经被处理，不再执行默认行为
                })
                .markdownCodeSyntaxHighlighter(.splash(theme: codeHighlightColorScheme))
                .markdownTheme(MarkdownTheme.defaultTheme(baseSize, scaleFactor: scaleFactor))
        }
    }
}

struct WebImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        WebImageView(url: url)
    }
}

struct WebInlineImageProvider: InlineImageProvider {
    func image(with url: URL, label _: String) async throws -> Image {
        // 下载图片
        guard let imagePath = await ImageManager.downloadImage(url.absoluteString),
              let original = UIImage(contentsOfFile: imagePath)
        else {
            throw NSError(
                domain: "WebInlineImageProvider",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No Image!"]
            )
        }

        // 获取屏幕宽度（逻辑点）
        let maxWidth = UIScreen.main.bounds.width - 30

        // 按屏幕宽度等比缩放
        let resized = resizedImageIfNeeded(original: original, maxWidth: maxWidth)

        return Image(uiImage: resized)
    }

    // MARK: - Helper：按逻辑点宽度缩放

    private func resizedImageIfNeeded(original: UIImage, maxWidth: CGFloat) -> UIImage {
        let originalWidth = original.size.width
        let originalHeight = original.size.height

        // 如果原图宽度小于屏幕宽度，就不缩放
        guard originalWidth > maxWidth else {
            return original
        }

        let scale = maxWidth / originalWidth
        let newSize = CGSize(width: originalWidth * scale, height: originalHeight * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let newImage = renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return newImage
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
                    Task.detached(priority: .background) {
                        await self.loadImage(url: url)
                    }
                }
        case .success(let image):
            ResizeToFit(idealSize: image.size) {
                Image(uiImage: image)
                    .resizable()
                    .contextMenu{
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
        if let url = url {
            if let imageURL = await ImageManager.downloadImage(url.absoluteString),
               let uiImage = UIImage(contentsOfFile: imageURL)
            {
                image = uiImage
                status = .success(uiImage)
            } else {
                status = .failure(String(localized: "加载失败"))
            }
        } else {
            status = .failure(String(localized: "地址错误"))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
