//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PTTPlayerManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  Created by Neo on 2026/6/20 18:38.
//

import AVFoundation
import Defaults
import os
import SwiftUI

nonisolated protocol PTTPlayerDelegate: AnyObject, Sendable {
    /// Legacy/UI progress callback. Kept while views migrate to the unified FSM.
    func playerManager(
        _ manager: PTTPlayerManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    )

    /// Tokenized callbacks consumed by PTTManager's audio mailbox. The default
    /// implementations keep older delegates source-compatible.
    func playerManager(
        _ manager: PTTPlayerManager,
        didStart id: UUID,
        generation: UInt64,
        duration: TimeInterval
    )
    func playerManager(
        _ manager: PTTPlayerManager,
        didFinish id: UUID,
        generation: UInt64
    )
    func playerManager(
        _ manager: PTTPlayerManager,
        didFail id: UUID,
        generation: UInt64,
        error: String
    )
}

nonisolated extension PTTPlayerDelegate {
    func playerManager(
        _ manager: PTTPlayerManager,
        didStart id: UUID,
        generation: UInt64,
        duration: TimeInterval
    ) {}

    func playerManager(
        _ manager: PTTPlayerManager,
        didFinish id: UUID,
        generation: UInt64
    ) {}

    func playerManager(
        _ manager: PTTPlayerManager,
        didFail id: UUID,
        generation: UInt64,
        error: String
    ) {}
}

actor PTTPlayerManager: Sendable {
    private enum Lifecycle {
        case idle
        case preparing
        case playing
        case paused
    }

    var delegate: PTTPlayerDelegate?

    private var playbackAudioEngine: AVAudioEngine?
    private var playbackPlayerNode: AVAudioPlayerNode?
    private var audioUnitEQ: AVAudioUnitEQ?
    private var timer: DispatchSourceTimer?
    private var audioFile: AVAudioFile?

    private var activeID: UUID?
    private var activeGeneration: UInt64 = 0
    private var duration: TimeInterval = 0
    private var lifecycle: Lifecycle = .idle

    func setDelegate(_ delegate: PTTPlayerDelegate?) {
        self.delegate = delegate
    }

    var currentPlaybackTime: Double {
        guard let playerNode = playbackPlayerNode else { return 0 }
        guard let engine = playerNode.engine, engine.isRunning else { return 0 }
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return 0 }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    private func startTimer(total: Double, id: UUID, generation: UInt64) {
        cancelTimer(resetProgress: false)
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            Task {
                guard await self.matches(id: id, generation: generation) else { return }
                let elapsed = await max(self.currentPlaybackTime, 0)
                await self.delegate?.playerManager(
                    self,
                    didUpdateCurrentTime: elapsed,
                    duration: total
                )
            }
        }
        timer.resume()
        self.timer = timer
    }

    private func cancelTimer(resetProgress: Bool) {
        if resetProgress {
            delegate?.playerManager(self, didUpdateCurrentTime: 0, duration: 0)
        }
        timer?.cancel()
        timer = nil
    }

    func setVolume(_ value: Float? = nil) {
        if let value {
            playbackPlayerNode?.volume = value
        } else {
            playbackPlayerNode?.volume = Float(Defaults[.pttVoiceVolume])
        }
    }

    /// Tokenized local playback entry. It owns exactly one engine/node graph.
    /// Pausing keeps the graph and scheduled file alive; resuming calls play()
    /// on that same node, preserving the sample position.
    func playAudio(
        _ filePath: URL,
        id: UUID,
        generation: UInt64
    ) async {
        stopInternal(resetProgress: false)
        activeID = id
        activeGeneration = generation
        lifecycle = .preparing

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        playbackAudioEngine = engine
        playbackPlayerNode = playerNode

        do {
            let file = try AVAudioFile(forReading: filePath)
            audioFile = file
            duration = Double(file.length) / file.processingFormat.sampleRate

            // Use the source processing format between player and EQ/mixer.
            // AVAudioEngine performs any final hardware conversion downstream.
            let format = file.processingFormat
            engine.attach(playerNode)
            eqAttach(
                to: engine,
                bands: Defaults[.eqBands],
                globalGain: Defaults[.globalGain]
            )
            if let eq = audioUnitEQ {
                engine.connect(playerNode, to: eq, format: format)
                engine.connect(eq, to: engine.mainMixerNode, format: format)
            } else {
                engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            }

            setVolume()
            try engine.start()
            startTimer(total: duration, id: id, generation: generation)

            lifecycle = .playing
            delegate?.playerManager(
                self,
                didStart: id,
                generation: generation,
                duration: duration
            )
            playerNode.play()

            await playerNode.scheduleFile(
                file,
                at: nil,
                completionCallbackType: .dataPlayedBack
            )

            // stop/pause/replacement can make this completion stale. Only the
            // matching active generation is allowed to terminate the FSM node.
            guard matches(id: id, generation: generation), lifecycle != .idle else {
                return
            }
            delegate?.playerManager(self, didFinish: id, generation: generation)
            stopInternal(resetProgress: true)
        } catch {
            guard matches(id: id, generation: generation) else { return }
            delegate?.playerManager(
                self,
                didFail: id,
                generation: generation,
                error: error.localizedDescription
            )
            stopInternal(resetProgress: true)
        }
    }

    /// Compatibility entry used by any call sites not yet migrated. The
    /// coordinator path always supplies an explicit id/generation.
    func playAudio(_ filePath: URL) async {
        await playAudio(filePath, id: UUID(), generation: activeGeneration &+ 1)
    }

    func pause(id: UUID) {
        guard activeID == id, lifecycle == .playing else { return }
        playbackPlayerNode?.pause()
        lifecycle = .paused
        // Keep the timer alive: playerTime stays frozen, so UI progress remains
        // stable without a special reset/restart path.
    }

    func resume(id: UUID) {
        guard activeID == id, lifecycle == .paused else { return }
        do {
            if playbackAudioEngine?.isRunning == false {
                try playbackAudioEngine?.start()
            }
            playbackPlayerNode?.play()
            lifecycle = .playing
        } catch {
            delegate?.playerManager(
                self,
                didFail: id,
                generation: activeGeneration,
                error: error.localizedDescription
            )
            stopInternal(resetProgress: true)
        }
    }

    func stop(id: UUID) {
        guard activeID == id else { return }
        stopInternal(resetProgress: true)
    }

    func stopPlay() {
        stopInternal(resetProgress: true)
    }

    private func matches(id: UUID, generation: UInt64) -> Bool {
        activeID == id && activeGeneration == generation
    }

    private func stopInternal(resetProgress: Bool) {
        // Invalidate before touching the node: a dataPlayedBack callback may
        // arrive synchronously as stop() flushes the schedule.
        lifecycle = .idle
        activeID = nil
        activeGeneration &+= 1
        cancelTimer(resetProgress: resetProgress)
        playbackPlayerNode?.stop()
        playbackAudioEngine?.stop()
        playbackAudioEngine = nil
        playbackPlayerNode = nil
        audioUnitEQ = nil
        audioFile = nil
        duration = 0
    }

    private func eqAttach(to engine: AVAudioEngine, bands: [EQBand], globalGain: Double) {
        let eq = AVAudioUnitEQ(numberOfBands: EqualizerPreset.bandFrequencies.count)
        audioUnitEQ = eq
        changeEQ(bands: bands, globalGain: Float(globalGain))
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
