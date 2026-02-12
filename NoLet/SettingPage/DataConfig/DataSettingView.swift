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
    @EnvironmentObject private var manager: AppManager
    @StateObject private var messageManager = MessagesManager.shared

    @Default(.messageExpiration) var messageExpiration
    @Default(.imageSaveDays) var imageSaveDays
    @Default(.proxyServer) var proxyServer
    @Default(.servers) var servers

    @State private var showImport: Bool = false
    @State private var showexportLoading: Bool = false
    @State private var showDriveCheckLoading: Bool = false

    @State private var showDeleteAlert: Bool = false
    @State private var resetAppShow: Bool = false
    @State private var restartAppShow: Bool = false

    @State private var totalSize: UInt64 = 0
    @State private var cacheSize: UInt64 = 0

    @State private var cancelTask: Task<Void, Never>?

    @State private var selectAction: MessageAction? = nil
    @State private var addLoading: Bool = false

    @State private var exampleValue = 10000.0
    var pickerServers: [PushServerModel] {
        [PushServerModel.space] + servers
    }

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
                    allowedContentTypes: [.trnExportType, .sqlite, .propertyList],
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
                    ForEach(ExpirationTime.allCases, id: \.self) { item in
                        Text(item.title)
                            .tag(item)
                    }
                } label: {
                    Label {
                        Text("消息存档")
                    } icon: {
                        Image(systemName: "externaldrive.badge.timemachine")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                messageExpiration == .no ? .red :
                                    (messageExpiration == .forever ? .green : .yellow),
                                Color.primary
                            )
                    }
                }

                Picker(selection: $imageSaveDays) {
                    ForEach(ExpirationTime.allCases, id: \.self) { item in
                        Text(item.title)
                            .tag(item)
                    }
                } label: {
                    Label {
                        Text("图片存档")
                    } icon: {
                        Image(systemName: "externaldrive.badge.timemachine")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                imageSaveDays == .no ? .red :
                                    (imageSaveDays == .forever ? .green : .yellow),
                                Color.primary
                            )
                    }
                }

            } footer: {
                Text("当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
                    .foregroundStyle(.gray)
            }

            Section(header: Text(verbatim: "")) {
                NavigationLink {
                    NoletFileList(rootURL: CONTAINER)
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
                    }
                    .contentShape(Rectangle())
                }

                HStack {
                    Button {
                        guard !showDeleteAlert else { return }
                        self.showDeleteAlert.toggle()
                    } label: {
                        HStack {
                            Spacer()
                            Label("清空缓存数据", systemImage: "trash.circle")
                                .foregroundStyle(.white, Color.primary)
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                                .if(showDriveCheckLoading) {
                                    Label("正在处理数据", systemImage: "slowmo")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.primary)
                                }

                            Spacer()
                        }
                    }
                    .diff { view in
                        Group {
                            if #available(iOS 26.0, *) {
                                view
                                    .buttonStyle(.glassProminent)
                            } else {
                                view
                                    .buttonStyle(BorderedProminentButtonStyle())
                            }
                        }
                    }
                }

                HStack {
                    Button {
                        try? DatabaseManager.shared.dbQueue
                            .vacuum()
                        calculateSize()
                    } label: {
                        HStack {
                            Spacer()
                            Label("整理数据库", systemImage: "arrow.down.doc.fill")
                                .foregroundStyle(.white, Color.primary)
                                .padding(.vertical, 5)
                                .fontWeight(.bold)

                            Spacer()
                        }
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                }

                HStack {
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
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("数据管理")
        .if(selectAction != nil) { view in
            view.deleteTips($selectAction)
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
                                if
                                    let fileURL = NCONFIG.getDir(.sounds),
                                    let cacheURL = NCONFIG.getDir(.tem)
                                {
                                    ImageManager.customCache.clearDiskCache()
                                    manager
                                        .clearContentsOfDirectory(
                                            at: fileURL
                                        )
                                    manager
                                        .clearContentsOfDirectory(
                                            at: cacheURL
                                        )
                                    Defaults[.imageSaves] = []
                                }

                                try? DatabaseManager.shared.dbQueue
                                    .vacuum()

                                Toast.success(title: "清理成功")

                                DispatchQueue.main.async {
                                    self.showDriveCheckLoading = false
                                    calculateSize()
                                }
                            }
                        ),
                        secondaryButton: .cancel()
                    )
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(MessageAction.allCases, id: \.self) { item in
                        if item == .cancel {
                            Section {
                                Button(role: .destructive) {} label: {
                                    Label(item.title, systemImage: "xmark.seal")
                                        .symbolRenderingMode(.palette)
                                        .customForegroundStyle(.accent, .primary)
                                }
                            }
                        } else {
                            Section {
                                Button {
                                    self.selectAction = item
                                } label: {
                                    Label(item.title, systemImage: "trash")
                                        .symbolRenderingMode(.palette)
                                        .customForegroundStyle(.accent, .primary)
                                }
                            }
                        }
                    }
                } label: {
                    Label("按条件删除消息", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                }
            }
        }
        .onChange(of: messageManager.allCount) { _ in
            self.calculateSize()
        }
        .task { calculateSize() }
    }

    fileprivate func resetApp() {
        manager.clearContentsOfDirectory(at: CONTAINER)
        exit(0)
    }

    func calculateSize() {
        if
            let soundsURL = NCONFIG.getDir(.sounds),
            let imageURL = NCONFIG.getDir(.image),
            let cacheFileURL = NCONFIG.getDir(.tem)
        {
            totalSize = manager.calculateDirectorySize(at: CONTAINER)

            cacheSize = manager.calculateDirectorySize(at: soundsURL) + manager
                .calculateDirectorySize(at: imageURL) +
                manager.calculateDirectorySize(at: cacheFileURL)
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
                        throw NoletError.basic("解密失败")
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

                default:
                    try messageManager.importJSONFile(fileURL: url)
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

            try await DatabaseManager.shared.dbQueue.write { db in
                try autoreleasepool {
                    for k in 0..<number {
                        let message = Message(
                            id: UUID().uuidString, createDate: .now,
                            group: "\(k % 50)", title: "\(k) Test",
                            body: "\(body)", level: 1, ttl: 1, isRead: true
                        )
                        try message.insert(db)
                    }
                }
            }
            return true
        } catch {
            logger.error("创建失败")
            return false
        }
    }
}

