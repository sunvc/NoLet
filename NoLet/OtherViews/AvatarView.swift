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
    var defaultAvatar: String? = nil
    var refreshId: UUID? = nil
    var textImage: Bool = true
   
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
        .task(id: "\(icon ?? "")-\(refreshId ?? UUID())") {
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
        
        if let path = await ImageManager.downloadImage(icon),
           let image = UIImage(contentsOfFile: path)
        {
            await MainActor.run {
                avatarImage = image
            }
            return 
        }
        
        if let image = await CloudManager.shared.queryIcons(name: icon).first,
           let icon = PushIcon(from: image),
           let previewImage = icon.previewImage,
           let data = previewImage.pngData()
        {
            await MainActor.run {
                avatarImage = UIImage(data: data)
            }
        }
        
    }
}

#Preview {
    AvatarView(icon: "https://example.com/avatar.png")
        .frame(width: 200, height: 200)
}
