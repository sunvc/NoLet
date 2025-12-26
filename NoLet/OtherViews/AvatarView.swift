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

struct AvatarView: View {
    var icon: String?
    var customIcon: String = ""

    @Default(.appIcon) private var appicon

    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let icon, !icon.isEmpty, customIcon.isEmpty {
                if icon.hasHttp { // 在线头像
                    KFImage(URL(string: icon))
                        .targetCache(ImageManager.customCache)
                        .resizable()
                        .fade(duration: 0.25)
                        .loadTransition(.move(edge: .leading))

                } else if let uiImage = icon.avatarImage() { // 本地头像
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
        .clipped()
    }

    private func defaultImage() -> some View {
        Image(appicon.logo)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}

#Preview {
    AvatarView(icon: "https://example.com/avatar.png")
        .frame(width: 200, height: 200)
}
