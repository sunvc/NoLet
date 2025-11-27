//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AudioConversion.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/11/25 02:10.

import AVFoundation

actor AudioCAFManager {
    let reader: AVAssetReader
    let readerOutput: AVAssetReaderTrackOutput
    let writer: AVAssetWriter
    let writerInput: AVAssetWriterInput
    let outputURL: URL

    init(
        reader: AVAssetReader,
        readerOutput: AVAssetReaderTrackOutput,
        writer: AVAssetWriter,
        writerInput: AVAssetWriterInput,
        outputURL: URL
    ) {
        self.reader = reader
        self.readerOutput = readerOutput
        self.writer = writer
        self.writerInput = writerInput
        self.outputURL = outputURL
    }

    func run() async throws -> URL {
        if !reader.startReading() {
            throw reader.error ?? NSError(domain: "AudioCAF", code: -2)
        }
        if !writer.startWriting() {
            throw writer.error ?? NSError(domain: "AudioCAF", code: -3)
        }
        writer.startSession(atSourceTime: .zero)

        while true {
            if writerInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                    if !writerInput.append(sampleBuffer) {
                        reader.cancelReading()
                        writerInput.markAsFinished()
                        writer.cancelWriting()
                        throw writer.error ?? NSError(domain: "AudioCAF", code: -4)
                    }
                } else {
                    break
                }
            } else {
                try await Task.sleep(nanoseconds: 5_000_000)
            }
        }

        writerInput.markAsFinished()
        await writer.finishWriting()

        if reader.status == .failed {
            throw reader.error ?? NSError(domain: "AudioCAF", code: -5)
        } else if writer.status == .failed {
            throw writer.error ?? NSError(domain: "AudioCAF", code: -6)
        }

        return outputURL
    }

    static func toCAFLong(
        inputURL: URL,
        outputURL: URL,
        bitrate: Int = 128_000,
        sampleRate: Double = 44100,
        channels: Int = 2,
        targetSeconds: Double = 30
    ) async throws -> URL {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        let asset = AVURLAsset(url: inputURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let srcTrack = tracks.first else {
            throw NSError(
                domain: "AudioCAF", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No audio track"]
            )
        }
        let reader: AVAssetReader
        let readerOutput: AVAssetReaderTrackOutput
        if targetSeconds <= 0 {
            reader = try AVAssetReader(asset: asset)
            readerOutput = AVAssetReaderTrackOutput(
                track: srcTrack,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMIsNonInterleaved: false,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
            )
            reader.add(readerOutput)
        } else {
            let tr = try await srcTrack.load(.timeRange)
            let sourceDuration = tr.duration
            let target = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            var cursor = CMTime.zero
            if sourceDuration <= CMTime.zero {
                throw NSError(
                    domain: "AudioCAF", code: -12,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid source duration"]
                )
            }
            let composition = AVMutableComposition()
            guard
                let compTrack = composition.addMutableTrack(
                    withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
                )
            else {
                throw NSError(
                    domain: "AudioCAF", code: -11,
                    userInfo: [NSLocalizedDescriptionKey: "Composition track failed"]
                )
            }
            while cursor < target {
                let remaining = target - cursor
                let chunk = remaining < sourceDuration ? remaining : sourceDuration
                try compTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: chunk), of: srcTrack, at: cursor
                )
                cursor = cursor + chunk
            }
            let compTracks = try await composition.loadTracks(withMediaType: .audio)
            guard let compAudioTrack = compTracks.first else {
                throw NSError(
                    domain: "AudioCAF", code: -13,
                    userInfo: [NSLocalizedDescriptionKey: "No composed audio track"]
                )
            }
            reader = try AVAssetReader(asset: composition)
            readerOutput = AVAssetReaderTrackOutput(
                track: compAudioTrack,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMIsNonInterleaved: false,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
            )
            reader.add(readerOutput)
        }

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .caf)
        let aac: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: bitrate,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
        ]
        let codecSettings: [String: Any]
        if writer.canApply(outputSettings: aac, forMediaType: .audio) {
            codecSettings = aac
        } else {
            codecSettings = [
                AVFormatIDKey: kAudioFormatAppleIMA4,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
            ]
        }
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: codecSettings)
        input.expectsMediaDataInRealTime = false
        writer.add(input)

        let actor = AudioCAFManager(
            reader: reader, readerOutput: readerOutput, writer: writer, writerInput: input,
            outputURL: outputURL
        )
        return try await actor.run()
    }

    static func toCAFShort(
        inputURL: URL,
        outputURL: URL,
        bitrate: Int = 128_000,
        sampleRate: Double = 44100,
        channels: Int = 2,
        maxSeconds: Double = 0
    ) async throws -> URL {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        let asset = AVURLAsset(url: inputURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let srcTrack = tracks.first else {
            throw NSError(
                domain: "AudioCAF", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No audio track"]
            )
        }
        let tr = try await srcTrack.load(.timeRange)
        let sourceDuration = tr.duration
        let maxDuration = CMTime(seconds: maxSeconds, preferredTimescale: 600)
        let reader: AVAssetReader
        let readerOutput: AVAssetReaderTrackOutput
        if maxSeconds > 0 && sourceDuration > maxDuration {
            let composition = AVMutableComposition()
            guard
                let compTrack = composition.addMutableTrack(
                    withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
                )
            else {
                throw NSError(
                    domain: "AudioCAF", code: -21,
                    userInfo: [NSLocalizedDescriptionKey: "Composition track failed"]
                )
            }
            try compTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: maxDuration), of: srcTrack, at: .zero
            )
            let compTracks = try await composition.loadTracks(withMediaType: .audio)
            guard let compAudioTrack = compTracks.first else {
                throw NSError(
                    domain: "AudioCAF", code: -22,
                    userInfo: [NSLocalizedDescriptionKey: "No composed audio track"]
                )
            }
            reader = try AVAssetReader(asset: composition)
            readerOutput = AVAssetReaderTrackOutput(
                track: compAudioTrack,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMIsNonInterleaved: false,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
            )
            reader.add(readerOutput)
        } else {
            reader = try AVAssetReader(asset: asset)
            readerOutput = AVAssetReaderTrackOutput(
                track: srcTrack,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMIsNonInterleaved: false,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                ]
            )
            reader.add(readerOutput)
        }

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .caf)
        let aac: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: bitrate,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
        ]
        let codecSettings: [String: Any]
        if writer.canApply(outputSettings: aac, forMediaType: .audio) {
            codecSettings = aac
        } else {
            codecSettings = [
                AVFormatIDKey: kAudioFormatAppleIMA4,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
            ]
        }
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: codecSettings)
        input.expectsMediaDataInRealTime = false
        writer.add(input)

        let actor = AudioCAFManager(
            reader: reader, readerOutput: readerOutput, writer: writer, writerInput: input,
            outputURL: outputURL
        )
        return try await actor.run()
    }
}
