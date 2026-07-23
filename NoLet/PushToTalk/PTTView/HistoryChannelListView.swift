//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - HistoryChannelListView.swift
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

struct HistoryChannelListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var globalTime: Double = 0.0
    @ObservedObject private var pttManager = PTTManager.shared
    @Default(.pttHisChannel) var pttHisChannel
    @Default(.pttChannel) var pttChannel
    @Default(.servers) var servers

    /// Sorted history — most-recently-visited first. Single-channel semantics
    /// means "active" is derived from equality with `pttChannel`, not the
    /// stored `PTTChannel.active` flag (which is now legacy metadata).
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
                            // Tap on a row = switch to that channel. We only
                            // support one active channel at a time now, so
                            // there is no per-row toggle any more.
                            guard channel != pttChannel else {
                                self.dismiss()
                                return
                            }
                            Task {
                                await pttManager.switchChannel(to: channel)
                            }
                            self.dismiss()
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .swipeActions(allowsFullSwipe: true) {
                            Button {
                                // Never allow removing the currently-selected
                                // bookmark from the list — that would leave us
                                // in a "no channel" state on next launch.
                                guard channel != pttChannel else {
                                    Toast.info(title: "主频道不能删除")
                                    return
                                }
                                pttHisChannel.removeAll(where: { $0 == channel })
                                if pttHisChannel.count == 0 {
                                    self.dismiss()
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }.tint(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("历史频道")
                .background(ContentBackgroundView())
                .toolbar {
                    ToolbarItem {
                        Menu {
                            Button {
                                if !pttManager.powerState {
                                    // Keep the current channel; wipe the rest.
                                    pttHisChannel = pttHisChannel.filter { $0 == pttChannel }
                                }
                            } label: {
                                Label("删除其他", systemImage: "trash")
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
                // Drop bookmarks that reference servers the user has since
                // removed. Same guardrail as before.
                var cleaned: [PTTChannel] = []
                for channel in pttHisChannel {
                    if channel.serverOK, servers.contains(channel.server) {
                        cleaned.append(channel)
                    }
                }
                if cleaned.count != pttHisChannel.count {
                    pttHisChannel = cleaned
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
        // Under single-channel semantics "active" == "this is the currently
        // selected channel". PTTChannel.active is legacy metadata and no
        // longer drives the row style.
        let isCurrent = (channel == currentChannel)

        VStack(spacing: 3) {
            // Top Section: 频道名称与状态标尺
            HStack(alignment: .center, spacing: 5) {
                Button {
                    monitoring()
                } label: {
                    Image(systemName: isCurrent ? "dot.radiowaves.left.and.right" : "arrow.triangle.swap")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                        .foregroundStyle(isCurrent ? .mint : .secondary)
                }
                .buttonStyle(.borderless)
                .padding(.trailing)

                HStack(alignment: .bottom, spacing: 5) {
                    Text(String(format: "%.3f", Double(channel.channel) / 1000.0))
                        .font(.numberStyle(size: 25))
                        .fontWeight(.bold)
                        .padding(.vertical, 2)
                        .foregroundStyle(isCurrent ? .mint : .primary)

                    Text(verbatim: "MHz")
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
                if isCurrent {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(channel.users.count > 0 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green.opacity(0.6), radius: 4)
                            .opacity(0.4 + (sin(globalTime * 8) + 1) * 0.3) // 👈 呼吸频率

                        Text(channel.server.name)
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(channel.users.count > 0 ? Color.mint : Color.orange)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(channel.users.count) 人在线")
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
