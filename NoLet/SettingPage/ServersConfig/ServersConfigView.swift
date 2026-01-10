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
    @Default(.servers) var servers
    @Default(.noServerModel) var noServerModel

    @EnvironmentObject private var manager: AppManager
    @StateObject private var chatManager = NoLetChatManager.shared
    @State private var showNoServerMode: Bool = false

    var cloudServers: [PushServerModel] {
        manager.servers.filter { item in
            !self.servers.contains(where: { $0.server == item.server })
        }
    }

    var NormalServer: [PushServerModel] {
        servers.filter { $0.status }
    }

    var ErrorServer: [PushServerModel] {
        servers.filter { !$0.status }
    }

    var body: some View {
        List {
            Section {
                ForEach(NormalServer, id: \.id) { item in
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
                    Label("运行中", systemImage: "cup.and.heat.waves")
                        .foregroundStyle(.primary, .green)
                    Spacer()
                    Text(verbatim: "\(NormalServer.count)")
                }
            }
            if ErrorServer.count > 0 {
                Section {
                    ForEach(ErrorServer, id: \.id) { item in
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

                                if let index = servers.firstIndex(where: { $0.id == item.id }) {
                                    servers.remove(at: index)
                                    Task {
                                        let server = await manager.register(
                                            server: item,
                                            reset: true
                                        )
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
                        Label("故障", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.primary, .red)
                        Spacer()
                        Text(verbatim: "\(ErrorServer.count)")
                    }
                }
            }
        }
        .animation(.easeInOut, value: servers)
        .listRowSpacing(10)
        .listStyle(.grouped)
        .refreshable {
            Task(priority: .userInitiated) {
                await AppManager.syncServer()
            }

            if servers.count > 0 {
                Task {
                    await manager.registers()
                    let updateCount = servers.filter { $0.status }.count
                    if updateCount == servers.count {
                        Toast.success(title: "更新成功")
                    } else if updateCount > 0 && updateCount < servers.count {
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
                        manager.open(sheet: nil)
                        manager.open(full: .customKey)
                    } label: {
                        Image(systemName: "plus.viewfinder")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.accentColor, Color.primary)
                            .accessibilityLabel("添加服务器")
                    }
                }
            }
            if cloudServers.count > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        manager.open(sheet: .cloudServer)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.accentColor, Color.primary)
                            .accessibilityLabel("查看历史服务器")
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

struct CloudServersView: View {
    @Default(.servers) var servers
    @Default(.noServerModel) var noServerModel
    @EnvironmentObject private var manager: AppManager
    @EnvironmentObject private var chatManager: NoLetChatManager

    var cloudServers: [PushServerModel] {
        manager.servers.filter { item in
            !self.servers.contains(where: { $0.server == item.server })
        }
    }

    @State private var downID: String? = nil
    var body: some View {
        List {
            ForEach(cloudServers, id: \.id) { item in
                ServerCardView(item: item, isCloud: true, loading: downID == item.id) {
                    Task { @MainActor in
                        self.downID = item.id
                        let success = await manager.appendServer(server: item)
                        if success {
                            manager.open(sheet: nil)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            self.downID = nil
                        }
                    }
                }
                .disabled(self.downID != nil)
                .padding(.horizontal, 15)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { @MainActor in
                            
                            let success = await CloudManager.shared.delete(
                                item.id,
                                pub: false
                            )
                            if success {
                                manager.servers.removeAll(where: { $0.id == item.id })
                                Toast.success(title: "删除成功")
                            }
                           
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .animation(.easeInOut, value: cloudServers)
        .listRowSpacing(10)
        .listStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Text(verbatim: "\(max(manager.servers.count - servers.count, 0))")
                }
            }
        }
        .navigationTitle("历史服务器")
        .navigationBarTitleDisplayMode(.inline)
    }
}
