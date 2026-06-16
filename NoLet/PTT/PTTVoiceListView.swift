//
//  PTTVoiceListView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import AVFoundation
import Defaults
import SwiftUI

struct PTTVoiceListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var pttManager = PushTalkManager.shared
    @Default(.id) var id
    var body: some View {
        NavigationStack {
            List {
                ForEach(pttManager.messages, id: \.id) { item in
                    Section {
                        HStack {
                            if item.remote.isEmpty {
                                Spacer(minLength: 0)
                            }

                            VoiceCard(message: item, manager: pttManager, isMe: item.remote.isEmpty)
                                .VButton { _ in
                                    pttManager.send(.startPlay(item))
                                    return true
                                }

                            if !item.remote.isEmpty {
                                Spacer(minLength: 0)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(10)

                    } header: {
                        HStack {
                            if let channel = PTTChannel.decimal(item.channel) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.bubble")
                                        .foregroundStyle(item.read ? .gray : .green)

                                    Text(verbatim: "\(channel.mhz).\(channel.khz)")
                                        .font(.numberStyle(size: 20))
                                        .fontWeight(.black)
                                }
                            }
                            Spacer()
                            TimesSwitchView(timestamp: item.timestamp)
                                .foregroundStyle(.gray)
                        }
                    }
                    .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("消息列表")
            .navigationBarTitleDisplayMode(.inline)
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

private struct TimesSwitchView: View {
    var timestamp: Date
    @State private var show: Bool = false
    var body: some View {
        Text(show ? timestamp.formatString() : timestamp.agoFormatString())
            .foregroundStyle(.gray)
            .onTapGesture {
                self.show.toggle()
            }
    }
}

struct VoiceCard: View {
    var message: PttMessageModel
    @ObservedObject var manager: PushTalkManager
    @State private var duration: Double = 0
    var isMe: Bool
    var progress: Double {
        guard manager.currentPlayFile == message else {
            return 0
        }

        let value = manager.currentPlayTime / max(manager.totalPlayTime, 0.001)

        guard value.isFinite else {
            return 0
        }

        return min(max(value, 0), 1)
    }

    var body: some View {
        HStack {
            if !isMe {
                Image(systemName: "dot.radiowaves.right")
                    .font(.title3)
                    .padding(.leading, 10)
            }

            Spacer(minLength: 0)

            Text(verbatim: "\(String(format: "%.1f", duration))")
                .font(.headline)

            Spacer(minLength: 0)

            if isMe {
                Image(systemName: "dot.radiowaves.right")
                    .font(.title3)
                    .padding(.leading, 10)
                    .rotationEffect(.degrees(180))
            }
        }
        .fontWeight(.black)
        .frame(height: 50)
        .frame(width: calc(UIScreen.main.bounds.width))
        .background(
            GeometryReader {
                let size = $0.size
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: size.width * progress)
                        .animation(.smooth, value: progress)
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.gray, lineWidth: 5)
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.message)
                        .shadow(group: false)
                )
            }
        )

        .frame(height: 50)
        .padding(.horizontal, 10)
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

    func calc(_ width: CGFloat) -> CGFloat {
        let minWidth = width * 0.2
        let maxWidth = width * 0.8

        let maxDuration: CGFloat = 60

        let progress = min(duration, maxDuration) / maxDuration

        return minWidth + (maxWidth - minWidth) * sqrt(progress)
    }
}

#Preview {
    PushToTalkView()
}
