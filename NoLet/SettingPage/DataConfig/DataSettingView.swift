//
//  DataSettingView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import Defaults
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let sqlite = UTType(filenameExtension: "sqlite")!
}

struct DataSettingView: View {
    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var messageManager = MessagesManager.shared

    @Default(.messageExpiration) var messageExpiration
    @Default(.imageSaveDays) var imageSaveDays
    @Default(.proxyServer) var proxyServer
    @Default(.servers) var servers

    @State private var showImport: Bool = false
    @State private var showexportLoading: Bool = false
    @State private var showDriveCheckLoading: Bool = false

    @State private var showDeleteView: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var resetAppShow: Bool = false
    @State private var restartAppShow: Bool = false

    @State private var totalSize: UInt64 = 0
    @State private var cacheSize: UInt64 = 0

    @State private var cancelTask: Task<Void, Never>?

    @State private var addLoading: Bool = false

    @State private var exampleValue = 10000.0

    @State private var showChangeDay = false
    @State private var changeDayTem = ""

    @State private var showChangeImageDay = false
    @State private var changeImageDayTem = ""

    var pickerServers: [PushServerModel] {
        [PushServerModel.space] + servers
    }

    var expirationTimes: [ExpirationTime] {
        switch messageExpiration {
        case .forever, .no:
            return [.forever, .day(1), .no]
        case .day(let day):
            return [.forever, .day(day), .no]
        }
    }

    var imageTimes: [ExpirationTime] {
        switch imageSaveDays {
        case .forever, .no:
            return [.forever, .day(1), .no]
        case .day(let day):
            return [.forever, .day(day), .no]
        }
    }

    private let pngCache = ImageManager.customCache.diskStorage.directoryURL
    
