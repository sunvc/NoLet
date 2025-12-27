//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - AppView+.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/27 12:09.
    
import SwiftUI

extension View {
    @ViewBuilder
    func saveToAlbumButton(
        albumName: String? = nil,
        imageURL: String? = nil,
        image: UIImage? = nil
    ) -> some View {
        Button {
            Task {
                let (success, status) = await ImageManager.saveToAlbum(
                    albumName: albumName,
                    imageURL: imageURL,
                    image: nil
                )
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
        } label: {
            Label(
                "保存图片",
                systemImage: "square.and.arrow.down.on.square"
            ).customForegroundStyle(.green, .primary)
        }
    }
}
