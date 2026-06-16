//
//  PTTVoiceListView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import AVFoundation
import Defaults
import SwiftUI

///  PTTVoiceListView
///
///

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

///  PTTChannelListView
///
///

struct PTTChannelListView: View {
    var complete: (PTTChannel) -> Bool

    @Environment(\.dismiss) var dismiss

    @Default(.pttHisChannel) var pttHisChannel
    @Default(.pttChannel) var pttChannel
    @Default(.servers) var servers

    var channels: [PTTChannel] {
        pttHisChannel.sorted(by: { $0.timestamp > $1.timestamp })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(channels, id: \.id) { item in
                    Section {
                        HStack {
                            Image(systemName: "speaker.wave.2.bubble")
                                .foregroundStyle(item == pttChannel ? .green : .orange)
                            Text("频道:")
                                .scaleEffect(0.9)
                                .foregroundStyle(.gray)
                            HStack(spacing: 0) {
                                Text(verbatim: "\(item.mhz)")
                                Text(verbatim: ".")
                                Text(verbatim: "\(item.khz)")

                            }.font(.numberStyle(size: 28))

                            Spacer(minLength: 0)
                            Text("选择")
                                .onTapGesture {
                                    _ = complete(item)
                                }
                        }
                        .minimumScaleFactor(0.8)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(10)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.message)
                                .shadow(group: false)
                        )

                        .padding(.horizontal)
                        .swipeActions(allowsFullSwipe: true) {
                            Button {
                                pttHisChannel.removeAll(where: { $0 == item })
                                if pttHisChannel.count == 0 {
                                    self.dismiss()
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }.tint(.red)
                        }

                    } header: {
                        HStack {
                            Text(verbatim: "\(item.timestamp.agoFormatString())")
                                .padding(.leading)
                            Spacer()
                            if item.serverOK {
                                Text(verbatim: "\(item.server.name)")
                                    .padding(.trailing)
                                    .textCase(.lowercase)
                            }
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("历史频道")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button {
                            pttHisChannel = []
                        } label: {
                            Label("删除所有", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .onAppear {
            var pttHisArr: [PTTChannel] = []
            for channel in pttHisChannel {
                if channel.serverOK, servers.contains(channel.server) {
                    pttHisArr.append(channel)
                }
            }

            if pttHisArr.count != pttHisChannel.count {
                pttHisChannel = pttHisArr
            }
        }
    }
}

/// PTTSettingsView
///
///

struct PTTSettingsView: View {
    @ObservedObject var manager = PushTalkManager.shared
    @Default(.eqBands) var eqBands

    @Default(.pttVibration) var pttVibration
    @Default(.pttMusicPlay) var pttMusicPlay

    @Default(.pttVoiceVolume) var pttVoiceVolume
    @Default(.pttSignature) var pttSignature
    @Default(.eqPreset) var eqPreset

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $pttSignature) {
                        Label {
                            Text("加密")
                        } icon: {
                            Image(systemName: "key.icloud")
                                .foregroundStyle(.green, .primary)
                        }
                    }
                }
                Section {
                    Toggle(isOn: $pttVibration) {
                        Label {
                            Text("震动")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundStyle(.primary, .green)
                        }
                    }

                    Toggle(isOn: $pttMusicPlay) {
                        Label {
                            Text("提示音")
                        } icon: {
                            Image(systemName: "speaker.zzz")
                                .foregroundStyle(.primary, .green)
                        }
                    }
                }

                Section {
                    Slider(value: $pttVoiceVolume, in: 0...1) {
                        Label {
                            Text("音量")
                        } icon: {
                            Image(systemName: "speaker.wave.2.circle")
                        }
                    }

                } header: {
                    Text("播放音量")
                }

                equalizerView
            }
            .navigationTitle("PTT设置")
        }
    }

    private var equalizerView: some View {
        Section {
            EQSliderView()
                .frame(height: 180)
                .padding(.vertical, 10)

            EQGlobalGainSlider()

        } header: {
            HStack {
                Text("音效调整器")
                Spacer()
                Picker(selection: $eqPreset) {
                    ForEach(EqualizerPreset.allCases, id: \.self) { item in
                        Label {
                            Text(item.displayName)
                                .tag(item)
                        } icon: {
                            Image(systemName: item.iconName)
                        }
                    }
                } label: { Text("切换服务器") }
                    .tint(.black)
                    .pickerStyle(MenuPickerStyle())
                    .offset(x: 10)
                    .onChange(of: eqBands) { _ in
                        manager.changeEQ()
                    }
            }
        }
        .listSectionSeparator(.hidden)
    }
}

#Preview {
    PTTContentView()
}
