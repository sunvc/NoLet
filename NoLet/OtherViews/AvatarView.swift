////
//// AvatarView.swift
////  NoLet
////
////  Author:        Copyright (c) 2024 QingHe. All rights reserved.
////  Document:      https://wiki.wzs.app
////  E-mail:        to@wzs.app
////
////
////  History:
////    Created by Neo 2024/10/8.
////
//
//import AVKit
//import Defaults
//import Kingfisher
//import SwiftUI
//
//struct AvatarView: View {
//    var icon: String?
//    var customIcon: String = ""
//
//    @Default(.appIcon) var appicon
//
//    @State private var image: URL?
//
//    var body: some View {
//        GeometryReader { proxy in
//            contentView(size: proxy.size)
//                .aspectRatio(contentMode: .fill)
//                .frame(width: proxy.size.width, height: proxy.size.height)
//        }
//        .onChange(of: icon) { _ in
//            image = nil
//        }
//    }
//
//    // MARK: - 主视图构建
//
//    @ViewBuilder
//    private func contentView(size _: CGSize) -> some View {
//        if let icon, customIcon.isEmpty {
//            if icon.hasHttp {
//                if let image {
//                    KFImage(image)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                } else {
//                    ProgressView()
//                        .onAppear {
//                            loadImage(icon: icon)
//                        }
//                }
//            } else if let imagedata = icon.avatarImage() {
//                Image(uiImage: imagedata)
//                    .resizable()
//
//            } else {
//                defaultImage()
//            }
//        } else if !customIcon.isEmpty {
//            Image(customIcon)
//                .resizable()
//
//        } else {
//            defaultImage()
//        }
//    }
//
//    private func defaultImage() -> some View {
//        Image(appicon.logo)
//            .resizable()
//    }
//
//    // MARK: - 加载远程图片
//
//    private func loadImage(icon: String) {
//        image = nil
//        Task {
//            if let localPath = await ImageManager.downloadImage(icon) {
//                image = URL(fileURLWithPath: localPath)
//            }
//        }
//    }
//}
//
//#Preview {
//    AvatarView(icon: "")
//        .frame(width: 300, height: 300)
//}

import SwiftUI
import Defaults

struct AvatarView: View {
    var icon: String?
    var customIcon: String = ""

    @Default(.appIcon) private var appicon

    @State private var loadTask: Task<Void, Never>?
    @State private var loadingState: LoadingState = .idle

    enum LoadingState {
        case idle
        case loading
        case success(UIImage)
        case failed
    }

    var body: some View {
        contentView
            .clipped()
            .onAppear { reload() }
            .onChange(of: icon) { _ in reload() }
    }

    // MARK: - 主视图内容
    @ViewBuilder
    private var contentView: some View {
        if let icon, !icon.isEmpty, customIcon.isEmpty {
            if icon.hasHttp {  // 在线头像
                switch loadingState {
                case .idle, .loading:
                    ProgressView()

                case .success(let img):
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                case .failed:
                    defaultImage()
                }

            } else if let uiImage = icon.avatarImage() {  // 本地头像
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

            } else {
                defaultImage()
            }
        }

        // 自定义 icon（资源文件）
        else if !customIcon.isEmpty {
            Image(customIcon)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }

        else {
            defaultImage()
        }
    }

    private func defaultImage() -> some View {
        Image(appicon.logo)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    // MARK: - 加载与取消
    private func reload() {
        loadTask?.cancel()
        loadingState = .idle

        guard let icon, icon.hasHttp else { return }

        loadingState = .loading

        loadTask = Task {
            if let file = await ImageManager.downloadImage(icon),
               let img = downsampleImage(at: URL(fileURLWithPath: file), to: CGSize(width: 300, height: 300))
            {
                if !Task.isCancelled {
                    await MainActor.run { loadingState = .success(img) }
                }
            } else {
                await MainActor.run { loadingState = .failed }
            }
        }
    }

    // MARK: - Downsample（控制内存的关键）
    private func downsampleImage(at url: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {

        let maxDimension = max(pointSize.width, pointSize.height) * scale

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else { return nil }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension),
            kCGImageSourceShouldCacheImmediately: true,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    AvatarView(icon: "https://example.com/avatar.png")
        .frame(width: 200, height: 200)
}
