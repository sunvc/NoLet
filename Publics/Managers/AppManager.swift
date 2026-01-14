//
//  AppManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/26.
//

import Defaults
import Foundation
import StoreKit
import SwiftUI
import UIKit
import Zip

final class AppManager: NetworkManager, ObservableObject, Sendable {
    static let shared = AppManager()

    @Published var page: TabPage = .message
    @Published private(set) var sheetPage: SubPage? = nil
    @Published private(set) var fullPage: SubPage? = nil

    @Published var selectID: String? = nil
    @Published var selectGroup: String? = nil
    @Published var searchText: String = ""

    @Published var mrouter: [RouterPage] = []
    @Published var srouter: [RouterPage] = []
    @Published var arouter: [RouterPage] = []
    @Published var prouter: [RouterPage] = []

    @Published var historyPage: TabPage = .message
    @Published var isWarmStart: Bool = false

    @Published var selectMessage: Message? = nil
    @Published var selectPoint: CGPoint = .zero
    /// 首页彩色框
    @Published var isLoading: Bool = false
    @Published var inAssistant: Bool = false

    /// 问智能助手
    @Published var askMessageID: String? = nil

    @Published var customServerURL: String = ""
    @Published var VipInfo: SubscribeUser? = nil

    @Published var servers: [PushServerModel] = []

    var router: [RouterPage] = [] {
        didSet {
            if .ISPAD {
                prouter = router
            } else {
                switch page {
                case .message:
                    mrouter = router
                case .setting:
                    srouter = router
                case .assistant:
                    arouter = router
                }
            }
        }
    }

    private var appending: Bool = false

    private override init() {
        super.init()
        updates = newTransactionListenerTask()
    }

    @MainActor
    deinit {
        self.updates?.cancel()
    }

    func open(sheet: SubPage?) {
        Task { @MainActor in
            guard sheet != sheetPage else { return }
            if sheetPage == nil || sheet == nil {
                sheetPage = sheet
            } else {
                self.sheetPage = nil
                try? await Task.sleep(for: .seconds(0.5))
                self.sheetPage = sheet
            }
        }
    }

    func open(full: SubPage?) {
        Task { @MainActor in
            guard full != fullPage else { return }
            if fullPage == nil || full == nil {
                fullPage = full
            } else {
                self.fullPage = nil
                try? await Task.sleep(for: .seconds(0.5))
                self.fullPage = full
            }
        }
    }

    var updates: Task<Void, Never>?

    class func syncLocalToCloud() {
        let locals = Defaults[.servers]
        let clouds = Defaults[.cloudServers]

        // 过滤掉有 group 的
        let filteredLocals = locals.filter { $0.group?.isEmpty ?? true }
        let filteredClouds = clouds.filter { $0.group?.isEmpty ?? true }

        // 合并并去重（前提是 PushServerModel 遵守 Hashable）
        let merged = Array(Set(filteredLocals + filteredClouds))

        // 同步回云端
        Defaults[.cloudServers] = merged
    }

    func HandlerOpenURL(url: String) -> String? {
        switch outParamsHandler(address: url) {
        case .crypto(let text):
            logger.info("\(text)")
            if let config = CryptoModelConfig(inputText: text) {
                Task { @MainActor in
                    self.page = .setting
                    self.router = [.crypto]
                    if !Defaults[.cryptoConfigs].contains(where: { $0 == config }) {
                        Defaults[.cryptoConfigs].append(config)
                        Toast.info(title: "添加成功")
                    } else {
                        Toast.info(title: "配置已存在")
                    }
                }
            }
            return nil
        case .server(let url, let key, let group, let sign):
            Task.detached(priority: .userInitiated) {
                let crypto = await CryptoModelConfig(inputText: sign ?? "", sign: true)?
                    .obfuscator()
                let server = PushServerModel(url: url, key: key, group: group, sign: crypto)
                let success = await self.appendServer(server: server)
                if success {
                    await MainActor.run {
                        self.page = .setting
                        self.router = [.server]
                    }
                }
            }
            return nil
        case .assistant(let text):
            if let account = AssistantAccount(base64: text) {
                Task { @MainActor in
                    self.page = .setting
                    self.router = [.noletChatSetting(account)]
                }
            }
            return nil
        case .cloudIcon:
            page = .setting
            sheetPage = .cloudIcon
            return nil
        default:
            return url
        }
    }
}

