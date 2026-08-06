//
//  MusicInfo.swift
//  AppleMusicBottomSheet
//
//  Created by Balaji on 18/03/23.
//

import SwiftUI

/// Resuable File
struct MusicInfo: View {
    @ObservedObject private var audioManager = AudioManager.shared
    @State private var progress: CGFloat = 0
    @State private var duration: TimeInterval = 0

    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying: Bool = false
    @State private var onActive: Bool = false

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation {
                        if let player = audioManager.speakPlayer {
                            if isPlaying {
                                player.pause()
                            } else {
                                player.play()
                            }
                        }
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
            }
            .frame(minWidth: 50)
            .disabled(audioManager.loading)

            /// Adding Matched Geometry Effect (Hero Animation)
            VStack {
                if let player = audioManager.speakPlayer, let audio = player.url {
                    WaveformScrubber(url: audio, progress: $progress, info: { info in
                        self.duration = info.duration
                    }, onGestureActive: { active in
                        onActive = active
                        player.currentTime = duration * progress
                    })
                } else {
                    HandlerOverlay()
                        .frame(minHeight: 60)
                }
            }
            .padding(.horizontal, 10)

            HStack {
                Button {
                    withAnimation {
                        audioManager.speakPlayer?.stop()
                        audioManager.speaking.toggle()
                    }

                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
            }
            .frame(minWidth: 50)
            .disabled(audioManager.loading)
        }
        .foregroundColor(.primary)
        .overlay(alignment: .top){
            HStack{
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 10)
        }
        .padding(.horizontal)
        .padding(.top, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onReceive(timer) { _ in
            if let player = audioManager.speakPlayer {
                currentTime = player.currentTime
                if !onActive {
                    progress = currentTime / duration
                }
                self.isPlaying = player.isPlaying
            }
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func safeFrameWidth(progress: CGFloat, width: CGFloat) -> CGFloat {
        guard progress.isFinite, width.isFinite, width > 0 else { return 0.1 }
        let value = abs(progress * width)
        return min(max(value, 0.1), width)
    }

    fileprivate struct HandlerOverlay: View {
        @State private var progress: Double = 0
        private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

        var body: some View {
            ProgressView(value: progress, total: 100)
                .progressViewStyle(.linear)
                .tint(.white)
                .frame(width: 180)
                .transition(.opacity)
                .onReceive(timer) { _ in
                    guard progress < 80 else { return }
                    progress = min(80, progress + Double.random(in: 3...10))
                }
        }
    }
}