    var body: some View {
        List {
            #if DEBUG
            Section {
                Stepper(
                    value: $exampleValue,
                    in: 10000...1_000_000,
                    step: 50000
                ) {
                    Button {
                        self.addLoading = true
                        Task.detached(priority: .high) {
                            _ = await self.createStressTest(max: Int(exampleValue))
                            await MainActor.run {
                                self.addLoading = false
                                self.calculateSize()
                            }
                        }
                    } label: {
                        Label {
                            Text(verbatim: addLoading ? "Adding..." :
                                "Add \(Int(exampleValue)) Test")
                        } icon: {
                            Image(systemName: "plus.message.fill")
                        }
                    }
                    .button26(BorderedProminentButtonStyle())
                    .disabled(addLoading)
                }

            } header: {
                Text(verbatim: "")
            }
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            #endif

            Section {
                Menu {
                    if messageManager.allCount > 0 {
                        Section {
                            Button {
                                guard !showexportLoading else { return }
                                self.showexportLoading = true
                                cancelTask = Task.detached(priority: .userInitiated) {
                                    do {
                                        let filepath = FileManager.default.temporaryDirectory
                                            .appendingPathComponent(
                                                "NoLet_\(Date().formatString(format: "yyyy_MM_dd_HH_mm"))",
                                                conformingTo: .trnExportType
                                            )
                                        try await messageManager.exportToJSONFile(fileURL: filepath)

                                        DispatchQueue.main.async {
                                            AppManager.shared
                                                .open(sheet: .share(
                                                    contents: [filepath],
                                                    preview: nil,
                                                    title: nil
                                                ))
                                            self.showexportLoading = false
                                            self.calculateSize()
                                        }
                                    } catch {
                                        logger.error("\(error)")
                                        DispatchQueue.main.async {
                                            self.showexportLoading = false
                                        }
                                    }
                                }
                            } label: {
                                Label("消息列表", systemImage: "list.bullet.clipboard")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.tint, Color.primary)
                            }
                        }
                    }

                    Section {
                        Button {
                            if let configPath = AppManager.createDatabaseFileTem() {
                                AppManager.shared.open(sheet: .share(
                                    contents: [configPath],
                                    preview: nil,
                                    title: nil
                                ))
                                self.calculateSize()
                            }

                        } label: {
                            Label("配置文件", systemImage: "doc.badge.gearshape")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                        }
                    }

                    Section {
                        Button {
                            AppManager.shared.open(sheet: .share(
                                contents: [NCONFIG.databasePath],
                                preview: nil,
                                title: nil
                            ))
                            self.calculateSize()
                        } label: {
                            Label("数据库文件", systemImage: "internaldrive")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                        }
                    }

                } label: {
                    HStack {
                        Label("导出", systemImage: "square.and.arrow.up")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .if(showexportLoading) {
                                Label("正在处理数据", systemImage: "slowmo")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.tint, Color.primary)
                            }
                        Spacer()
                        Text(String(format: String(localized: "%d条消息"), messageManager.allCount))
                            .foregroundStyle(Color.green)
                    }
                }
                .onDisappear {
                    cancelTask?.cancel()
                }

                HStack {
                    Button {
                        self.showImport.toggle()
                    } label: {
                        Label("导入", systemImage: "arrow.down.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                    }
                    Spacer()
                }
                .fileImporter(
                    isPresented: $showImport,
                    allowedContentTypes: [.trnExportType, .sqlite, .propertyList, .javaScript],
                    allowsMultipleSelection: false,
                    onCompletion: { result in
                        Task.detached(priority: .userInitiated) {
                            switch result {
                            case .success(let files):
                                let msg = await importMessage(files)
                                await Toast.shared.present(title: msg, symbol: .info)
                            case .failure(let err):
                                await Toast.shared.present(
                                    title: err.localizedDescription,
                                    symbol: .error
                                )
                            }
                        }
                    }
                )
            } header: {
                Text(verbatim: "")
            } footer: {
                Text("导出/导入(消息/配置/数据库)")
                    .textCase(.none)
            }

            Section {
                Picker(selection: $messageExpiration) {
                    ForEach(expirationTimes, id: \.self) { item in
                        Text(item.title)
                            .tag(item)
                    }
                } label: {
                    Label {
                        Text("消息存档")
                    } icon: {
                        if case .day = messageExpiration {
                            Image(systemName: "square.and.pencil.circle")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    messageExpiration == .no ? .red : Color.primary
                                )

                        } else {
                            Image(systemName: "externaldrive.badge.timemachine")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    messageExpiration == .no ? .red : Color.primary
                                )
                        }
                    }
                    .onTapGesture {
                        if case .day = messageExpiration {
                            self.showChangeDay = true
                        }
                    }
                    .onAppear {
                        if case .day(let day) = messageExpiration {
                            self.changeDayTem = "\(day)"
                        }
                    }
                    .onChange(of: messageExpiration) { value in
                        if case .day(let day) = value {
                            self.changeDayTem = "\(day)"
                        }
                    }
                }

                Picker(selection: $imageSaveDays) {
                    ForEach(imageTimes, id: \.self) { item in
                        Text(item.title)
                            .tag(item)
                    }
                } label: {
                    Label {
                        Text("图片存档")
                    } icon: {
                        if case .day = imageSaveDays {
                            Image(systemName: "square.and.pencil.circle")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    imageSaveDays == .no ? .red : Color.primary
                                )

                        } else {
                            Image(systemName: "externaldrive.badge.timemachine")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    imageSaveDays == .no ? .red : Color.primary
                                )
                        }
                    }
                    .onTapGesture {
                        if case .day = imageSaveDays {
                            self.showChangeImageDay = true
                        }
                    }
                    .onAppear {
                        if case .day(let day) = imageSaveDays {
                            self.changeImageDayTem = "\(day)"
                        }
                    }
                    .onChange(of: imageSaveDays) { value in
                        if case .day(let day) = value {
                            self.changeImageDayTem = "\(day)"
                        }
                    }
                }

            } footer: {
                Text("当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
                    .foregroundStyle(.gray)
            }

            Section {
                ListButton {
                    Label {
                        Text("云图标")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        ZStack {
                            Image(systemName: "icloud")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(Color.primary)
                            Image(systemName: "photo")
                                .scaleEffect(0.4)
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent)
                                .offset(y: 2)
                        }
                    }
                } action: {
                    Task { @MainActor in
                        manager.open(sheet: .cloudIcon)
                    }
                    return true
                }

                NavigationLink {
                    NoletFileList(rootURL: NCONFIG.localContainer)
                } label: {
                    HStack {
                        Label {
                            Text("文件管理")
                        } icon: {
                            Image(systemName: "folder.badge.questionmark")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                        }

                        Spacer()
                        HStack {
                            Text(verbatim: cacheSize.fileSize())
                            Text(verbatim: "/")
                                .foregroundStyle(.gray)
                            Text(verbatim: totalSize.fileSize())
                        }
                        .if(showDriveCheckLoading) {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("清理中...")
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ContentBackgroundView())
        .navigationTitle("数据管理")
        .if(showChangeImageDay) { view in
            view.modifier(
                ChangeView(show: $showChangeImageDay, data: $imageSaveDays)
            )
        }
        .if(showChangeDay) { view in
            view.modifier(
                ChangeView(show: $showChangeDay, data: $messageExpiration)
            )
        }
        .if(restartAppShow) { view in
            view
                .alert(isPresented: $restartAppShow) {
                    Alert(
                        title: Text("导入成功"),
                        message: Text("重启才能生效,即将退出程序！"),
                        dismissButton:
                        .destructive(Text("确定"), action: { exit(0) })
                    )
                }
        }
        .if(resetAppShow) { view in
            view
                .alert(isPresented: $resetAppShow) {
                    Alert(
                        title: Text("危险操作!!! 恢复初始化."),
                        message: Text("将丢失所有数据"),
                        primaryButton: .destructive(Text("确定"), action: { resetApp() }),
                        secondaryButton: .cancel()
                    )
                }
        }
        .if(showDeleteAlert) { view in
            view
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("是否确定清空?"),
                        message: Text("删除后不能还原!!!"),
                        primaryButton: .destructive(
                            Text("清空"),
                            action: {
                                self.showDriveCheckLoading = true
                                if let fileURL = NCONFIG.Path(.sounds),
                                   let cacheURL = NCONFIG.Path(.tem)
                                {
                                    ImageManager.customCache.clearDiskCache()
                                    manager.clearContentsOfDirectory(at: fileURL)
                                    manager.clearContentsOfDirectory(at: cacheURL)
                                }

                                Toast.success(title: "清理成功")
                                self.showDriveCheckLoading = false
                                calculateSize()
                            }
                        ),
                        secondaryButton: .cancel()
                    )
                }
        }
        .deleteTips($showDeleteView)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    self.showDeleteView = true
                } label: {
                    Label("按条件删除消息", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Section {
                    Button {
                        self.resetAppShow.toggle()
                    } label: {
                        HStack {
                            Spacer()
                            Label("初始化App", systemImage: "arrow.3.trianglepath")
                                .foregroundStyle(.white, Color.primary)
                                .padding(.vertical, 5)
                                .fontWeight(.bold)

                            Spacer()
                        }
                    }
                    .tint(.red)
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Section {
                    Button {
                        guard !showDeleteAlert else { return }
                        self.showDeleteAlert.toggle()
                    } label: {
                        Label("清空缓存数据", systemImage: "trash.circle")
                            .foregroundStyle(.white, Color.primary)
                            .fontWeight(.bold)
                            .padding(.vertical, 5)
                    }
                }
            }
        }
        .onChange(of: messageManager.allCount) { _ in
            self.calculateSize()
        }
        .task { calculateSize() }
    }

    fileprivate func resetApp() {
        manager.clearContentsOfDirectory(at: NCONFIG.localContainer)
        exit(0)
    }

    func calculateSize() {
        if
            let soundsURL = NCONFIG.Path(.sounds),
            let caches = NCONFIG.Path(.caches),
            let cacheFileURL = NCONFIG.Path(.tem)
        {
            
            totalSize = manager.calculateDirectorySize(at: NCONFIG.localContainer)

            cacheSize = manager.calculateDirectorySize(at: soundsURL) + manager
                .calculateDirectorySize(at: caches) +
                manager.calculateDirectorySize(at: cacheFileURL) + 
                manager.calculateDirectorySize(at: pngCache)
        }
    }

    fileprivate func importMessage(_ fileURLs: [URL]) async -> String {
        guard let url = fileURLs.first else { return "" }

        do {
            if url.startAccessingSecurityScopedResource() {
                switch url.pathExtension {
                case "plist":
                    let raw = try Data(contentsOf: url)
                    if let data = CryptoManager(.data).decrypt(data: raw) {
                        try data.write(to: NCONFIG.configPath)
                    } else {
                        throw NoletError( "解密失败")
                    }
                    await MainActor.run {
                        self.restartAppShow.toggle()
                    }

                case "sqlite":
                    let raw = try Data(contentsOf: url)
                    try raw.write(to: NCONFIG.databasePath)
                    await MainActor.run {
                        self.restartAppShow.toggle()
                    }

                case "js":
                    let script = try String(contentsOf: url, encoding: .utf8)
                    let result = await JSRuntime.validate(script, args: ScriptData.Mode.tts.args)
                    if result.ok {
                        let data = try ScriptData(
                            name: url.lastPathComponent,
                            content: script,
                            mode: .tts
                        )

                        Defaults[.scripts].insert(data)
                    } else {
                        if let message = result.message {
                            Toast.shared.present(title: message, symbol: .error)
                        }
                        throw NoletError( "script error")
                    }

                default:
                    try await messageManager.importJSONFile(fileURL: url)
                }
            }

            return String(localized: "导入成功")

        } catch {
            logger.error("\(error)")
            return error.localizedDescription
        }
    }

    func createStressTest(
        max number: Int = 100_000
    ) async -> Bool {
        do {
            let body = """
                ---

                ## 📌 功能亮点

                ### 📲 Push 通知

                - 简单易用的 API 可推送任意自定义内容
                - 支持多种通知级别
                - 支持自定义图标、铃声等

                ---

                ## 📡 自建服务器

                项目支持自建推送服务器，方便对推送流程进行私有化部署：

                - 服务端代码同样开源
                - 支持 Docker 部署
                - 有助于提高数据隐私和可控性

                ---
                """

            try await MessageDBManager.shared.bulkInsertStress(count: number, body: body)
            return true
        } catch {
            logger.error("创建失败")
            return false
        }
    }

    struct ChangeView: ViewModifier {
        @Binding var show: Bool
        @Binding var data: ExpirationTime

        @State private var dataTem: String

        init(show: Binding<Bool>, data: Binding<ExpirationTime>) {
            self._show = show
            self._data = data
            if case .day(let day) = data.wrappedValue {
                self._dataTem = State(wrappedValue: "\(day)")
            } else {
                self._dataTem = State(wrappedValue: "1")
            }
        }

        func body(content: Content) -> some View {
            content
                .alert("修改存档时间", isPresented: $show) {
                    TextField(text: $dataTem) {}
                        .customField(icon: "clock.arrow.circlepath")
                        .keyboardType(.numberPad)

                    Button("取消", role: .cancel) { self.dataTem = "" }

                    Button("保存", role: .destructive) {
                        if let days = Int64(dataTem) {
                            self.data = .day(days)
                        }
                    }
                } message: {
                    Text("修改数据的保存时间. 单位: 天")
                }
        }
    }
}

extension UInt64 {
    func fileSize() -> String {
        if self >= 1_073_741_824 {
            return String(format: "%.2fGB", Double(self) / 1_073_741_824)
        } else if self >= 1_048_576 {
            return String(format: "%.2fMB", Double(self) / 1_048_576)
        } else if self >= 1024 {
            return String(format: "%dKB", self / 1024)
        } else {
            return "\(self)B"
        }
    }
}

extension ExpirationTime {
    var title: String {
        switch self {
        case .no: String(localized: "不保存")
        case .day(let day): String(localized: "\(day)天")
        case .forever: String(localized: "长期")
        }
    }
}

#Preview {
    DataSettingView()
}
