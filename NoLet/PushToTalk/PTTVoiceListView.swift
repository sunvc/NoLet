//
//  PTTVoiceListView.swift
//  pushme
//
//  Created by lynn on 2025/7/28.
//

import SwiftUI
import AVFoundation
import Defaults

struct PTTVoiceListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var pttManager = PushTalkManager.shared
    @Default(.id) var id
    var body: some View {
        VStack{
            HStack(spacing: 0){
                Menu {
                    Button{
                        
                    }label: {
                        Label("删除所有", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "trash")
                }

                
                Spacer(minLength: 0)
                Text("消息列表")
                    .font(.title3)
                Spacer(minLength: 0)
                Image(systemName: "xmark")
                    .imageScale(.large)
                    .padding(5)
                    .VButton { _ in
                        self.dismiss()
                        return true
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.background)
            
            List{
                ForEach(pttManager.messages, id: \.id){ item in
                    Section{
                        HStack{
                            if id != item.from{
                                Spacer(minLength: 0)
                            }
                            VoiceCard(message: item, manager: pttManager)
                            
                            if id == item.from{
                                Spacer(minLength: 0)
                            }
                        }
                        
                    }header: {
                        HStack{
                            Text(item.timestamp.formatString())
                                .foregroundStyle(.gray)
                                .font(.headline)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 25)
                        .padding(.top, 10)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                
            }
            .listStyle(.grouped)
            
        }.environment(\.colorScheme, .dark)
    }
}

struct VoiceCard: View {
    var message: PttMessageModel
    @ObservedObject var manager: PushTalkManager
    @State private var duration: Double = 0
    
    var progress: Double {
        if manager.currentPlay == message{
            return manager.micLevel / max(duration, 0.1)
        }
        return 0
    }
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            HStack{
                Image(systemName: "dot.radiowaves.right")
                    .font(.title)
                    .symbolEffect(progress == 0 ? .none : .variableColor)
                    .padding(.leading, 10)
                
                Spacer(minLength: 0)
                
                Text("\(String(format: "%.1f", duration))″")
                    .font(.headline)

                Spacer(minLength: 0)
            }
            .fontWeight(.black)
            .frame(height: size.height)
            .frame(width: calc(size.width))
            .background(
                GeometryReader {
                    let size = $0.size
                    ZStack(alignment: .leading){
                        Rectangle()
                            .fill(Color.gray.opacity(0.9))
                        
                        Rectangle()
                            .fill(Color.accent)
                            .frame(width: size.width * progress)
                        
                    }.clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )
                }
            )
            .animation(.default, value: progress)
            .VButton { _ in
                manager.play(file: message)
                return true
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
        .onAppear{  self.getDuration() }
        
    }
    
    func getDuration() {
        Task{
            guard let filePath = message.filePath() else { return }
            let asset = AVURLAsset(url: filePath)
            let duration = try await asset.load(.duration)
            self.duration = CMTimeGetSeconds(duration)
        }
    }
    
    func calc(_ width: CGFloat) -> CGFloat{
        let minW = width * 0.3
        let wet:CGFloat = min(60 , duration + 10)
        return min(max(width / wet * duration, minW), width * 0.7)
    }
}


#Preview {
    PushToTalkView()
}
