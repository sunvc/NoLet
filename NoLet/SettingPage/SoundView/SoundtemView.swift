//
//  SoundtemView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo 2024/8/9.
//

import AVKit
import Defaults
import SwiftUI

struct SoundItemView: View {
    @ObservedObject var tipsManager: AudioManager
    @Default(.sound) var sound

    var audio: URL
    var fileName: String?

    @State var duration: Double = 0.0
    @State private var title: String?

    var name: String {
        audio.deletingPathExtension().lastPathComponent
    }

    var defaultSound: Bool {
        sound == audio.deletingPathExtension().lastPathComponent
    }

    var progress: CGFloat {
        if audio == tipsManager.currentURL {
            return tipsManager.currentTime / tipsManager.duration
        }
        return 0.0
    }

    var body: some View {
        HStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .foregroundStyle(defaultSound ? Color.green : Color.textBlack)
                    Text(verbatim: "\(tipsManager.formatDuration(duration))s")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                WaveformScrubber(
                    config: defaultSound ? .init(activeTint: Color.accentColor) :
                        .init(activeTint: .textBlack),
                    url: audio,
                    progress: Binding(get: { progress }, set: { value in
                        tipsManager.seek(to: value * tipsManager.duration)
                    })
                )
                .scaleEffect(0.8)
                .disabled(progress == 0.0)
            }
            .diff { view in
                Group {
                    if #available(iOS 26.0, *) {
                        view
                            .onTapGesture {
                                playAudio()
                                Haptic.impact()
                            }
                    } else {
                        view
                            .VButton(onRelease: { _ in
                                playAudio()
                                return true
                            })
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "doc.on.doc")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.tint, Color.primary)
                .onTapGesture {
                    Clipboard.set(self.name)
                    Toast.copy(title: "复制成功")
                    Haptic.impact()
                }
        }
        .swipeActions(edge: .leading) {
            Button {
                sound = audio.deletingPathExtension().lastPathComponent
            } label: {
                Text("设置")
                    .accessibilityLabel("设置默认铃声")
            }.tint(.green)
        }
        .task {
            do {
                self.duration = try await tipsManager.loadVideoDuration(fromURL: self.audio)
            } catch {
                #if DEBUG
                logger.fault("Error loading aideo duration: \(error)")
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

    func playAudio() {
        tipsManager.togglePlay(url: audio)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
