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

import SwiftUI
import Kingfisher


struct AsyncPhotoView: View {
    var url: String

    @State private var imageHeight: CGFloat = 100
    @State private var status: ImageLoadState = .empty
    
    var zoom:Bool = true
    var body: some View {
        GeometryReader { proxy in

            VStack {
               
                switch status {
                case .empty:
                    VStack{
                        Spacer()
                        ProgressView("加载中…")
                        Spacer()
                    }
                case .success(let image):
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height,
                            alignment: .topLeading
                        )
                        
                        .contextMenu {
                            Button {
                                
                                Task{ 
                                    if let file = await ImageManager.downloadImage( url),
                                       let uiimage = UIImage(contentsOfFile: file){
                                        uiimage.bat_save(intoAlbum: nil) { success, status in
                                            if status == .authorized || status == .limited {
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
                        } preview: {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: proxy.size.width,
                                    height: proxy.size.height,
                                    alignment: .topLeading
                                )
                        }
                        .if(zoom){ view in
                            view.zoomable()
                        }
                    
                case .failure:
                    VStack{
                        Spacer()
                        Image(systemName: "camera.shutter.button")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                        Spacer()
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
                    .frame(height: 1)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 3)
            }
            .task(id: url) {
                self.loadingImage(width: proxy.size.width)
            }
        }
        .frame(height: imageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        
    }

    func loadingImage(width: CGFloat)  {
        // 1. memory cache
        Task.detached(priority: .background){ 
            if  let thumb = await ImageManager.thumbImage(url, maxPixel: 800) {
                DispatchQueue.main.async{
                    self.imageHeight = thumb.scaledSize(withWidth: width).height
                    self.status = .success(thumb)
                }
                
            }else{
                DispatchQueue.main.async{
                    self.status = .failure
                }
            }
        }
    }
    
    enum ImageLoadState {
        case empty
        case success(UIImage)
        case failure
    }
}
