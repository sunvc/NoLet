//
//  ServersConfiView.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//

import SwiftUI
import Defaults

struct ServersConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Default(.servers) var servers
    @Default(.cloudServers) var cloudServers
    @EnvironmentObject private var manager:AppManager
    
    var showClose:Bool = false
    
    
    var body: some View {
      
            List{
                Section{
                    ForEach(servers, id: \.id){ item in
                        
                        ServerCardView( item: item){
                            Clipboard.set(item.url + "/" + item.key)
                            Toast.copy(title: "复制 URL 和 KEY 成功")
                        }
                        .padding(.horizontal, 15)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button{
                                Task{
                                    let success = await manager.appendServer(server: PushServerModel(url: item.url ))
                                    
                                    if success {
                                        if let index = servers.firstIndex(where:{$0.id == item.id}){
                                            servers.remove(at: index)
                                            Task{
                                               _ = await manager.register(server: item, reset: true)
                                            }
                                        }
                                    }
                                }
                                
                            }label:{
                                Label("重置", systemImage: "arrow.clockwise")
                                    .fontWeight(.bold)
                                    .accessibilityLabel("崇置")

                            }.tint(.accentColor)
                        }
                        .if( servers.count > 1){ view in
                            view
                                .swipeActions(edge: .trailing, allowsFullSwipe: true){
                                    
                                    Button{
                                        
                                        if let index = servers.firstIndex(where:{$0.id == item.id}){
                                            servers.remove(at: index)
                                            Task{
                                                _ = await manager.register(server: item, reset: true)
                                            }
                                        }
                                    }label:{
                                        Label("移除", systemImage: "arrow.up.bin")
                                            .fontWeight(.bold)
                                    }.tint(.red)
                                }
                        }
                        
                    }
                    .onMove(perform: { indices, newOffset in
                        servers.move(fromOffsets: indices, toOffset: newOffset)
                    })
                }header:{
                    HStack{
                        Label("使用中的服务器", systemImage: "cup.and.heat.waves")
                            .foregroundStyle(.primary, .green)
                        Spacer()
                        Text(verbatim: "\(servers.count)")
                    }
                   
                }
                
                
                Section{
                    
                    ForEach(cloudServers, id: \.id){ item in
                        
                        if !servers.contains(where: { $0.url == item.url && $0.key == item.key }){
                            ServerCardView(item: item,isCloud: true){
                                servers.append(item)
                                Task{
                                    _ = await manager.register(server: item)
                                }
                            }
                            .padding(.horizontal, 15)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive){
                                    if let index = cloudServers.firstIndex(where: {$0.id == item.id}){
                                        cloudServers.remove(at: index)
                                    }
                                }label:{
                                    Label("删除", systemImage: "trash")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    
                    
                }header: {
                    HStack{
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
            .refreshable { manager.registers(msg: true) }
            .toolbar{
            
                ToolbarItem {
                    withAnimation {
                        Button{
                            manager.fullPage = .customKey
                            manager.sheetPage = .none
                        }label:{
                            Image(systemName: "externaldrive.badge.plus")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle( Color.accentColor,Color.primary)
                                .accessibilityLabel("添加服务器")
                        }
                    }
                    
                }
                
                
                if showClose {
                    
                    ToolbarItem{
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.seal")
                                .accessibilityLabel("关闭")
                        }
                        
                    }
                }
            }
            .navigationTitle( "服务器")
            
    }
     
}

#Preview {
    ServersConfigView()
        .environmentObject(AppManager.shared)
}



