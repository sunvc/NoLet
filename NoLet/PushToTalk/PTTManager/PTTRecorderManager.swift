//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PTTRecorderManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/20 18:40.

import Accelerate
import AVFoundation
import Opus
import SwiftUI

nonisolated protocol PTTRecorderDelegate: AnyObject {
    /// 实时回调录音音量和已录制时长
    func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    )

    /// 麦克风权限状态变化
    func recorderManager(
        _ manager: PTTRecorderManager,
        didUpdateMicrophonePermission hasPermission: Bool
    )

    /// 每次采集到 PCM 帧时的实时回调——用于并行 WebSocket 逐帧 Opus 传输。
    /// 与 didUpdateRecordingPower 同一回调线程；实现方需自行避免长阻塞。
    func recorderManager(
        _ manager: PTTRecorderManager,
        didCaptureBuffer buffer: AVAudioPCMBuffer
    )

    /// Tokenized recorder lifecycle callbacks used by the unified audio FSM.
    func recorderManager(_ manager: PTTRecorderManager, didStartRecording id: UUID)
    func recorderManager(_ manager: PTTRecorderManager, recording id: UUID, didStopWith data: Data?)
    func recorderManager(_ manager: PTTRecorderManager, recording id: UUID, didFail error: String)
}

extension PTTRecorderDelegate {
    // Optional by default so existing tests / older delegates compile unchanged.
    func recorderManager(
        _ manager: PTTRecorderManager,
        didCaptureBuffer buffer: AVAudioPCMBuffer
    ) {}

    func recorderManager(_ manager: PTTRecorderManager, didStartRecording id: UUID) {}
    func recorderManager(_ manager: PTTRecorderManager, recording id: UUID, didStopWith data: Data?) {}
    func recorderManager(_ manager: PTTRecorderManager, recording id: UUID, didFail error: String) {}
}

final nonisolated class PTTRecorderManager {
    var delegate: PTTRecorderDelegate?

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    private var recordedAudioData = Data()
    private var oggWriter: OpusManager?
    private var activeRecordingID: UUID?

    // 跳过提示音的样本数
    private var skippedSamplesCount: UInt32 = 0
    private var hasMicrophonePermission: Bool = false
    private let packetSize = 1920

    func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            self.hasMicrophonePermission = granted
            logger.debug("Permesso microfono: \(granted ? "concesso" : "negato")")
            self.delegate?.recorderManager(self, didUpdateMicrophonePermission: granted)
        }
    }

    func setupAudio() {
        logger.debug("Inizializzazione sistema di registrazione...")
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else {
                logger.debug("ERROR: Inizializzazione audio engine di registrazione")
                return
            }

            let inputNode = audioEngine.inputNode
            self.inputNode = inputNode
            audioFormat = inputNode.outputFormat(forBus: 0)

            guard audioFormat != nil else {
                logger.debug("ERROR: Configurazione formato audio di registrazione")
                return
            }
            logger.debug("Sistema di registrazione inizializzato correttamente")
        } catch {
            logger.debug("Setup audio recording:\(error)")
        }
    }

    func startRecording(
        id: UUID,
        _ activity: Bool = true,
        pttMusicPlay: Bool
    ) {
        logger.debug("Avvio trasmissione audio...")
        activeRecordingID = id
        self.oggWriter = nil

        guard self.hasMicrophonePermission else {
            self.requestAudioPermission()
            delegate?.recorderManager(self, recording: id, didFail: "microphone permission unavailable")
            activeRecordingID = nil
            return
        }

        if let audioEngine = audioEngine, audioEngine.isRunning {
            inputNode?.removeTap(onBus: 0)
            audioEngine.stop()
        }

        setupAudio()

        self.delegate?.recorderManager(self, didUpdateRecordingPower: 0, duration: 0)

        guard let audioEngine = audioEngine, let inputNode = inputNode,
              let audioFormat = audioFormat
        else {
            return
        }

        do {
            oggWriter = try OpusManager(
                sampleRate: Int(audioFormat.sampleRate),
                bitrate:  32_000,
                application: .voip
            )

            recordedAudioData = Data()

            guard let oggWriter, audioFormat.sampleRate > 0, audioFormat.channelCount > 0 else {
                logger
                    .debug(
                        "Formato audio non valido: SR=\(audioFormat.sampleRate), CH=\(audioFormat.channelCount)"
                    )
                return
            }

            self.skippedSamplesCount = 0
            let targetSampleCount = UInt32(audioFormat.sampleRate * 0.26)

            inputNode
                .installTap(
                    onBus: 0,
                    bufferSize: 1024,
                    format: audioFormat
                ) { [weak self] buffer, _ in
                    guard let self = self else { return }

                    let elapsedTime = oggWriter.encodedDuration

                    // 切除提示音
                    if activity, pttMusicPlay, self.skippedSamplesCount < targetSampleCount {
                        self.skippedSamplesCount += buffer.frameLength
                        return
                    }

                    if elapsedTime > 60 { return }

                    try? oggWriter.append(buffer: buffer)

                    // 并行的实时路径：把同一份 PCM 交给 WS 发送流，
                    // 由 PTTStreamingSender 走 OpusRealtimeEncoder → 逐 20ms 帧。
                    self.delegate?.recorderManager(self, didCaptureBuffer: buffer)

                    let mic = self.calculateLevelPercentage(from: buffer)
                    self.delegate?.recorderManager(
                        self,
                        didUpdateRecordingPower: CGFloat(mic),
                        duration: elapsedTime
                    )
                }

            audioEngine.prepare()
            try audioEngine.start()
            logger.debug("Trasmissione audio avviata.")
            delegate?.recorderManager(self, didStartRecording: id)
        } catch {
            logger.error("\(error.localizedDescription)")
            _ = self.stopRecording(id: id, notify: false)
            delegate?.recorderManager(self, recording: id, didFail: error.localizedDescription)
        }
    }

    /// Compatibility wrapper used until every caller is tokenized.
    func startRecording(_ activity: Bool = true, pttMusicPlay: Bool) {
        startRecording(id: UUID(), activity, pttMusicPlay: pttMusicPlay)
    }

    @discardableResult
    func stopRecording(id: UUID, notify: Bool = true) -> Data? {
        logger.debug("Arresto trasmissione audio...")
        guard activeRecordingID == id else { return nil }
        activeRecordingID = nil

        guard let oggWriter, let audioEngine = audioEngine,
              let inputNode = inputNode else {
            if notify { delegate?.recorderManager(self, recording: id, didStopWith: nil) }
            return nil
        }

        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        self.inputNode = nil
        self.audioEngine = nil

        var result: Data?
        if let data = try? oggWriter.finish(), oggWriter.encodedDuration > 0.2 {
            result = data
        }
        self.oggWriter = nil
        logger.debug("Trasmissione audio arrestata.")
        if notify { delegate?.recorderManager(self, recording: id, didStopWith: result) }
        return result
    }

    func stopRecording() -> Data? {
        guard let id = activeRecordingID else { return nil }
        return stopRecording(id: id, notify: false)
    }

   
    @inline(__always)
    private func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Double {
        guard let samples = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(frameLength))
        guard rms > 0 else { return 0 }
        let decibels = 20 * log10f(rms)
        let minDb: Float = -80
        if decibels <= minDb { return 0 }
        let normalized = (decibels - minDb) * 0.0125
        let level = normalized * sqrtf(normalized)
        return Double(level)
    }
}
