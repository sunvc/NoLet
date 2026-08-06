//
//  SoundView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo 2024/8/9.
//

// MARK: - afconvert input.wav output.caf -d ima4 -f caff

import AVFoundation
import SwiftUI
import UIKit

struct SoundView: View {
    @ObservedObject private var tipsManager = AudioManager.shared

    @State private var showUpload: Bool = false
    @State private var uploadLoading: Bool = false
    @State private var downLoading: Bool = false

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    Button {
                        self.showUpload.toggle()
                    } label: {
                        Label("上传铃声", systemImage: "waveform")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint)
                            .if(uploadLoading) { _ in
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Text("正在处理中...")
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background26(.ultraThinMaterial, radius: 20)
                    }
                    .disabled(uploadLoading)
                    .fileImporter(
                        isPresented: $showUpload,
                        allowedContentTypes: [.audio]
                    ) { result in
                        self.uploadLoading = true
                        switch result {
                        case .success(let file):
                            Task.detached {
                                defer {
                                    file.stopAccessingSecurityScopedResource()
                                }

                                if file.startAccessingSecurityScopedResource() {
                                    await self.saveSound(url: file)
                                    try? await Task.sleep(for: .seconds(0.5))
                                    await MainActor.run {
                                        self.uploadLoading = false
                                    }
                                }
                            }

                        case .failure(let err):
                            self.uploadLoading = false
                            Toast.error(title: "添加失败")
                            logger.error("\(err)")
                        }
                    }

                    Spacer()
                }
            } header: {
                Spacer()
            } footer: {
                HStack {
                    Text("选择铃声，超出30秒的将截断")
                }
            }.listRowBackground(Color.clear)

            if tipsManager.customSounds.count > 0 {
                Section {
                    ForEach(tipsManager.customSounds, id: \.self) { url in
                        SoundItemView(tipsManager: tipsManager, audio: url)

                    }.onDelete { indexSet in
                        for index in indexSet {
                            self.deleteSound(url: tipsManager.customSounds[index])
                        }
                    }

                } header: {
                    Text("自定义铃声")
                }
            }

            Section {
                ForEach(tipsManager.defaultSounds, id: \.self) { url in
                    SoundItemView(tipsManager: tipsManager, audio: url)
                }
            } header: {
                Text("内置铃声")
            }
        }
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle("所有铃声")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Section {
                    Button {
                        self.downLoading = true
                        Task {
                            do {
                                try await self.downloadSounds()
                                Toast.success(title: "下载成功")

                            } catch {
                                logger.error("\(error)")
                                Toast.error(title: "下载失败")
                            }
                            self.downLoading = false
                        }
                    } label: {
                        Label("获取所有铃声", systemImage: "arrow.down.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, .primary)
                            .accessibilityLabel("同步所有铃声")
                    }
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Section {
                    Button {
                        guard let soundsDirURL = NCONFIG.Path(.sounds) else {
                            return
                        }

                        do {
                            try FileManager.default.removeItem(at: soundsDirURL)
                            tipsManager.updateFileList()
                            Toast.success(title: "删除成功")
                        } catch {
                            Toast.error(title: "删除失败")
                        }

                    } label: {
                        Label("删除下载铃声", systemImage: "trash")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.red, .primary)
                            .accessibilityLabel("删除下载铃声")
                    }
                }
            }
        }
        .onDisappear {
            tipsManager.play(stop: true)
        }
    }

    func downloadSounds() async throws {
        let fileManager = FileManager.default

        let fromURL = try await tipsManager.network.download(
            from: NCONFIG.soundsRemoteURL.url
        )

        let soundsTem = FileManager.default.temporaryDirectory
            .appending(
                path: fromURL.deletingPathExtension().lastPathComponent,
                directoryHint: .isDirectory
            )

        defer {
            tipsManager.updateFileList()
            try? fileManager.removeItem(at: soundsTem)
            try? fileManager.removeItem(at: fromURL)
        }

        guard let soundsDirURL = NCONFIG.Path(.sounds) else {
            throw NoletError("Not Dir")
        }

        try AppleArchiveManager.extractArchive(from: fromURL, to: soundsTem)

        if !fileManager.fileExists(atPath: soundsDirURL.path) {
            try fileManager.createDirectory(
                at: soundsDirURL,
                withIntermediateDirectories: true
            )
        }

        guard let enumerator = fileManager.enumerator(
            at: soundsTem,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let skipFiles = tipsManager.allSounds()

        while let item = enumerator.nextObject() as? URL {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory == true { continue }

            let baseName = item.deletingPathExtension().lastPathComponent
            if skipFiles.contains(baseName) { continue }

            let outputURL = soundsDirURL
                .appendingPathComponent("\(baseName).caf")

            if fileManager.fileExists(atPath: outputURL.path) {
                continue
            }

            if (try? await AudioConversion().toCAFShort(
                inputURL: item,
                outputURL: outputURL
            )) != nil {
                continue
            }

            if item.pathExtension.lowercased() == "caf" {
                try fileManager.moveItem(at: item, to: outputURL)
            }
        }
    }

    /// 通用文件保存方法
    func saveSound(
        url sourceURL: URL,
        name lastPath: String? = nil,
        maxNameLength: Int = 13
    ) async {
        guard let groupDirectoryURL = NCONFIG.Path(.sounds) else { return }

        var fileName: String {
            String((lastPath ?? sourceURL.lastPathComponent).suffix(maxNameLength))
        }

        let groupDestinationURL = groupDirectoryURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: groupDestinationURL.path) {
            try? FileManager.default.removeItem(at: groupDestinationURL)
        }

        do {
            _ = try await AudioConversion().toCAFShort(
                inputURL: sourceURL,
                outputURL: groupDestinationURL,
                maxSeconds: 29.9
            )
            try FileManager.default.removeItem(at: sourceURL)

            Toast.success(title: "保存成功")

            tipsManager.updateFileList()
        } catch {
            Toast.error(title: "保存失败")
            logger.error("\(error)")
        }
    }

    func deleteSound(url: URL) {
        try? FileManager.default.removeItem(at: url)
        if let groupSoundURL = NCONFIG.SoundName.long.path(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: groupSoundURL)
        }
        tipsManager.updateFileList()
    }
}

#Preview {
    NavigationStack {
        SoundView()
    }
}
