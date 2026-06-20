//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PTTPlayerManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/20 18:38.

import AVFoundation
import os
import SwiftUI

nonisolated protocol PTTPlayerDelegate: AnyObject {
    /// 实时回调播放进度
    func playerManager(
        _ manager: PTTPlayerManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    )
}

final nonisolated class PTTPlayerManager: @unchecked Sendable {
    var delegate: PTTPlayerDelegate?

    private var playbackAudioEngine: AVAudioEngine?
    private var playbackPlayerNode: AVAudioPlayerNode?
    private(set) var audioUnitEQ: AVAudioUnitEQ?
    private var timer: DispatchSourceTimer?

    var currentPlaybackTime: Double {
        guard let playerNode = playbackPlayerNode else { return 0 }
        guard let engine = playerNode.engine, engine.isRunning else { return 0 }
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return 0 }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    func startTimer(total: Double) {
        stopTimer()
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.delegate?.playerManager(
                self,
                didUpdateCurrentTime: max(self.currentPlaybackTime, 0),
                duration: total
            )
        }
        timer.resume()
        self.timer = timer
    }

    private func stopTimer() {
        self.delegate?.playerManager(self, didUpdateCurrentTime: 0, duration: 0)
        timer?.cancel()
        timer = nil
    }

    func setVolume(_ value: Float? = nil) {
        if let value {
            playbackPlayerNode?.volume = value
        } else {
            Task {
                let volume = await Defaults[.pttVoiceVolume]
                playbackPlayerNode?.volume = Float(volume)
            }
        }
    }

    func playAudio(_ filePath: URL) async {
        
        playbackAudioEngine = AVAudioEngine()
        playbackPlayerNode = AVAudioPlayerNode()

        guard let audioEngine = playbackAudioEngine, let playerNode = playbackPlayerNode else {
            logger.debug("ERROR: Inizializzazione playback")
            return
        }

        do {
            guard let audioFile = try? AVAudioFile(forReading: filePath) else { return }
            let hardwareFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)

            print("sampleRate: ", audioFile.processingFormat.sampleRate)
            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate

            self.startTimer(total: duration)
            audioEngine.attach(playerNode)

            self.eqAttach(
                to: audioEngine,
                bands: Defaults[.eqBands],
                globalGain: Defaults[.globalGain]
            )

            if let eq = self.audioUnitEQ {
                audioEngine.connect(playerNode, to: eq, format: hardwareFormat)
                audioEngine.connect(eq, to: audioEngine.mainMixerNode, format: hardwareFormat)
            } else {
                audioEngine.connect(
                    playerNode,
                    to: audioEngine.mainMixerNode,
                    format: hardwareFormat
                )
            }

            self.setVolume()
            try audioEngine.start()

            playerNode.play()

            _ = await playerNode.scheduleFile(
                audioFile,
                at: nil,
                completionCallbackType: .dataPlayedBack
            )

            logger.debug("Avviata riproduzione audio PCM.")
            self.stopPlay()

        } catch {
            logger.debug("ERROR: Riproduzione audio PCM - \(error)")
            self.stopPlay()
        }
    }


    func stopPlay() {
        playbackPlayerNode?.stop()
        playbackAudioEngine?.stop()
        playbackAudioEngine = nil
        playbackPlayerNode = nil
        audioUnitEQ = nil
        self.stopTimer()
    }

    private func eqAttach(to engine: AVAudioEngine, bands: [EQBand], globalGain: Double) {
        let eq = AVAudioUnitEQ(numberOfBands: EqualizerPreset.bandFrequencies.count)
        self.audioUnitEQ = eq
        self.changeEQ(bands: bands, globalGain: Float(globalGain))
        engine.attach(eq)
    }

    func changeEQ(bands: [EQBand], globalGain: Float = 0) {
        guard let eq = audioUnitEQ else { return }
        eq.globalGain = globalGain
        for (index, frequency) in EqualizerPreset.bandFrequencies.enumerated() {
            let eqBands = eq.bands[index]
            eqBands.filterType = .parametric
            eqBands.frequency = frequency
            eqBands.bandwidth = 2.5
            eqBands.bypass = false
            eqBands.gain = bands[index].value
        }
    }
}
