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

class AudioConversion{
    
    private class func removeIfExists(_ url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private class func loadFirstAudioTrack(_ asset: AVURLAsset) async throws -> AVAssetTrack {
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            throw NSError(domain: "AudioCAF", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio track"])
        }
        return track
    }

    private class var pcmOutputSettings: [String: Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
    }

    private class func makeReader(for track: AVAssetTrack, asset: AVAsset) throws -> (AVAssetReader, AVAssetReaderTrackOutput) {
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: pcmOutputSettings)
        reader.add(output)
        return (reader, output)
    }

    private class func makeLinearWriter(outputURL: URL,
                                        sampleRate: Double,
                                        channels: Int,
                                        bitDepth: Int,
                                        audioFormat: AudioFormatID) throws -> (AVAssetWriter, AVAssetWriterInput) {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .caf)
        var settings: [String: Any] = [
            AVFormatIDKey: audioFormat,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels
        ]
        if audioFormat == kAudioFormatLinearPCM {
            settings[AVLinearPCMBitDepthKey] = bitDepth
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsNonInterleaved] = false
        }
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        writer.add(input)
        return (writer, input)
    }

    private class func makeCompressedWriter(outputURL: URL,
                                            bitrate: Int,
                                            sampleRate: Double,
                                            channels: Int) throws -> (AVAssetWriter, AVAssetWriterInput) {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .caf)
        let aac: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: bitrate,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels
        ]
        let settings: [String: Any]
        if writer.canApply(outputSettings: aac, forMediaType: .audio) {
            settings = aac
        } else {
            settings = [
                AVFormatIDKey: kAudioFormatAppleIMA4,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels
            ]
        }
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        writer.add(input)
        return (writer, input)
    }
    class func convertAudioToCAF(inputURL: URL,
                                 outputURL: URL,
                                 sampleRate: Double = 44_100,
                                 channels: Int = 2,
                                 bitDepth: Int = 16,
                                 audioFormat: AudioFormatID = kAudioFormatLinearPCM) async throws -> URL {
        removeIfExists(outputURL)
        let asset = AVURLAsset(url: inputURL)
        let track = try await loadFirstAudioTrack(asset)
        let (reader, readerOutput) = try makeReader(for: track, asset: asset)
        let (writer, writerInput) = try makeLinearWriter(outputURL: outputURL, sampleRate: sampleRate, channels: channels, bitDepth: bitDepth, audioFormat: audioFormat)
        let actor = AudioCAFWriter(reader: reader, readerOutput: readerOutput, writer: writer, writerInput: writerInput, outputURL: outputURL)
        return try await actor.run()
    }
    
    class func toCAFLong(inputURL: URL,
                           outputURL: URL,
                           bitrate: Int = 128_000,
                           sampleRate: Double = 44_100,
                           channels: Int = 2,
                           targetSeconds: Double = 30) async throws -> URL {
        removeIfExists(outputURL)
        let asset = AVURLAsset(url: inputURL)
        let srcTrack = try await loadFirstAudioTrack(asset)
        let reader: AVAssetReader
        let readerOutput: AVAssetReaderTrackOutput
        if targetSeconds <= 0 {
            let r = try makeReader(for: srcTrack, asset: asset)
            reader = r.0
            readerOutput = r.1
        } else {
            let tr = try await srcTrack.load(.timeRange)
            let sourceDuration = tr.duration
            let target = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            var cursor = CMTime.zero
            if sourceDuration <= CMTime.zero {
                throw NSError(domain: "AudioCAF", code: -12, userInfo: [NSLocalizedDescriptionKey: "Invalid source duration"])
            }
            let composition = AVMutableComposition()
            guard let compTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw NSError(domain: "AudioCAF", code: -11, userInfo: [NSLocalizedDescriptionKey: "Composition track failed"])
            }
            while cursor < target {
                let remaining = target - cursor
                let chunk = remaining < sourceDuration ? remaining : sourceDuration
                try compTrack.insertTimeRange(CMTimeRange(start: .zero, duration: chunk), of: srcTrack, at: cursor)
                cursor = cursor + chunk
            }
            let compTracks = try await composition.loadTracks(withMediaType: .audio)
            guard let compAudioTrack = compTracks.first else {
                throw NSError(domain: "AudioCAF", code: -13, userInfo: [NSLocalizedDescriptionKey: "No composed audio track"])
            }
            let r = try makeReader(for: compAudioTrack, asset: composition)
            reader = r.0
            readerOutput = r.1
        }
        let w = try makeCompressedWriter(outputURL: outputURL, bitrate: bitrate, sampleRate: sampleRate, channels: channels)
        let actor = AudioCAFWriter(reader: reader, readerOutput: readerOutput, writer: w.0, writerInput: w.1, outputURL: outputURL)
        return try await actor.run()
    }
    
    
    class func toCAFShort(inputURL: URL,
                     outputURL: URL,
                     bitrate: Int = 128_000,
                     sampleRate: Double = 44_100,
                     channels: Int = 2,
                     maxSeconds: Double = 30) async throws -> URL {
        removeIfExists(outputURL)
        let asset = AVURLAsset(url: inputURL)
        let srcTrack = try await loadFirstAudioTrack(asset)
        let tr = try await srcTrack.load(.timeRange)
        let sourceDuration = tr.duration
        let maxDuration = CMTime(seconds: maxSeconds, preferredTimescale: 600)
        let reader: AVAssetReader
        let readerOutput: AVAssetReaderTrackOutput
        if maxSeconds > 0 && sourceDuration > maxDuration {
            let composition = AVMutableComposition()
            guard let compTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw NSError(domain: "AudioCAF", code: -21, userInfo: [NSLocalizedDescriptionKey: "Composition track failed"])
            }
            try compTrack.insertTimeRange(CMTimeRange(start: .zero, duration: maxDuration), of: srcTrack, at: .zero)
            let compTracks = try await composition.loadTracks(withMediaType: .audio)
            guard let compAudioTrack = compTracks.first else {
                throw NSError(domain: "AudioCAF", code: -22, userInfo: [NSLocalizedDescriptionKey: "No composed audio track"])
            }
            let r = try makeReader(for: compAudioTrack, asset: composition)
            reader = r.0
            readerOutput = r.1
        } else {
            let r = try makeReader(for: srcTrack, asset: asset)
            reader = r.0
            readerOutput = r.1
        }
        let w = try makeCompressedWriter(outputURL: outputURL, bitrate: bitrate, sampleRate: sampleRate, channels: channels)
        let actor = AudioCAFWriter(reader: reader, readerOutput: readerOutput, writer: w.0, writerInput: w.1, outputURL: outputURL)
        return try await actor.run()
    }
    
    
    
    actor AudioCAFWriter {
        let reader: AVAssetReader
        let readerOutput: AVAssetReaderTrackOutput
        let writer: AVAssetWriter
        let writerInput: AVAssetWriterInput
        let outputURL: URL
        
        init(reader: AVAssetReader,
             readerOutput: AVAssetReaderTrackOutput,
             writer: AVAssetWriter,
             writerInput: AVAssetWriterInput,
             outputURL: URL) {
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
    }
}
