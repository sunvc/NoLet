//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AudioHandler.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/9 08:00.

import AVFoundation
import Defaults
import Foundation
import Opus

nonisolated protocol AudioHardwareDelegate: AnyObject {
    /// 实时回调播放进度
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateCurrentTime currentTime: TimeInterval,
        duration: TimeInterval
    )

    /// 实时回调录音音量和已录制时长 👈 【修改这里】
    /// - Parameters:
    ///   - power: 平均分贝值
    ///   - duration: 当前已录制的总时长（秒数）
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateRecordingPower power: CGFloat,
        duration: TimeInterval
    )

    /// 麦克风权限状态变化
    func audioManager(
        _ manager: CombinedAudioManager,
        didUpdateMicrophonePermission hasPermission: Bool
    )
}

final nonisolated class CombinedAudioManager: @unchecked Sendable {
    var delegate: AudioHardwareDelegate?
    /// walkie-talkie
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    private var recordedAudioData = Data()
    private var oggWriter = OggOpusWriter()
    private var dataItem = DataItem()
    private var timer: DispatchSourceTimer?
    // 跳过提示音的样本数
    private var skippedSamplesCount: UInt32 = 0
    // play
    private var playbackAudioEngine: AVAudioEngine?
    private var playbackPlayerNode: AVAudioPlayerNode?
    private(set) var audioUnitEQ: AVAudioUnitEQ?

    private var hasMicrophonePermission: Bool = false

    var currentPlaybackTime: Double {
        // 1. 安全守护：拿到 playerNode
        guard let playerNode = playbackPlayerNode else { return 0 }

        // 2. 核心修复：检查当前节点是否依然和有效的引擎绑定，且引擎正在运行
        // 如果引擎已经 stop 或者节点被 detach，直接安全返回 0
        guard let engine = playerNode.engine, engine.isRunning else {
            return 0
        }

        // 3. 此时访问 lastRenderTime 才是绝对安全的
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else {
            return 0
        }

        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    func startTimer(total: Double) {
        stopTimer()

        let timer = DispatchSource.makeTimerSource()

        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(100)
        )

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }

            self.delegate?.audioManager(
                self,
                didUpdateCurrentTime: self.currentPlaybackTime,
                duration: total
            )
        }

        timer.resume()

        self.timer = timer
    }

    private func stopTimer() {
        self.delegate?.audioManager(self, didUpdateCurrentTime: 0, duration: 0)
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

    func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            self.hasMicrophonePermission = granted
            logger.debug("Permesso microfono: \(granted ? "concesso" : "negato")")
            self.delegate?.audioManager(self, didUpdateMicrophonePermission: granted)
        }
    }

    func setupAudio() {
        logger.debug("Inizializzazione sistema audio...")

        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )

            try audioSession.setPreferredSampleRate(48000.0)
            try audioSession.setPreferredIOBufferDuration(0.06)

            try audioSession.setActive(true)
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else {
                logger.debug("ERROR:  Inizializzazione audio engine")
                return
            }

            // Configura input node
            let inputNode = audioEngine.inputNode
            self.inputNode = inputNode

            // Usa il formato nativo dell'input node direttamente
            let nativeFormat = inputNode.outputFormat(forBus: 0)

            // Usa il formato nativo per evitare problemi di conversione
            audioFormat = nativeFormat

            guard audioFormat != nil else {
                logger.debug("ERROR: Configurazione formato audio")
                return
            }

            logger.debug("Sistema audio inizializzato correttamente")

        } catch {
            logger.debug("Setup audio:\(error)")
        }
    }

    func startRecording(_ activity: Bool = true, pttMusicPlay: Bool) {
        logger.debug("Avvio trasmissione audio...")

        guard self.hasMicrophonePermission else {
            self.requestAudioPermission()
            return
        }

        // Ferma e resetta l'audio engine se già attivo
        if let audioEngine = audioEngine, audioEngine.isRunning {
            inputNode?.removeTap(onBus: 0)
            audioEngine.stop()
        }

        setupAudio()

        self.delegate?.audioManager(
            self,
            didUpdateRecordingPower: 0,
            duration: 0
        )

        guard let audioEngine = audioEngine, let inputNode = inputNode,
              let audioFormat = audioFormat
        else {
            return
        }

        do {
            oggWriter = OggOpusWriter()
            dataItem = DataItem()
            oggWriter.inputSampleRate = Int32(audioFormat.sampleRate)
            oggWriter.begin(with: dataItem)

            recordedAudioData = Data()

            // Validazione formato prima di installare tap
            guard audioFormat.sampleRate > 0, audioFormat.channelCount > 0 else {
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
                ) { buffer, _ in
                    let elapsedTime = self.oggWriter.encodedDuration()

                    // 切除提示音
                    if activity, pttMusicPlay, self.skippedSamplesCount < targetSampleCount {
                        self.skippedSamplesCount += buffer.frameLength // 累加当前帧的样本数
                        return
                    }

                    if elapsedTime > 60 { return }

                    self.processAndDisposeAudioBuffer(buffer)

                    let mic = self.calculateLevelPercentage(from: buffer)
                    self.delegate?.audioManager(
                        self,
                        didUpdateRecordingPower: mic,
                        duration: elapsedTime
                    )
                }
            audioEngine.prepare()
            try audioEngine.start()

            logger.debug("Trasmissione audio avviata.")
        } catch {
            debugPrint(error.localizedDescription)
            _ = self.stopRecording()
        }
    }

    func stopRecording() -> Data? {
        logger.debug("Arresto trasmissione audio...")

        guard let audioEngine = audioEngine, let inputNode = inputNode else { return nil }

        inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        self.inputNode = nil
        self.audioEngine = nil

        if oggWriter.writeFrame(nil, frameByteCount: 0),
           oggWriter.encodedDuration() > 0.2
        {
            return dataItem.data()
        }

        logger.debug("Trasmissione audio arrestata.")
        return nil
    }

    func playAudio(_ filePath: URL) async {
        // Ferma riproduzione precedente se in corso
        stopPlay()

        playbackAudioEngine = AVAudioEngine()
        playbackPlayerNode = AVAudioPlayerNode()

        guard let audioEngine = playbackAudioEngine,
              let playerNode = playbackPlayerNode
        else {
            logger.debug("ERROR: Inizializzazione playback")
            return
        }

        do {
            // Configura il formato audio usando la frequenza di campionamento nativa del sistema
            let audioFormat = playerNode.outputFormat(forBus: 0)
            guard let audioFile = try? AVAudioFile(forReading: filePath) else {
                return
            }
            print("sampleRate: ", audioFile.processingFormat.sampleRate)

            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate

            self.startTimer(total: duration)

            // Configura audio engine — inserisce l'Equalizer Pro in catena se presente.
            audioEngine.attach(playerNode)
            self.eqAttach(
                to: audioEngine,
                bands: await Defaults[.eqBands],
                globalGain: await Defaults[.globalGain]
            )

            if let eq = self.audioUnitEQ {
                audioEngine.connect(playerNode, to: eq, format: audioFormat)
                audioEngine.connect(eq, to: audioEngine.mainMixerNode, format: audioFormat)
            } else {
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
            }

            self.setVolume()
            try audioEngine.start()

            playerNode.play()

            _ = await playerNode.scheduleFile(
                audioFile,
                at: nil,
                completionCallbackType: .dataPlayedBack
            )
            
            logger.debug("Avviata riproduzione audio PCM: frames")

        } catch {
            logger.debug("ERROR: Riproduzione audio PCM")
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
        let eq = AVAudioUnitEQ(numberOfBands:
            EqualizerPreset.bandFrequencies.count
        )
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

    private func processAndDisposeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let bufferData = conversionFloat32ToInt16Buffer(buffer) else { return }
        let buffer = bufferData.audioBufferList.pointee.mBuffers

        let sampleRate = 16000
        let frameDurationMs = 60
        let bytesPerSample = 2
        let encoderPacketSizeInBytes = sampleRate * frameDurationMs / 1000 * bytesPerSample

        let currentEncoderPacket = malloc(encoderPacketSizeInBytes)!
        defer { free(currentEncoderPacket) }

        var bufferOffset = 0

        while true {
            var currentEncoderPacketSize = 0

            while currentEncoderPacketSize < encoderPacketSizeInBytes {
                if recordedAudioData.count != 0 {
                    let takenBytes = min(
                        recordedAudioData.count,
                        encoderPacketSizeInBytes - currentEncoderPacketSize
                    )
                    if takenBytes != 0 {
                        recordedAudioData.withUnsafeBytes { rawBytes in
                            let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)

                            memcpy(
                                currentEncoderPacket.advanced(by: currentEncoderPacketSize),
                                bytes,
                                takenBytes
                            )
                        }
                        recordedAudioData.replaceSubrange(0..<takenBytes, with: Data())
                        currentEncoderPacketSize += takenBytes
                    }
                } else if bufferOffset < Int(buffer.mDataByteSize) {
                    let takenBytes = min(
                        Int(buffer.mDataByteSize) - bufferOffset,
                        encoderPacketSizeInBytes - currentEncoderPacketSize
                    )
                    if takenBytes != 0 {
                        memcpy(
                            currentEncoderPacket.advanced(by: currentEncoderPacketSize),
                            buffer.mData?.advanced(by: bufferOffset),
                            takenBytes
                        )

                        bufferOffset += takenBytes
                        currentEncoderPacketSize += takenBytes
                    }
                } else {
                    break
                }
            }

            if currentEncoderPacketSize < encoderPacketSizeInBytes {
                recordedAudioData.append(
                    currentEncoderPacket.assumingMemoryBound(to: UInt8.self),
                    count: currentEncoderPacketSize
                )
                break
            } else {
                oggWriter.writeFrame(
                    currentEncoderPacket.assumingMemoryBound(to: UInt8.self),
                    frameByteCount: UInt(currentEncoderPacketSize)
                )
            }
        }
    }

    private func conversionFloat32ToInt16Buffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: buffer.format.sampleRate,
            channels: buffer.format.channelCount,
            interleaved: true
        ) else {
            return nil
        }

        let frameLength = buffer.frameLength
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength)
        else {
            return nil
        }
        convertedBuffer.frameLength = frameLength

        // 获取输入 float32 样本指针
        guard let sourcePointer = buffer.floatChannelData?[0] else {
            return nil
        }

        // 获取目标 int16 样本指针
        guard let destinationPointer = convertedBuffer.int16ChannelData?[0] else {
            return nil
        }

        for index in 0..<Int(frameLength) {
            let floatSample = min(max(sourcePointer[index], -1.0), 1.0)
            destinationPointer[index] = Int16(clamping: Int(floatSample * 32767.0))
        }

        return convertedBuffer
    }

    private func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }

        let channelDataValue = channelData.pointee
        // 4
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        )
        .map { channelDataValue[$0] }

        // 5
        let rms = sqrt(channelDataValueArray.map {
            $0 * $0
        }
        .reduce(0, +) / Float(buffer.frameLength))

        // 6
        let avgPower = 20 * log10(rms)
        // 7
        let meterLevel = normalizedAudioLevel(from: avgPower)

        return Double(meterLevel)
    }

    private func normalizedAudioLevel(from decibels: Float) -> Float {
        guard decibels.isFinite else {
            return 0
        }

        let minDb: Float = -80

        guard decibels > minDb else {
            return 0
        }

        let normalized = (decibels - minDb) / -minDb

        return pow(normalized, 1.5)
    }
}

nonisolated extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
