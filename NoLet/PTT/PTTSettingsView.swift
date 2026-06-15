//
//  PTTSessingsView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import SwiftUI
import Defaults

struct PTTSettingsView: View {
   
    @Default(.pttVibration) var pttVibration
    @Default(.pttMusicPlay) var pttMusicPlay

    @Default(.pttVoiceVolume) var pttVoiceVolume
    @Default(.pttSignature) var pttSignature
    
    var body: some View {
        NavigationStack{
            List { 
                Section{
                    Toggle(isOn: $pttSignature) { 
                        Label { 
                            Text("加密")
                        } icon: { 
                            Image(systemName: "key.icloud")
                                .foregroundStyle(.green, .primary)
                        }
                    }
                }
                Section{
                    Toggle(isOn: $pttVibration) { 
                        Label { 
                            Text("震动")
                        } icon: { 
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundStyle( .primary, .green)
                        }
                    }
                    
                    Toggle(isOn: $pttMusicPlay) { 
                        Label { 
                            Text("提示音")
                        } icon: { 
                            Image(systemName: "speaker.zzz")
                                .foregroundStyle( .primary, .green)
                        }
                    }
                }
                
                Section{
                    
                    Slider(value: $pttVoiceVolume, in: 0...1) { 
                        Label { 
                            Text("音量")
                        } icon: { 
                            Image(systemName: "speaker.wave.2.circle")
                        }
                    }
                    
                }header: {
                    Text("播放音量")
                }
            }
            .navigationTitle("PTT设置")
        }
    }
}
