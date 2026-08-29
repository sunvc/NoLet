//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AddScriptsView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/11 19:39.

import SwiftUI

struct AddScriptsView: View {
    @State private var content: String = ""
    @State private var name: String = ""
    @State private var mode: ScriptData.Mode = .tts

    var filePath: URL? { ScriptManager.shared.filePath(self.name) }

    var dismiss: (() -> Void)? = nil

    @State private var showImport = false

    var body: some View {
        NavigationStack {
            Form {
                Section("调用名") {
                    TextField(text: $name) {}
                        .customField(icon: "doc.text") {
                            if let text = NCONFIG.text() {
                                name = text
                            }
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .fileImporter(
                            isPresented: $showImport,
                            allowedContentTypes: [.javaScript],
                            allowsMultipleSelection: false,
                            onCompletion: { result in
                                Task.detached(priority: .userInitiated) {
                                    switch result {
                                    case .success(let files):
                                        guard let url = files.first else { return }
                                        if url.startAccessingSecurityScopedResource() {
                                            
                                            Task{@MainActor in
                                                if self.name.isEmpty{
                                                    self.name =  url.deletingPathExtension().lastPathComponent
                                                }
                                            }
                                            
                                            let content = try String(
                                                contentsOf: url,
                                                encoding: .utf8
                                            )
                                            await MainActor.run {
                                                self.content = content
                                            }
                                        }
                                    case .failure(let err):
                                        await Toast.shared.present(
                                            title: err.localizedDescription,
                                            symbol: .error
                                        )
                                    }
                                }
                            }
                        )
                }

                Section {
                    Picker(selection: $mode) {
                        ForEach(ScriptData.Mode.allCases, id: \.self) { item in
                            
                            Label { 
                                Text(item.title)
                            } icon: { 
                                Image(systemName: item.symbol)
                            }.tag(item)
                        }
                    } label: {
                        Label {
                            Text("脚本类型")
                        } icon: {
                            Image(systemName: "applescript")
                        }
                    }
                }
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 60,maxHeight: 260)
                        .customField(icon: "doc.on.clipboard") {
                            if let text = NCONFIG.text() {
                                content = text
                            }
                        }
                    

                } header: {
                    Text("脚本内容或URL")
                }
                
                Section{
                    HStack{
                        Spacer()
                        AnimatedButton(
                            normal: .init(title: "保存脚本", symbolImage: "square.and.arrow.down")
                        ) { handler in
                            
                            if !content.isEmpty {
                                if let url = URL(remote: content) {
                                    if self.name.isEmpty {
                                        self.name = url.deletingPathExtension().lastPathComponent
                                    }

                                    await handler.loading(title: "开始下载")

                                    do {
                                        let request = NetworkManager()
                                        let file = try await request.download(from: url)
                                        
                                        
                                        let script = try String(
                                            contentsOfFile: file.path(),
                                            encoding: .utf8
                                        )
                                        await handler.loading(title: "正在校验")
                                        if await JSRuntime.validate(script, args: mode.args).ok {
                                            self.content = script
                                        } else {
                                            await handler.fail(title: "校验失败")
                                        }

                                    } catch {
                                        await handler.fail(title: "下载失败")
                                        return
                                    }
                                }
                                
                                if name.isEmpty {
                                    Toast.info(title: "参数不能为空")
                                    return 
                                }
                                
                                do {
                                    let data = try ScriptData(
                                        name: self.name,
                                        content: self.content,
                                        mode: self.mode
                                    )
                                    Defaults[.scripts].insert(data)
                                    await handler.succeed(symbolImage: "flag.checkered")
                                    self.dismiss?()
                                } catch {
                                    logger.error("\(error.localizedDescription)")
                                    await handler.fail()
                                }

                            } else {
                                Toast.info(title: "参数不能为空")
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("添加脚本")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(ContentBackgroundView())
            .customDetents([.medium, .large])
            .toolbar {
                ToolbarItem {
                    Button {
                        self.showImport = true
                    } label: {
                        Image(systemName: "folder")
                    }
                }
            }
        }
    }
}
