//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PTTChannelHistoryListView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/18 07:35.

import AVFoundation
import Defaults
import SwiftUI

struct PTTChannelHistoryListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var globalTime: Double = 0.0 // 驱动活跃频道的波形和绿灯闪烁
    @ObservedObject private var pttManager = PushTalkManager.shared
    @Default(.pttHisChannel) var pttHisChannel
    @Default(.pttChannel) var pttChannel
    @Default(.servers) var servers

    var channels: [PTTChannel] {
        pttHisChannel.sorted(by: { $0.timestamp > $1.timestamp })
    }

    var body: some View {
        TimelineView(.animation) { context in
            NavigationStack {
                List {
                    ForEach(channels, id: \.id) { channel in
                        ChannelMonitorRow(
                            channel: channel,
                            currentChannel: pttChannel,
                            globalTime: globalTime
                        ) {
                            guard channel != pttChannel else {
                                Toast.info(title: "主频道不能关闭")
                                return
                            }

                            if let index = pttHisChannel.firstIndex(of: channel) {
                                pttHisChannel[index].active = !channel.active
                                if pttManager.powerState {
                                    if pttHisChannel[index].active {
                                        Task {
                                            await pttManager.publicJoinConnect()
                                        }
                                    } else {
                                        Task {
                                            await pttManager.publicLevelConnect([channel])
                                        }
                                    }
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .swipeActions(allowsFullSwipe: true) {
                            Button {
                                pttHisChannel.removeAll(where: { $0 == channel })
                                if pttHisChannel.count == 0 {
                                    self.dismiss()
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }.tint(.red)
                        }

                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                if PushTalkManager.shared.powerState {
                                    pttHisChannel.set(channel, active: true)

                                    Task {
                                        await PushTalkManager.shared.publicJoinConnect()
                                    }
                                } else {
                                    pttHisChannel.set(channel, active: false)
                                }

                                pttChannel = channel

                            } label: {
                                Label("默认", systemImage: "pencil.line")
                            }.tint(.mint)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("监听频道")
                .background(TiffanyBlueBackground())
                .toolbar {
                    ToolbarItem {
                        Menu {
                            Button {
                                if !pttManager.powerState {
                                    pttHisChannel = []
                                }
                            } label: {
                                Label("删除所有", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onChange(of: context.date) { newDate in
                // 持续驱动动画时间轴
                globalTime = newDate.timeIntervalSinceReferenceDate
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
}

struct ChannelMonitorRow: View {
    let channel: PTTChannel
    let currentChannel: PTTChannel
    let globalTime: Double

    @Environment(\.colorScheme) var colorScheme

    var monitoring: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            // Top Section: 频道名称与状态标尺
            HStack(alignment: .center, spacing: 5) {
                Button {
                    monitoring()
                } label: {
                    Image(systemName: "power.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.white, channel.active ? .red : .mint)
                }
                .buttonStyle(.borderless)
                .padding(.trailing)

                HStack(alignment: .bottom, spacing: 5) {
                    Text(String(format: "%.3f", Double(channel.channel) / 1000.0))
                        .font(.numberStyle(size: 25))
                        .fontWeight(.bold)
                        .padding(.vertical, 2)
                        .foregroundStyle(channel == currentChannel ? .mint : .primary)

                    Text("MHz")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(2)
                }

                Spacer()

                Text(channel.timestamp, format: .relative(presentation: .named))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()
                .opacity(0.4)
                .padding(.vertical, 5)

            HStack {
                if channel.active {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(channel.users > 0 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green.opacity(0.6), radius: 4)
                            .opacity(0.4 + (sin(globalTime * 8) + 1) * 0.3) // 👈 呼吸频率

                        Text(channel.server.name)
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(channel.users > 0 ? Color.mint : Color.orange)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(channel.users) 人在线")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)

                        Text(channel.server.name)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<7) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 2.5, height: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .glassCard(15)
    }
}