extension AppManager {
    /// open app settings
    class func openSetting() {
        AppManager.openURL(url: URL(string: UIApplication.openSettingsURLString)!, .safari)
    }

    /// Open a URL or handle a fallback if the URL cannot be opened
    /// - Parameters:
    ///   - url: The URL to open
    ///   - unOpen: A closure called when the URL cannot be opened, passing the URL as an argument
    class func openURL(url: URL, _ mode: DefaultBrowserModel) {
        guard url.absoluteString.hasHttp else {
            // 非 http/https 直接打开
            UIApplication.shared.open(url, options: [:])
            return
        }

        // 优先尝试 Universal Link
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
            guard !success else { return } // 成功唤起 App，无需 fallback

            switch (Defaults[.defaultBrowser], mode) {
            case (.app, _):
                AppManager.shared.fullPage = .web(url)
            case (.safari, _):
                UIApplication.shared.open(url, options: [:])
            case (.auto, .app):
                AppManager.shared.fullPage = .web(url)
            case (.auto, .safari):
                UIApplication.shared.open(url, options: [:])
            case (.auto, .auto):
                UIApplication.shared.open(url, options: [:])
            }
        }
    }

    class func openURL(url: String, _ mode: DefaultBrowserModel) {
        if let url = URL(string: url) {
            openURL(url: url, mode)
        }
    }

    class func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    // MARK: 注册设备以接收远程推送通知

    func registerForRemoteNotifications(_ isCriticalAlert: Bool = false) async -> Bool {
        var auths: UNAuthorizationOptions = [
            .alert,
            .sound,
            .badge,
            .providesAppNotificationSettings,
        ]
        if isCriticalAlert {
            auths.insert(.criticalAlert)
        }

        guard let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: auths)
        else { return false }

        if granted {
            // 如果授权，注册设备接收推送通知
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        } else {
            Toast.error(title: "没有打开推送")
        }
        return granted
    }

    func clearContentsOfDirectory(at url: URL) {
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            )

            for fileURL in contents {
                do {
                    try fileManager.removeItem(at: fileURL)
                    logger.info("✅ 删除: \(fileURL.lastPathComponent)")
                } catch {
                    logger.fault("清空失败: \(error)")
                }
            }

            logger.info("🧹 清空完成：\(url.path)")
        } catch {
            logger.fault("清空失败: \(error)")
        }
    }

    func calculateDirectorySize(at url: URL) -> UInt64 {
        var totalSize: UInt64 = 0

        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [],
            errorHandler: nil
        ) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [
                        .isRegularFileKey,
                        .fileSizeKey,
                    ])
                    if resourceValues.isRegularFile == true {
                        if let fileSize = resourceValues.fileSize {
                            totalSize += UInt64(fileSize)
                        }
                    }
                } catch {
                    logger.error(
                        "❌获取文件大小失败: \(fileURL.lastPathComponent) - \(error)"
                    )
                }
            }
        }

        return totalSize
    }

    func outParamsHandler(address: String) -> OutDataType {
        guard let url = URL(string: address), let scheme = url.scheme?.lowercased() else {
            return .text(address)
        }

        if PBScheme.schemes.contains(scheme),
           let host = url.host(),
           let host = PBScheme.HostType(rawValue: host),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        {
            let params = components.getParams()

            switch host {
            case .server:
                if let url = params["text"], let urlResponse = URL(string: url), url.hasHttp {
                    let (result, key) = urlResponse.findNameAndKey()
                    return .server(
                        url: result,
                        key: key,
                        group: params["group"],
                        sign: params["sign"]
                    )
                }
            case .crypto:
                if let config = params["text"] {
                    return .crypto(config)
                }
            case .assistant:
                if let config = params["text"] {
                    return .assistant(config)
                }
            case .openPage:
                /// pb://openPage
                if let _ = params["page"] {
                    return .cloudIcon
                }
            }
        }

        return .otherURL(address)
    }

    func printDirectoryContents(at path: String, indent: String = "") {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
            logger.error("\(indent)❌ Path not found: \(path)")
            return
        }

        if isDir.boolValue {
            logger.info("\(indent)📂 \(URL(fileURLWithPath: path).lastPathComponent)")

            if let contents = try? fileManager.contentsOfDirectory(atPath: path) {
                for item in contents {
                    let itemPath = (path as NSString).appendingPathComponent(item)
                    printDirectoryContents(at: itemPath, indent: indent + "    ")
                }
            }
        } else {
            if let attrs = try? fileManager.attributesOfItem(atPath: path),
               let fileSize = attrs[.size] as? UInt64
            {
                let sizeMB = Double(fileSize) / (1024.0 * 1024.0)
                logger
                    .info(
                        "\(indent)📄 \(URL(fileURLWithPath: path).lastPathComponent) (\(String(format: "%.2f", sizeMB)) MB)"
                    )
            }
        }
    }

    static func createDatabaseFileTem() -> URL? {
        let path = NCONFIG.configPath
        do {
            let data = try Data(contentsOf: path)

            if let cryptData = CryptoManager(.data).encrypt(data: data) {
                let pathTem = FileManager.default.temporaryDirectory.appendingPathComponent(
                    path.lastPathComponent,
                    conformingTo: .data
                )
                try cryptData.write(to: pathTem)
                return pathTem
            }
        } catch {
            logger.fault("配置文件加密失败: \(error)")
        }

        return nil
    }

    static func runQuick(_ action: String) -> Bool {
        switch QuickAction(rawValue: action.lowercased()) {
        case .assistant:
            shared.page = .assistant
        case .scan:
            shared.fullPage = .scan
        default:
            return false
        }
        return true
    }
}

