//
//  PTTSessingsView.swift
//  NoLet
//
//  Created by lynn on 2025/7/28.
//

import Defaults
import SwiftUI

/// PTTSettingsView
///
///

struct PTTSettingsView: View {
    @ObservedObject var manager = PushTalkManager.shared
    @Environment(\.dismiss) var dismiss
    @Default(.eqBands) var eqBands

    @Default(.pttVibration) var pttVibration
    @Default(.pttMusicPlay) var pttMusicPlay

    @Default(.pttVoiceVolume) var pttVoiceVolume
    @Default(.pttSignature) var pttSignature
    @Default(.eqPreset) var eqPreset

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $pttSignature) {
                        Label {
                            Text("加密")
                        } icon: {
                            Image(systemName: "key.icloud")
                                .foregroundStyle(.green, .primary)
                        }
                    }
                }
                Section {
                    Toggle(isOn: $pttVibration) {
                        Label {
                            Text("震动")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundStyle(.primary, .green)
                        }
                    }

                    Toggle(isOn: $pttMusicPlay) {
                        Label {
                            Text("提示音")
                        } icon: {
                            Image(systemName: "speaker.zzz")
                                .foregroundStyle(.primary, .green)
                        }
                    }
                }

                Section {
                    Slider(value: $pttVoiceVolume, in: 0...1) {
                        Label {
                            Text("音量")
                        } icon: {
                            Image(systemName: "speaker.wave.2.circle")
                        }
                    }

                } header: {
                    Text("播放音量")
                }

                equalizerView
            }
            .navigationTitle("PTT设置")
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                        
                        AppManager.shared.page = .message
                        if AppManager.shared.sizeClass == .regular {
                            AppManager.shared.homeViewMode = .all
                        }
                        
                        Haptic.impact()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)

                    }.buttonStyle(.borderless)
                }
            }
        }
    }

    private var equalizerView: some View {
        Section {
            EQSliderView()
                .frame(height: 180)
                .padding(.vertical, 10)

            EQGlobalGainSlider()

        } header: {
            HStack {
                Text("音效调整器")
                Spacer()
                Picker(selection: $eqPreset) {
                    ForEach(EqualizerPreset.allCases, id: \.self) { item in
                        Label {
                            Text(item.displayName)
                                .tag(item)
                        } icon: {
                            Image(systemName: item.iconName)
                        }
                    }
                } label: { Text("切换服务器") }
                    .pickerStyle(MenuPickerStyle())
                    .offset(x: 10)
                    .onChange(of: eqBands) { _ in
                        manager.changeEQ()
                    }
            }
        }
        .listSectionSeparator(.hidden)
    }
}
