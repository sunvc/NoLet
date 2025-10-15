//
// AvatarView.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//


import SwiftUI
import Defaults
import Kingfisher
import AVKit

struct AvatarView: View {

	var icon:String?
    var customIcon:String = ""
	
	@Default(.appIcon) var appicon
	
    @State private var image: URL?
	
    var body: some View {
        GeometryReader { proxy in
            contentView(size: proxy.size)
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onChange(of: icon) { _ in
            image = nil
        }
    }

    // MARK: - 主视图构建
    @ViewBuilder
    private func contentView(size: CGSize) -> some View {
        if let icon, customIcon.isEmpty {
            if icon.hasHttp() {
                if let image {
                    KFImage(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ProgressView()
                        .onAppear {
                            loadImage(icon: icon)
                        }
                }
            } else if let imagedata = icon.avatarImage() {
                Image(uiImage: imagedata)
                    .resizable()
                    
            } else {
                defaultImage()
            }
        } else if !customIcon.isEmpty {
            Image(customIcon)
                .resizable()
                
        } else {
            defaultImage()
        }
    }


    private func defaultImage() -> some View {
        Image(appicon.logo)
            .resizable()
            
    }

    // MARK: - 加载远程图片
    private func loadImage(icon: String) {
        image = nil
        Task.detached(priority: .background) {
            if let localPath = await ImageManager.downloadImage(icon) {
                await MainActor.run {
                    image = URL(fileURLWithPath: localPath)
                }
            }
        }
    }
}

#Preview {
    AvatarView(icon: "")
        .frame(width: 300, height: 300)
}