extension UInt64 {
    func fileSize() -> String {
        if self >= 1_073_741_824 { // 1GB
            return String(format: "%.2fGB", Double(self) / 1_073_741_824)
        } else if self >= 1_048_576 { // 1MB
            return String(format: "%.2fMB", Double(self) / 1_048_576)
        } else if self >= 1024 { // 1KB
            return String(format: "%dKB", self / 1024)
        } else {
            return "\(self)B" // 小于 1KB 直接显示字节
        }
    }
}

// MARK: - MessageAction model

enum MessageAction: CaseIterable, Equatable, Hashable {
    static var allCases: [MessageAction] {
        [.hour(1), .day(1), .week(1), .month(1), .all, .cancel]
    }

    case hour(Int)
    case day(Int)
    case week(Int)
    case month(Int)
    case all
    case cancel
}

extension MessageAction {
    var title: String {
        switch self {
        case .hour(let hour): String(localized: "\(hour)小时前")
        case .day(let day): String(localized: "\(day)天前")
        case .week(let week): String(localized: "\(week)周前")
        case .month(let month): String(localized: "\(month)月前")
        case .all: String(localized: "所有消息")
        case .cancel: String(localized: "取消")
        }
    }

    var date: Date {
        switch self {
        case .hour(let hour): Date().someHourBefore(hour)
        case .day(let day): Date().someDayBefore(day)
        case .week(let week): Date().someDayBefore(week * 7)
        case .month(let month): Date().someDayBefore(month * 30)
        case .all: Date()
        default: Date().s1970
        }
    }
}

extension ExpirationTime {
    var title: String {
        switch self {
        case .no: String(localized: "不保存")
        case .oneDay: String(localized: "1天")
        case .weekDay: String(localized: "1周")
        case .month: String(localized: "1月")
        case .forever: String(localized: "长期")
        }
    }
}

#Preview {
    DataSettingView()
        .environmentObject(AppManager.shared)
}
