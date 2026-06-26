//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PTTMessageView.swift
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

///  PTTMessageView
///
///

struct PTTMessageView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var pttManager = PTTManager.shared
    @Default(.id) var id
    var body: some View {
        NavigationStack {
            List {
                ForEach(pttManager.messages, id: \.id) { item in
                    PTTMessageRow(message: item)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(10)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("消息列表")
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
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

struct PTTMessageRow: View {
    let message: AudioMessage

    let tiffanyColor = Color(red: 0.35, green: 0.78, blue: 0.80)

    @State private var duration: Double = 0
    @ObservedObject var pttManager = PTTManager.shared

    var isPlaying: Bool {
        if case .playing = pttManager.state, pttManager.currentPlayFile == message {
            return true
        }
        return false
    }

    var durationNow: Double {
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

    @State private var sendStatus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if message.url.isEmpty {
                    HStack{
                        Image(systemName: "paperplane")
                            .font(.title3)
                            .foregroundStyle(message.status.color)
                            
                        
                        if message.status == .failed, !sendStatus {
                            Text("重试")
                                .font(.numberStyle(size: 17))
                                .foregroundStyle(.red)
                        }
                    }
                    .VButton { _ in
                        guard !sendStatus, message.status == .failed else { return false}
                        self.sendStatus = true
                        Task {
                            await pttManager.sendVoice(message: message)
                            self.sendStatus = false
                        }
                        return true
                    }
                    .disabled(sendStatus)
                } else {
                    Image(systemName: "radio")
                        .foregroundStyle(.orange)
                        .font(.title)
                }

                if let channel = PTTChannel.decimal(message.channel) {
                    Text(verbatim: "\(channel.mhz).\(channel.khz)")
                        .font(.numberStyle(size: 20))
                }
                
                Spacer()
                
                Text(message.timestamp, format: .relative(presentation: .named))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .padding(.trailing, 10)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await pttManager.send(.startPlay(message))
                    }
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
                    .foregroundColor(.primary)
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
        .padding(15)
        .glassCard(20, borderColor: message.status.color)
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

#Preview {
    PTTMessageRow(message: AudioMessage(channel: "923", from: "123", file: "file", status: .failed))
        .frame(height: 100)
}
