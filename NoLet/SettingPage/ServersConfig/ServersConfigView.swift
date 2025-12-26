//
//  ServersConfigView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/8.
//

import Defaults
import SwiftUI

struct ServersConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Default(.servers) var servers
    @Default(.cloudServers) var cloudServers
    @Default(.noServerModel) var noServerModel
    @EnvironmentObject private var manager: AppManager
    @State private var showNoServerMode: Bool = false
    var showClose: Bool = false

    var body: some View {
        List {
            Section {
                ForEach(servers, id: \.id) { item in
                    ServerCardView(item: item) {
                        Clipboard.set(item.url + "/" + item.key)
                        Toast.copy(title: "复制成功")
                    }
                    .padding(.horizontal, 15)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            Task {
                                _ = await manager
                                    .appendServer(server: item, reset: true)
                            }

                        } label: {
                            Label("重置", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                                .accessibilityLabel("崇置")

                        }.tint(.accentColor)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            guard servers.count > 1 else {
                                self.showNoServerMode.toggle()
                                return
                            }
                            if let group = item.group, group.isEmpty {
                                cloudServers.removeAll(where: { $0.id == item.id })
                            }

                            if let index = servers.firstIndex(where: { $0.id == item.id }) {
                                servers.remove(at: index)
                                Task {
                                    let server = await manager.register(server: item, reset: true)
                                    if server.status {
                                        Toast.success(title: "操作成功")
                                    } else {
                                        Toast.question(title: "操作失败")
                                    }
                                }
                            }

                        } label: {
                            if item.group != nil {
                                Label("删除", systemImage: "arrow.up.bin")
                                    .fontWeight(.bold)
                            } else {
                                Label("移除", systemImage: "arrow.up.bin")
                                    .fontWeight(.bold)
                            }

                        }.tint(.red)
                    }
                }
                .onMove(perform: { indices, newOffset in
                    servers.move(fromOffsets: indices, toOffset: newOffset)
                })
            } header: {
                HStack {
                    Label("使用中的服务器", systemImage: "cup.and.heat.waves")
                        .foregroundStyle(.primary, .green)
                    Spacer()
                    Text(verbatim: "\(servers.count)")
                }
            }

            Section {
                ForEach(manager.servers, id: \.id) { item in
                    if !servers.contains(where: { $0 == item }) {
                        ServerCardView(item: item, isCloud: true) {
                            Task {
                                let server = await manager.register(server: item)
                                if server.status {
                                    servers.append(item)
                                    Toast.success(title: "操作成功")
                                } else {
                                    Toast.question(title: "操作失败")
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = cloudServers
                                    .firstIndex(where: { $0.id == item.id })
                                {
                                    cloudServers.remove(at: index)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

            } header: {
                HStack {
                    Label("历史服务器", systemImage: "cup.and.heat.waves")
                        .foregroundStyle(.primary, .gray)
                    Spacer()
                    Text(verbatim: "\(cloudServers.count - servers.count)")
                }
            }
        }
        .animation(.easeInOut, value: servers)
        .listRowSpacing(10)
        .listStyle(.grouped)
        .refreshable {
            if servers.count > 0 {
                Task{
                    await manager.registers()
                    let updateCount = servers.filter({$0.status}).count 
                    if updateCount == servers.count{
                        Toast.success(title: "更新成功")
                    }else if updateCount > 0 && updateCount < servers.count{
                        Toast.question(title: "部分注册成功")
                    }
                }
                
            } else {
                Toast.question(title: "请先添加服务器")
            }
        }
        .toolbar {
            ToolbarItem {
                withAnimation {
                    Button {
                        manager.fullPage = .customKey
                        manager.sheetPage = .none
                    } label: {
                        Image(systemName: "externaldrive.badge.plus")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.accentColor, Color.primary)
                            .accessibilityLabel("添加服务器")
                    }
                }
            }

            if showClose {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.seal")
                            .accessibilityLabel("关闭")
                    }
                }
            }
        }
        .navigationTitle("服务器")
        .alert("无服务器模式", isPresented: $showNoServerMode) {
            Button("取消", role: .cancel) {}
            Button("开启", role: .destructive) {
                noServerModel = true
                servers = []
                cloudServers.removeAll(where: { $0.group != nil })
                Task.detached(priority: .userInitiated) {
                    let servers = await Defaults[.cloudServers]
                    await withTaskGroup(of: Void.self) { group in
                        for server in servers {
                            group.addTask {
                                let server = await manager.register(server: server)
                                if server.status {
                                    Toast.success(title: "操作成功")
                                } else {
                                    Toast.question(title: "操作失败")
                                }
                            }
                        }
                    }
                }
                manager.router = []
            }
        } message: {
            Text("开启无服务器模式后, 当前服务器列表的设备令牌将清空!!")
        }
        .onDisappear {
            if servers.count == 0 {
                noServerModel = true
            }
        }
    }
}

#Preview {
    ServersConfigView()
        .environmentObject(AppManager.shared)
}
