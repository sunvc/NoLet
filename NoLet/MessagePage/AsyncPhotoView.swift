//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AsyncPhotoView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/11/27 22:33.

import Kingfisher
import SwiftUI

struct AsyncPhotoView: View {
    var url: String

    @State private var imageHeight: CGFloat = 100

    var zoom: Bool = true
    var height: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            VStack {
               
                KFImage(URL(string: url))
                    .targetCache(ImageManager.customCache)
                    .resizable()
                    .cancelOnDisappear(true)
                    .retry(maxCount: 3, interval: .seconds(5))
                    .memoryCacheExpiration(.seconds(30))
                    .cacheOriginalImage()
                    .placeholder {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                           
                    }
                    .onSuccess { result in
                        let aspectRatio = proxy.size.width / result.image.size.width
                        imageHeight = result.image.size.height * aspectRatio
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: .topLeading
                    )
                    .if(zoom) { view in
                        view.zoomable()
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
                    .frame(height: 1)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 3)
            }
        }
        .frame(height: imageHeight)
        .frame(maxHeight: height > 0 ? min(height, imageHeight) : imageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}
