//
//  Image+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//
import Photos
import SwiftUI

extension Image {
    @ViewBuilder
    func customDraggable(
        _ width: CGFloat = .zero,
        appear: ((Image) -> Void)? = nil,
        disappear: ((Image) -> Void)? = nil
    ) -> some View {
        draggable(self) {
            self
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width == .zero ? 300 : width)
                .onAppear {
                    appear?(self)
                }
                .onDisappear {
                    disappear?(self)
                }
        }
    }
}
