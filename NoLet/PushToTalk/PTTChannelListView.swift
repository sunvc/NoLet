//
//  PTTChannelListView.swift
//  pushme
//
//  Created by lynn on 2025/7/28.
//

import SwiftUI
import Defaults

struct PTTChannelListView: View {
    
    var complete: (PTTChannel) -> Bool
    
    @Environment(\.dismiss) var dismiss
    
    @Default(.pttHisChannel) var pttHisChannel
    @Default(.servers) var servers
    
    var channels:[PTTChannel]{
        pttHisChannel.sorted(by: {  $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        VStack{
            HStack(spacing: 0){
                Text("历史频道")
                    .font(.title2)
                Spacer(minLength: 0)
                Image(systemName: "xmark")
                    .imageScale(.large)
                    .padding(10)
                    .onTapGesture {
                        self.dismiss()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.background)
            List{
                ForEach(channels, id: \.id) { item in
                    Section{
                        HStack{
                            Image(systemName: "speaker.wave.2.bubble")
                                .foregroundStyle(item.isActive ? .green : .orange)
                            Text("频道:")
                                .scaleEffect(0.9)
                                .foregroundStyle(.gray)
                            HStack(spacing: 0){
                                Text(verbatim: "\(item.prefix)")
                                Text(verbatim: ".")
                                Text(verbatim: "\(item.suffix)")
                                
                            }.font(.numberStyle(size: 28))
                            
                            if !item.password.isEmpty{
                                HStack(spacing: 0){
                                    Text(verbatim: "KEY:")
                                        .scaleEffect(0.9)
                                        .foregroundStyle(.gray)
                                    Text(item.password)
                                        .font(.title3)
                                }
                            }
                            Spacer(minLength: 0)
                            Text("选择")
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
                        .VButton{ _ in
                            return complete(item)
                        }
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
                            Text("\(item.timestamp.agoFormatString())")
                                .padding(.leading)
                            Spacer()
                            if let server = item.server{
                                Text("\(server.name)")
                                    .padding(.trailing)
                                    .textCase(.lowercase)
                            }
                        }
                    }
                    
                }
            }.listStyle(.grouped)
            
        }
        .environment(\.colorScheme, .dark)
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
