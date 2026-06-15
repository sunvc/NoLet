//
//  PTTChannelListView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import SwiftUI
import Defaults

struct PTTChannelListView: View {
    
    var complete: (PTTChannel) -> Bool
    
    @Environment(\.dismiss) var dismiss
    
    @Default(.pttHisChannel) var pttHisChannel
    @Default(.pttChannel) var pttChannel
    @Default(.servers) var servers
    
    var channels:[PTTChannel]{
        pttHisChannel.sorted(by: {  $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        NavigationStack{
            
            List{
                ForEach(channels, id: \.id) { item in
                    Section{
                        HStack{
                            Image(systemName: "speaker.wave.2.bubble")
                                .foregroundStyle(item == pttChannel ? .green : .orange)
                            Text("频道:")
                                .scaleEffect(0.9)
                                .foregroundStyle(.gray)
                            HStack(spacing: 0){
                                Text(verbatim: "\(item.prefix)")
                                Text(verbatim: ".")
                                Text(verbatim: "\(item.suffix)")
                                
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
                        
//                        .VButton{ _ in
//                            return complete(item)
//                        }
                        .padding(.horizontal)
                        .swipeActions(allowsFullSwipe: true) {
                            Button{
                                pttHisChannel.removeAll(where: {$0 == item})
                                if pttHisChannel.count == 0{
                                    self.dismiss()
                                }
                            }label:{
                                Label("删除", systemImage: "trash")
                            }.tint(.red)
                        }
                        
                    }header:{
                        HStack{
                            Text(verbatim: "\(item.timestamp.agoFormatString())")
                                .padding(.leading)
                            Spacer()
                            if let server = item.server{
                                Text(verbatim: "\(server.name)")
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
                ToolbarItem{
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
        .onAppear{
            var pttHisArr:[PTTChannel] = []
            for channel in pttHisChannel{
                if let server = channel.server, servers.contains(server){
                    pttHisArr.append(channel)
                }
            }
            
            if pttHisArr.count != pttHisChannel.count{
                pttHisChannel = pttHisArr
            }
            
        }
    }
}


#Preview {
    PushToTalkView()
}
