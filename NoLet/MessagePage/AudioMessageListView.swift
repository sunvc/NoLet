//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AudioMessageListView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/17 22:18.

import AVFoundation
import Defaults
import SwiftUI

///  AudioMessageListView
///
///

struct AudioMessageListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var pttManager = PushTalkManager.shared
    @Default(.id) var id
    var body: some View {
        NavigationStack {
            List {
                ForEach(pttManager.messages, id: \.id) { item in
                    AudioMessageRow(message: item)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(10)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("消息列表")
            .scrollContentBackground(.hidden)
            .background(TiffanyBlueBackground())
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button {
                            pttManager.deleteAll()
                        } label: {
                            Label("删除所有", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        
    }
}

struct AudioMessageRow: View {
    let message: AudioMessage

    let tiffanyColor = Color(red: 0.35, green: 0.78, blue: 0.80)

    @State private var duration: Double = 0
    @ObservedObject var pttManager = PushTalkManager.shared

    var isPlaying: Bool {
        if case .playing = pttManager.state, pttManager.currentPlayFile == message {
            return true
        }
        return false
    }
    
    var durationNow: Double{
        guard pttManager.currentPlayFile == message else {
            return duration
        }
        return abs(duration - pttManager.currentPlayTime)
    }

    var progress: Double {
        guard pttManager.currentPlayFile == message else {
            return 0
        }

        let value = pttManager.currentPlayTime / max(pttManager.totalPlayTime, 0.001)

        guard value.isFinite else {
            return 0
        }

        return min(max(value, 0), 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 右侧核心气泡主体
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    
                    if message.remote.isEmpty {
                        Image(systemName: "paperplane")
                            .foregroundStyle(.mint)
                    }else{
                        Image(systemName: "radio")
                            .foregroundStyle(.orange)
                    }
                    
                    if let channel = PTTChannel.decimal(message.channel) {
                        Text(verbatim: "\(channel.mhz).\(channel.khz)")
                            .font(.numberStyle(size: 20))
                            
                    }
                    

                    Spacer()

                    Text(message.timestamp, format: .relative(presentation: .named))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }

                HStack(spacing: 12) {
                    Button {
                        pttManager.send(.startPlay(message))
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(tiffanyColor))
                            .shadow(color: tiffanyColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    }.buttonStyle(.borderless)
                    if let filePath = message.filePath() {
                        WaveformScrubber(
                            config: .init(activeTint: .mint),
                            url: filePath,
                            progress: Binding(get: { CGFloat(progress) }, set: { _ in })
                        )
                        .scaleEffect(0.8)
                        .disabled(progress == 0.0)
                    }

                    Text(verbatim: String(format: "%.1fs", durationNow))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor( .primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    GeometryReader {
                        let size = $0.size
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.mint)
                                .frame(width: size.width * progress)
                                .animation(.smooth, value: progress)
                            RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.1))
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 20)
                        )   
                    }
                )
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 12, x: 0, y: 6)
        }
        .onAppear { self.getDuration() }
    }

    func getDuration() {
        Task {
            guard let filePath = message.filePath() else { return }
            let asset = AVURLAsset(url: filePath)
            let duration = try await asset.load(.duration)
            self.duration = CMTimeGetSeconds(duration)
        }
    }
}
