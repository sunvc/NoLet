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

import Defaults
import Kingfisher
import SwiftUI

/// AvatarView 的 .task(id:) 使用的稳定复合键。
/// 只依赖 icon 与显式传入的 refreshId,任一变化才重跑 loadImage()。
private struct AvatarTaskID: Hashable {
    let icon: String?
    let refreshId: UUID?
}

struct AvatarView: View {
    var icon: String?
    var defaultAvatar: String? = nil
    var refreshId: UUID? = nil
    var textImage: Bool = true
    /// 下采样上限(像素)。列表头像 30–45pt,默认 150 已覆盖 @3x;
    /// 大头像场景(如 120pt)显式传更大值。
    var maxPixel: CGFloat = 150

    @Default(.appIcon) private var appicon

    @State private var avatarImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let icon, !icon.isEmpty {
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                } else if let uiImage = icon.avatarImage(), textImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                } else {
                    defaultImage()
                }
            } else {
                defaultImage()
            }
        }
        .clipped()
        .task(id: AvatarTaskID(icon: icon, refreshId: refreshId)) {
            await loadImage()
        }
    }

    private func defaultImage() -> some View {
        Group {
            if let defaultAvatar {
                Image(systemName: defaultAvatar)
                    .resizable()
            } else {
                Image(appicon.logo)
                    .resizable()
            }
        }
        .aspectRatio(contentMode: .fill)
    }

    func loadImage() async {
        guard let icon = icon else { return }

        // 下采样到显示尺寸,避免把原始大图全像素解码常驻内存。
        if let thumb = await ImageManager.thumbImage(icon, maxPixel: maxPixel),
           !Task.isCancelled
        {
            await MainActor.run { avatarImage = thumb }
            return
        }

        if !Task.isCancelled,
           let icon = try? await PushIcon.query(
               NSPredicate(format: "name == %@", icon),
               from: NCONFIG.publicCloudDatabase
           ).first,
           let previewImage = icon.previewImage,
           let data = previewImage.pngData(),
           let image = UIImage(data: data)
        {
            await MainActor.run { avatarImage = image }
        }
    }
}

#Preview {
    AvatarView(icon: "https://example.com/avatar.png")
        .frame(width: 200, height: 200)
}