extension AppManager {
    func restore(address: String, deviceKey: String, sign: String? = nil) async -> Bool {
        do {
            let response: baseResponse<String> =
                try await fetch(
                    url: address,
                    path: "/register/\(deviceKey)",
                    headers: CryptoManager.signature(sign: sign, server: deviceKey)
                )

            guard 200...299 ~= response.code else {
                Toast.shared.present(title: response.message, symbol: .error)
                return false
            }

            if response.message == "success" {
                return await appendServer(server: PushServerModel(
                    url: address,
                    key: deviceKey,
                    sign: sign
                ))
            } else {
                return false
            }
        } catch {
            Toast.error(title: "数据不正确")
            return false
        }
    }

    func registers() async {
        guard Defaults[.servers].count > 0 else { return }
        let servers = Defaults[.servers]
        let results = await withTaskGroup(of: (Int, PushServerModel).self) { group in
            for (index, server) in servers.enumerated() {
                group.addTask {
                    let result = await self.register(server: server)
                    return (index, result)
                }
            }

            var tmp: [(Int, PushServerModel)] = []
            for await pair in group {
                tmp.append(pair)
            }
            // 按 index 排序，保证和 servers 顺序一致
            return tmp.sorted { $0.0 < $1.0 }.map { $0.1 }
        }

        await MainActor.run {
            Defaults[.servers] = results
        }
    }

    func register(
        server: PushServerModel,
        reset: Bool = false
    ) async -> PushServerModel {
        var server = server

        if server.name == "uuneo.com" || server.name == "push.uuneo.com" {
            server.url = NCONFIG.server
        }

        do {
            let deviceToken = reset ? UUID().uuidString : Defaults[.deviceToken]
            let params = DeviceInfo(
                deviceKey: server.key,
                deviceToken: deviceToken,
                group: server.group
            ).toEncodableDictionary() ?? [:]

            let response: baseResponse<DeviceInfo> = try await fetch(
                url: server.url,
                path: "/register",
                method: .POST,
                params: params,
                headers: CryptoManager.signature(sign: server.sign, server: server.key)
            )

            guard 200...299 ~= response.code else {
                Toast.shared.present(title: response.message, symbol: .error)
                throw response.message
            }

            if let data = response.data {
                server.key = data.deviceKey
                server.status = true
            }

            Self.syncLocalToCloud()
            return server
        } catch {
            server.status = false
            logger.fault("\(error)")
            return server
        }
    }

