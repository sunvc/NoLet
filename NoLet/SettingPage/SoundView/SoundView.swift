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
import Zip

struct SoundView: View {
    @StateObject private var tipsManager = AudioManager.shared

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
                    ///  UTType.types(tag: "caf", tagClass:
                    /// UTTagClass.filenameExtension,conformingTo: nil)
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
        .navigationTitle("所有铃声")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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

                } label: {
                    if downLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("更多", systemImage: "menubar.arrow.down.rectangle")
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

        // 1️⃣ 下载 zip 文件
        let zipURL = try await tipsManager.download(
            from: NCONFIG.soundsRemoteURL.url
        )

        // 2️⃣ 解压 zip
        let unzipURL = try Zip.quickUnzipFile(zipURL)

        // 3️⃣ sounds 目录
        guard let soundsDirURL = NCONFIG.getDir(.sounds) else {
            throw "Not Dir"
        }

        if !fileManager.fileExists(atPath: soundsDirURL.path) {
            try fileManager.createDirectory(
                at: soundsDirURL,
                withIntermediateDirectories: true
            )
        }

        // 4️⃣ 枚举解压后的文件
        guard let enumerator = fileManager.enumerator(
            at: unzipURL,
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

            // 5️⃣ 优先走转码
            if (try? await AudioConversion().toCAFShort(
                inputURL: item,
                outputURL: outputURL
            )) != nil {
                continue
            }

            // 6️⃣ 本身就是 caf，直接移动
            if item.pathExtension.lowercased() == "caf" {
                try fileManager.moveItem(at: item, to: outputURL)
            }
        }

        // 7️⃣ 更新列表
        tipsManager.updateFileList()

        // 8️⃣ 清理临时文件
        try? fileManager.removeItem(at: unzipURL)
        try? fileManager.removeItem(at: zipURL)
    }


    /// 通用文件保存方法
    func saveSound(
        url sourceURL: URL,
        name lastPath: String? = nil,
        maxNameLength: Int = 13
    ) async {
        // 获取 App Group 的共享铃声目录路径
        guard let groupDirectoryURL = NCONFIG.getDir(.sounds) else { return }

        var fileName: String {
            String((lastPath ?? sourceURL.lastPathComponent).suffix(maxNameLength))
        }

        // 构造目标路径：使用传入的自定义文件名（lastPath），否则使用源文件名
        let groupDestinationURL = groupDirectoryURL.appendingPathComponent(fileName)

        // 如果目标文件已存在，先删除旧文件
        if FileManager.default.fileExists(atPath: groupDestinationURL.path) {
            try? FileManager.default.removeItem(at: groupDestinationURL)
        }

        do {
            _ = try await AudioConversion().toCAFShort(
                inputURL: sourceURL,
                outputURL: groupDestinationURL,
                maxSeconds: 29.9
            )
            // 拷贝文件到共享目录（实现“保存”操作）
            try FileManager.default.removeItem(at: sourceURL)

            // 弹出成功提示（使用 Toast）
            Toast.success(title: "保存成功")

            // 刷新铃声文件列表（用于更新 UI 或数据）
            tipsManager.updateFileList()
        } catch {
            // 如果保存失败，弹出错误提示
            Toast.error(title: "保存失败")
            logger.error("\(error)")
        }
    }

    func deleteSound(url: URL) {
        // 获取 App Group 中的共享铃声目录
        guard let soundsDirectoryURL = NCONFIG.getDir(.sounds) else { return }

        // 删除本地 sounds 目录下的铃声文件
        try? FileManager.default.removeItem(at: url)

        // 构造共享目录下对应的长铃声文件路径（带有前缀）
        let groupSoundURL = soundsDirectoryURL.appendingPathComponent(
            "\(NCONFIG.longSoundPrefix).\(url.lastPathComponent)")

        // 删除共享目录中的铃声文件（如果存在）
        try? FileManager.default.removeItem(at: groupSoundURL)

        // 刷新文件列表（通常是为了更新 UI 或内部数据状态）
        tipsManager.updateFileList()
    }
}

#Preview {
    NavigationStack {
        SoundView()
    }
}
