//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScriptsView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/11 19:50.

import Defaults
import SwiftUI

struct ScriptsView: View {
    @State private var searchText: String = ""
    @State private var showAddView: Bool = false
    @State private var data: ScriptData?

    @Default(.scripts) private var scripts

    var datas: [String: [ScriptData]] {
        var datas: [String: [ScriptData]] = [:]
        for item in ScriptData.Mode.allCases {
            datas[item.rawValue] = Array(scripts.filter {
                if !searchText.isEmpty {
                    return $0
                        .mode == item &&
                        ($0.name.contains(searchText) || $0.mode.rawValue.contains(searchText))
                } else {
                    return $0.mode == item
                }
            })
            .sorted(by: { $0.createDate > $1.createDate })
        }
        return datas
    }

    var body: some View {
        List {
            ForEach(ScriptData.Mode.allCases, id: \.self) { mode in
                let scripts = datas[mode.rawValue] ?? []
                if scripts.count > 0 {
                    Section {
                        DatasView(datas: scripts)
                    } header: {
                        Label {
                            Text(mode.title)
                        } icon: {
                            Image(systemName: mode.symbol)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .searchable(text: $searchText)
        .navigationTitle("脚本列表")
        .sheet(isPresented: $showAddView) {
            AddScriptsView { self.showAddView = false }
                .customDetents([.large])
        }
        .sheet(item: $data) { item in
            NavigationStack {
                Form {
                    Section {
                        TextField("文件名", text: Binding(get: { item.name }, set: {
                            data?.name = $0
                        }))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .customField(icon: "key.viewfinder")
                    }

                    Section {
                        Picker(selection: Binding(get: {
                            item.mode
                        }, set: { data?.mode = $0 })) {
                            ForEach(ScriptData.Mode.allCases, id: \.self) { item in
                                Label {
                                    Text(item.title)
                                } icon: {
                                    Image(systemName: item.symbol)
                                }
                                .tag(item)
                            }
                        } label: {
                            Label {
                                Text("脚本类型")
                            } icon: {
                                Image(systemName: "applescript")
                            }
                        }
                    }
                }
                .navigationTitle("修改脚本")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            self.data = nil
                        } label: {
                            Text("取消")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let data = self.data {
                                if let data = scripts.first(where: { $0.id == item.id }) {
                                    scripts.remove(data)
                                }
                                scripts.insert(data)
                            }
                            self.data = nil
                        } label: {
                            Text("保存")
                        }
                    }
                }
                .customDetents([.medium])
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    self.showAddView.toggle()
                } label: {
                    Label {
                        Text("添加脚本")
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    @ViewBuilder
    func DatasView(datas: [ScriptData]) -> some View {
        ForEach(datas, id: \.id) { script in
            NavigationLink {
                ScriptPreview(file: script.file)
            } label: {
                Label {
                    Text(verbatim: script.name)
                } icon: {
                    Image(systemName: "applescript")
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        ScriptManager.shared.delete(script)
                    } label: {
                        Label {
                            Text("删除")
                        } icon: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        self.data = script

                    } label: {
                        Label {
                            Text("修改")
                        } icon: {
                            Image(systemName: "square.and.pencil.circle")
                        }
                    }
                    .tint(.accent)
                }
            }
        }
    }
}