    func appendServer(server: PushServerModel, reset: Bool = false) async -> Bool {
        guard !appending && !Defaults[.deviceToken].isEmpty else { return false }
        appending = true

        var serverCopy = server
        if reset {
            serverCopy.key = ""
            serverCopy.id = UUID().uuidString
        }

        guard !Defaults[.servers].contains(where: { $0 == serverCopy }) else {
            Toast.error(title: "服务器已存在")
            return false
        }

        let serverNew = await register(server: serverCopy)
        if serverNew.status {
            if reset {
                /// 重置后清空老的token
                _ = await register(server: server, reset: true)
            }

            await MainActor.run {
                if reset {
                    Defaults[.servers].removeAll(where: { $0 == server })
                }
                Defaults[.servers].insert(serverNew, at: 0)
            }

            if let index = Defaults[.servers].firstIndex(where: { $0.id == serverNew.id }) {
                Defaults[.servers][index] = serverNew
            }
            Toast.success(title: "添加成功")
            Self.syncLocalToCloud()
        } else {
            Toast.success(title: "注册失败")
        }

        appending = false
        return serverNew.status
    }
}

extension AppManager {
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                self.handle(updatedTransaction: verificationResult)
            }

            for await result in Transaction.currentEntitlements {
                self.handle(updatedTransaction: result)
            }
        }
    }

    private func handle(updatedTransaction verificationResult: VerificationResult<StoreKit
            .Transaction>)
    {
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }

        if let revocationDate = transaction.revocationDate {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about
            // the revoked transaction.
            if let reason = transaction.revocationReason {
                logger.info("Transaction revoked due to: \(revocationDate) - \(String(describing: reason)) ")
            }

            if VipInfo?.productID == transaction.productID {
                VipInfo = nil
            }
            return

        } else if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            // Do nothing, this subscription is expired.
            if VipInfo?.productID == transaction.productID {
                VipInfo = nil
            }
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            return
        } else {
            DispatchQueue.main.async {
                self.VipInfo = SubscribeUser(
                    expirationDate: transaction.expirationDate,
                    productID: transaction.productID
                )
            }
        }
    }

    nonisolated static func syncServer() async {
        let pushServerDatas =
            Array(await Set<PushServerModel>(Defaults[.servers] + Defaults[.cloudServers]))

        let serverName = await CloudManager.serverName
        let datas = pushServerDatas.compactMap { server in
            server.toCKRecord(recordType: serverName)
        }

        let records = await CloudManager.shared.synchronousServers(from: datas)
            .compactMap { record in
                PushServerModel(from: record)
            }

        Task { @MainActor in
            AppManager.shared.servers = records
        }
    }
}

extension AppManager {
    enum OutDataType {
        case text(String)
        case crypto(String)
        case server(url: String, key: String, group: String?, sign: String?)
        case otherURL(String)
        case assistant(String)
        case cloudIcon
    }

    struct SubscribeUser: Codable, Hashable, Identifiable {
        var id: String = UUID().uuidString
        var expirationDate: Date?
        var productID: String = ""

        var isVip: Bool {
            if let expirationDate {
                return expirationDate > Date() && level != .none
            }
            return false
        }

        var level: levelType {
            if productID == StoreProduct.monthly {
                return .monthly
            } else if productID == StoreProduct.yearly {
                return .yearly
            } else if productID == StoreProduct.once {
                return .onece
            } else {
                return .none
            }
        }

        enum levelType {
            case monthly
            case yearly
            case onece
            case none
        }
    }
}
