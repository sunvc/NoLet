//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - TabBarBackButtonView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/17 08:09.

import SwiftUI

struct TabBarBackButtonView: View {
    var size: CGSize
    @ObservedObject private var manager = AppManager.shared
    @State var show = false

    var body: some View {
        Group {
            if manager.historyPage == .setting {
                Button {
                    manager.router = []
                    manager.page = .setting

                    Task.detached {
                        await Haptic.impact()
                        await Tone.play(.share)
                    }
                } label: {
                    Label("设置", systemImage: "gear.badge.questionmark")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.green, .primary)
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .transition(.move(edge: .leading))
                }.button26(.borderless)
            } else {
                Button {
                    manager.router = []
                    manager.page = .message

                    Task.detached {
                        await Haptic.impact()
                        await Tone.play(.share)
                    }
                } label: {
                    Label("消息", systemImage: "ellipsis.message")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.green, .primary)
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .transition(.move(edge: .leading))
                }.button26(.borderless)
            }
        }
        .offset(x: show ? 0 : size.width, y: size.height)
        .onAppear {
            withAnimation(.spring(
                response: 0.3,
                dampingFraction: 0.5,
                blendDuration: 0
            )) {
                show = true
            }
        }
        .onDisappear {
            withAnimation(.spring(
                response: 0.3,
                dampingFraction: 0.5,
                blendDuration: 0
            )) {
                show = false
            }
        }
    }
}
