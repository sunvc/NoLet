//
//  SoundItemView.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import SwiftUI
import AVKit
import Defaults



struct SoundItemView: View {
    @EnvironmentObject private var audioManager:AudioManager
	@Default(.sound) var sound

	var audio:URL
	var fileName:String?
	
    @State var duration:Double = 0.0
	@State private var title:String?
    
	var name:String{
		audio.deletingPathExtension().lastPathComponent
	}
    
    var selectSound:Bool{
		sound == audio.deletingPathExtension().lastPathComponent
    }
    
    @State private var progress:CGFloat = 0
	
    var wavConfig:WaveformScrubber.Config{
        selectSound ? .init(activeTint: Color.accentColor) : .init(activeTint: .textBlack)
    }

    var body: some View{
        HStack{
            
            HStack{
                
                VStack(alignment: .leading){
                    Text( name)
                        .foregroundStyle(selectSound ? Color.green :  Color.textBlack)
                    Text(verbatim: "\(formatDuration(duration))s")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                WaveformScrubber(config: wavConfig, url: audio, progress: Binding(get: {progress}, set: {_ in}))
                    .disabled(true)
                    .scaleEffect(0.8)
                    .onChange(of: selectSound) { value  in
                        progress = selectSound ? 1 : 0
                    }
                    .onAppear{
                        withAnimation {
                            progress = selectSound ? 1 : 0
                        }
                        
                    }
                
            }
            .diff{view in
                Group{
                    if #available(iOS 26.0, *){
                        view
                            .onTapGesture {
                                playAudio()
                                Haptic.impact()
                            }
                    }else{
                        view
                            .VButton(onRelease:{ _ in
                                playAudio()
                                return true
                            })
                    }
                }

            }

            
            
            
           
            
            
            Spacer(minLength: 0)
            if duration <= 30{
                Image(systemName: "doc.on.doc")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .tint, Color.primary)
                    .onTapGesture {
                        Clipboard.set(self.name)
                        Toast.copy(title: "复制成功")
                        Haptic.impact()
                    }

            }else{
                Text("长度不能超过30秒")
                    .foregroundStyle(.red)
            }
            
        }
        .swipeActions(edge: .leading) {
            Button {
                sound = audio.deletingPathExtension().lastPathComponent
                audioManager.playAudio(url: audio)
            } label: {
                Text("设置")
                    .accessibilityLabel("设置默认铃声")
            }.tint(.green)
        }
        .task {
            do {
                self.duration =  try await loadVideoDuration(fromURL: self.audio)
            } catch {
#if DEBUG
                NLog.error("Error loading aideo duration: \(error.localizedDescription)")
#endif
                
            }
        }

        .accessibilityElement(children: .ignore)
        .accessibilityLabel("铃声" + name)
        .accessibilityAction(named: "复制") {
            Clipboard.set(self.name)
            Toast.copy(title: "复制成功")
            Haptic.impact()
        }
        .accessibilityAction(named: "播放铃声") {
            playAudio()
        }

        
    }

    func playAudio(){
        self.progress = 0
        DispatchQueue.main.async{
            withAnimation(.easeInOut(duration: duration )) {
                self.progress = 1
            }

            audioManager.playAudio(url: audio)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1){
                self.progress = selectSound ? 1 : 0
            }
        }
    }

	
}

extension SoundItemView{
	// 定义一个异步函数来加载audio的持续时间
	func loadVideoDuration(fromURL audioURL: URL) async throws -> Double {
		return try AVAudioPlayer(contentsOf: audioURL).duration
    }
    
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: duration)) ?? ""
    }
    
}






#Preview{
    SettingsPage()
		.environmentObject(AppManager.shared)
}
