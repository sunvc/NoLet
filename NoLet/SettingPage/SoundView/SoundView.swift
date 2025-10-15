//
//  SoundView.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import SwiftUI
import AVFoundation
import UIKit

struct SoundView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioManager = AudioManager.shared
    @EnvironmentObject private var manager:AppManager
    @State private var showUpload:Bool = false
    
    @State private var uploadLoading:Bool = false


    var body: some View {
        List {
            
            Section {
                HStack{
                    Spacer()
                    Button {
                        self.showUpload.toggle()
                    } label: {
                        
                        
                        Label("上传铃声", systemImage: "waveform" )
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint)
                            .symbolEffect(.replace)
                            .symbolEffect(.variableColor, delay: 1)
                            .if(uploadLoading){ view in
                                HStack{
                                    Spacer()
                                    ProgressView()
                                    Text("正在处理中...")
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background26(.ultraThinMaterial,radius: 20)
                    }
                    .disabled(uploadLoading)
                    ///  UTType.types(tag: "caf", tagClass: UTTagClass.filenameExtension,conformingTo: nil)
                    .fileImporter(isPresented: $showUpload, allowedContentTypes: [.audio] ) { result in
                        self.uploadLoading = true
                        switch result{
                        case .success(let file):

                            Task.detached{
                                
                                defer {
                                    file.stopAccessingSecurityScopedResource()
                                }
                                
                                if file.startAccessingSecurityScopedResource() {
                                    
                                    if let url = await audioManager.convertAudioToCAF(inputURL: file){
                                        await audioManager.saveSound(url: url)
                                    }else{
                                        Toast.error(title: "导出失败")
                                    }
                                    try? await Task.sleep(for: .seconds(0.5))
                                    await MainActor.run{
                                        self.uploadLoading = false
                                    }
                                }
                                
                            }
                            
                        case .failure(let err):
                            NLog.log(err)
                            self.uploadLoading = false
                            Toast.shared.present(title: err.localizedDescription, symbol: .error)
                        }
                    }
                    
                    Spacer()
                }
            }header: {
                Spacer()
            }footer: {
                HStack{
                    Text( "选择铃声，超出30秒的将截断")
                }
            }.listRowBackground(Color.clear)


            if audioManager.customSounds.count > 0{
                Section{
                    
                    ForEach(audioManager.customSounds, id: \.self) { url in
                        SoundItemView(audio: url)

                    }.onDelete { indexSet in
                        for index in indexSet{
                            audioManager.deleteSound(url: audioManager.customSounds[index])
                        }
                    }
                    .environmentObject(audioManager)
                }header: {
                    Text(  "自定义铃声")
                }
            }
            
            
            Section{
                ForEach(audioManager.defaultSounds, id: \.self) { url in
                    SoundItemView(audio: url)

                } .environmentObject(audioManager)
            }header: {
                Text(  "自带铃声")
            }
            
            
        }
        .navigationTitle("所有铃声")
        .toolbar{
            ToolbarItem(placement: .topBarTrailing) {
               
                Image(systemName: "speaker.zzz")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.tint, .primary)
                    .VButton(onRelease: { _ in
                        manager.router.append(.tts)
                        return true
                    })
                    .accessibilityLabel("语音朗读设置")
            }
        }
        .onDisappear{
            audioManager.playAudio(url: nil)
        }
    }
    
    
    
    
    
    
    
}

#Preview {
    SoundView()
        .environmentObject(AppManager.shared)
    
}

