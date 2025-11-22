//
//  Manager.swift
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

import UIKit
import SwiftUI
import Defaults
import Foundation
import StoreKit
import Zip



final class AppManager:  NetworkManager, ObservableObject, @unchecked Sendable {
    static let shared = AppManager()
    
    
    @Published var page:      TabPage = .message
    @Published var sheetPage: SubPage = .none
    @Published var fullPage:  SubPage = .none
    
    
    @Published var selectId:    String? = nil
    @Published var selectGroup: String? = nil
    @Published var searchText:  String = ""
    
    
    @Published var mrouter:  [RouterPage] = []
    @Published var srouter:  [RouterPage] = []
    @Published var sorouter: [RouterPage] = []
    @Published var prouter:  [RouterPage] = []
    
    @Published var isWarmStart:Bool = false
    
    @Published var selectMessage:Message? = nil
    @Published var selectPoint:CGPoint = .zero
    /// 首页彩色框
    @Published var isLoading:Bool = false
    @Published var inAssistant:Bool = false
    
    /// 问智能助手
    @Published var askMessageId:String? = nil
    /// 开始播放语音
    @Published var speaking:Bool = false
    
    @Published var customServerURL:String = ""
    @Published var VipInfo: SubscribeUser? = nil
    
    var router:[RouterPage] = []{
        didSet{
            if .ISPAD{
                self.prouter = router
            }else{
                
                switch page {
                case .message:
                    self.mrouter = router
                case .setting:
                    self.srouter = router
                case .search:
                    self.sorouter = router
                    
                }
            }
        }
    }
    
    var fullShow:Binding<Bool>{
        Binding {
            self.fullPage != .none
        } set: { _ in
            self.fullPage = .none
        }
    }
    
    var sheetShow:Binding<Bool>{
        Binding {
            self.sheetPage != .none
        } set: { _ in
            self.sheetPage = .none
        }
    }
    
    
    private var appending:Bool = false
    
    private override init() {
        super.init()
        updates = newTransactionListenerTask()
    }
    
    deinit {  updates?.cancel() }
    
    var updates: Task<Void, Never>? = nil
    
    
    
    
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

    
    func HandlerOpenUrl(url:String) -> String?{
        
        switch self.outParamsHandler(address: url) {
        case .crypto(let text):
            NLog.log(text)
            if let config = CryptoModelConfig(inputText: text){
                Task{@MainActor in
                    self.page = .setting
                    self.router = [.crypto]
                    if !Defaults[.cryptoConfigs].contains(where: {$0 == config}){
                        Defaults[.cryptoConfigs].append(config)
                        Toast.info(title: "添加成功")
                    }else{
                        Toast.info(title: "配置已存在")
                    }
                }
            }
            return nil
        case .server(let url, let key,let group, let sign):
            Task.detached(priority: .userInitiated) {
                let crypto = CryptoModelConfig(inputText: sign ?? "", sign: true)?.obfuscator()
                let server = PushServerModel(url: url,key: key,group: group, sign: crypto)
                let success = await self.appendServer(server: server)
                if success{
                    await MainActor.run {
                        self.page = .setting
                        self.router = [.server]
                    }
                }
            }
            return nil
        case .assistant(let text):
            if let account = AssistantAccount(base64: text){
                Task{@MainActor in
                    self.page = .setting
                    self.router = [.assistantSetting(account)]
                    
                }
            }
            return nil
        case .cloudIcon:
            self.page = .setting
            self.sheetPage = .cloudIcon
            return nil
        default:
            return url
            
        }
    }
    
}


extension AppManager{
    /// open app settings
    class func openSetting(){
        AppManager.openUrl(url: URL(string: UIApplication.openSettingsURLString)!, .safari)
    }
    /// Open a URL or handle a fallback if the URL cannot be opened
    /// - Parameters:
    ///   - url: The URL to open
    ///   - unOpen: A closure called when the URL cannot be opened, passing the URL as an argument
    class func openUrl(url: URL, _ mode: DefaultBrowserModel) {
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
    
    class func openUrl(url: String, _ mode:DefaultBrowserModel) {
        if let url = URL(string: url) {
            self.openUrl(url: url, mode)
        }
    }
    
    
    
    class func hideKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to: nil,from: nil,for: nil)
    }
    
    
    // MARK: 注册设备以接收远程推送通知
    func registerForRemoteNotifications(_ isCriticalAlert:Bool = false) async -> Bool {
        
        var auths: UNAuthorizationOptions = [.alert, .sound, .badge,
                                             .providesAppNotificationSettings]
        if isCriticalAlert{
            auths.insert(.criticalAlert)
        }
        
        
        guard let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: auths)
        else { return false}
        
        
        
        if granted {
            // 如果授权，注册设备接收推送通知
            Task{@MainActor in
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
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            
            for fileURL in contents {
                do{
                    try fileManager.removeItem(at: fileURL)
                    NLog.log("✅ 删除: \(fileURL.lastPathComponent)")
                }catch{
                    NLog.error("❌ 清空失败: \(error.localizedDescription)")
                }
            }
            
            NLog.log("🧹 清空完成：\(url.path)")
        } catch {
            NLog.error("❌ 清空失败: \(error.localizedDescription)")
        }
    }
    
    func calculateDirectorySize(at url: URL) -> UInt64 {
        var totalSize: UInt64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    if resourceValues.isRegularFile == true {
                        if let fileSize = resourceValues.fileSize {
                            totalSize += UInt64(fileSize)
                        }
                    }
                } catch {
                    NLog.error("❗️获取文件大小失败: \(fileURL.lastPathComponent) - \(error.localizedDescription)")
                }
            }
        }
        
        return totalSize
    }
    
    
    func outParamsHandler(address:String) -> OutDataType{
        
        guard let url = URL(string: address), let scheme = url.scheme?.lowercased() else {
            return .text(address)
        }
        
        if PBScheme.schemes.contains(scheme),
           let host = url.host(),
           let host = PBScheme.HostType(rawValue: host),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false){
            let params = components.getParams()
            
            switch host {
            case .server:
                if let url = params["text"],let urlResponse = URL(string: url), url.hasHttp {
                    let (result, key) = urlResponse.findNameAndKey()
                    return .server(url: result, key:key, group: params["group"], sign: params["sign"])
                }
            case .crypto:
                if let config = params["text"]{
                    return .crypto(config)
                }
            case .assistant:
                if let config = params["text"]{
                    return .assistant(config)
                }
                
            case .openPage:
                /// pb://openPage
                if let _ = params["page"]{
                    return .cloudIcon
                }
            }
            
        }
        
        return .otherUrl(address)
    }
    
    func printDirectoryContents(at path: String, indent: String = "") {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
            NLog.error("\(indent)❌ Path not found: \(path)")
            return
        }
        
        if isDir.boolValue {
            NLog.log("\(indent)📂 \(URL(fileURLWithPath: path).lastPathComponent)")
            
            if let contents = try? fileManager.contentsOfDirectory(atPath: path) {
                for item in contents {
                    let itemPath = (path as NSString).appendingPathComponent(item)
                    printDirectoryContents(at: itemPath, indent: indent + "    ")
                }
            }
        } else {
            if let attrs = try? fileManager.attributesOfItem(atPath: path),
               let fileSize = attrs[.size] as? UInt64 {
                let sizeMB = Double(fileSize) / (1024.0 * 1024.0)
                NLog.log("\(indent)📄 \(URL(fileURLWithPath: path).lastPathComponent) (\(String(format: "%.2f", sizeMB)) MB)")
            }
        }
    }
    
    static func createDatabaseFileTem() -> URL?{
        let path = NCONFIG.configPath
        do{
            let data = try Data(contentsOf: path)
            
            if let cryptData = CryptoManager(.data).encrypt(data: data){
                
                let pathTem = FileManager.default.temporaryDirectory.appendingPathComponent(
                    path.lastPathComponent,
                    conformingTo: .data
                )
                try cryptData.write(to: pathTem)
                return pathTem
            }
        }catch{
            NLog.error("配置文件加密失败")
        }
        
        return nil
    }
    
    
    static func runQuick(_ action: String) -> Bool{
        switch QuickAction(rawValue: action.lowercased()){
        case .assistant:
            Self.shared.router = [.assistant]
        case .scan:
            Self.shared.fullPage = .scan
        default:
            return false
        }
        return true
    }
    
}

extension AppManager{
    
    func restore(address:String, deviceKey:String, sign:String? = nil) async -> Bool{
        do{
            let response:baseResponse<String> =
            try await self.fetch(url: address, path: "/register/\(deviceKey)")
            
            
            guard 200...299 ~= response.code else{
                Toast.shared.present(title: response.message, symbol: .error)
                return false
            }
            
            
            if response.message == "success"{
                let serever = PushServerModel(url: address,key: deviceKey, sign: sign)
                let success = await self.appendServer(server: serever)
                return success
            }else{
                return false
            }
        }catch{
            Toast.error(title: "数据不正确")
            return false
        }
        
    }
    
    func registers(){
        Task.detached(priority: .userInitiated) {
            let servers = Defaults[.servers]
            let results = await withTaskGroup(of: (Int, PushServerModel).self) { group in
                for (index, server) in servers.enumerated() {
                    group.addTask {
                        let result = await self.register(server: server, msg: false)
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
            
            if results.filter({$0.status}).count == servers.count{
                Toast.success(title: "注册成功")
            }else if results.filter({!$0.status}).count == servers.count{
                Toast.error(title: "注册失败")
            }else{
                Toast.info(title: "部分注册成功")
            }
            
            await MainActor.run {
                Defaults[.servers] = results
            }
            
        }
    }
    
    func register(server:PushServerModel, reset:Bool = false, msg:Bool = false) async -> PushServerModel{
        var server = server
        
        if  server.name == "uuneo.com" || server.name == "push.uuneo.com"{
            server.url = NCONFIG.server
        }
        
        do{
            
            let deviceToken = reset ? UUID().uuidString : Defaults[.deviceToken]
            let params  = DeviceInfo(deviceKey: server.key, deviceToken: deviceToken, group: server.group ).toEncodableDictionary() ?? [:]
            
            let response:baseResponse<DeviceInfo> = try await self.fetch(url: server.url,
                                                                         path: "/register",
                                                                         method: .POST,
                                                                         params: params)
            
            guard 200...299 ~= response.code else{
                Toast.shared.present(title: response.message, symbol: .error)
                throw "erroe"
            }

            if let data = response.data {
                server.key = data.deviceKey
                server.status = true
                if msg{
                    if reset{ Toast.info(title: "解绑成功") }else{
                        Toast.success(title: "注册成功")
                    }
                }
            }else{
                
                if msg{
                    Toast.error(title: "注册失败")
                }
                throw "erroe"
            }
            Self.syncLocalToCloud()
            return server
        }catch{
            server.status = false
            server.voice = false
            NLog.error(error.localizedDescription)
            return server
        }
    }
    
    func appendServer(server:PushServerModel, reset: Bool = false) async -> Bool{
        
        guard !appending && !Defaults[.deviceToken].isEmpty else { return false}
        self.appending = true
        
        var serverCopy = server
        if reset {  
            serverCopy.key = ""
            serverCopy.id = UUID().uuidString
        }
        
        guard !Defaults[.servers].contains(where: {$0 == serverCopy})else{
            Toast.error(title: "服务器已存在")
            return false
        }
        
        
        let serverNew = await self.register(server: serverCopy, msg: true)
        if serverNew.status {
            if reset{
                /// 重置后清空老的token
                _ = await self.register(server: server, reset: true)
            }
           
            await MainActor.run {
                if reset{
                    Defaults[.servers].removeAll(where: {$0 == server})
                }
                Defaults[.servers].insert(serverNew, at: 0)
            }
            Toast.success(title: "添加成功")
        }
        Self.syncLocalToCloud()
        self.appending = false
        return serverNew.status
    }
}


extension AppManager{
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
    
    
    private func handle(updatedTransaction verificationResult: VerificationResult<StoreKit.Transaction>) {
    
        
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }
        
        if let revocationDate = transaction.revocationDate {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about
            // the revoked transaction.
            if let reason = transaction.revocationReason {
                NLog.log("Transaction revoked due to: \(revocationDate) - \(reason) ")
            }
        
            if self.VipInfo?.productID == transaction.productID{
                self.VipInfo = nil
            }
            return
    
        } else if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            // Do nothing, this subscription is expired.
            if self.VipInfo?.productID == transaction.productID{
                self.VipInfo = nil
            }
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            return
        }else{
            DispatchQueue.main.async{
                self.VipInfo = SubscribeUser( expirationDate: transaction.expirationDate,
                                              productID: transaction.productID)
            }
        }
    }
}


struct SubscribeUser: Codable, Hashable, Identifiable{
    var id: String = UUID().uuidString
    var expirationDate: Date?
    var productID: String = ""
    
    var isVip: Bool{
        if let expirationDate{
            return expirationDate > Date() && level != .none
        }
        return false
    }
    
    var level:levelType{
        if productID == StoreProduct.monthly{
            return .monthly
        }else if productID == StoreProduct.yearly{
            return .yearly
        }else if productID == StoreProduct.once{
            return .onece
        }else{
            return .none
        }
    }
    
    enum levelType{
        case monthly
        case yearly
        case onece
        case none
    }
}


extension AppManager{
    func downloadSounds() async throws {
        
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("sounds.zip")
        
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        var request = URLRequest(url: NCONFIG.soundsUrl.url)
        request.assumesHTTP3Capable = true
        
        let (data, response) = try await session.download(for: request)
        
        guard let response = response as? HTTPURLResponse else{ throw NetworkManager.APIError.invalidURL}
        
        guard 200...299 ~= response.statusCode else{
            throw NetworkManager.APIError.invalidCode(response.statusCode)
        }
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: data, to: destinationURL)
        
        let result = try Zip.quickUnzipFile(destinationURL)
 
        if let soundsUrl = NCONFIG.getDir(.sounds){
            moveAllFiles(from: result, to: soundsUrl, overwrite: true)
        }
        
        AudioManager.shared.updateFileList()
        
        try? FileManager.default.removeItem(at: result)
        try? FileManager.default.removeItem(at: destinationURL)
    }
    
    func moveAllFiles(from sourceDir: URL, to destinationDir: URL, overwrite: Bool = false) {
        let fileManager = FileManager.default

        // 确保目标目录存在
        if !fileManager.fileExists(atPath: destinationDir.path) {
            do {
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            } catch {
                print("创建目标目录失败: \(error)")
                return
            }
        }

        // 获取源目录下的所有内容
        guard let enumerator = fileManager.enumerator(at: sourceDir,
                                                      includingPropertiesForKeys: [.isDirectoryKey],
                                                      options: [.skipsHiddenFiles]) else {
            print("无法访问源目录")
            return
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
                if resourceValues.isDirectory == true {
                    // 是文件夹，跳过
                    continue
                }

                // 构建目标路径
                let destinationURL = destinationDir.appendingPathComponent(fileURL.lastPathComponent)

                // 如果目标文件已存在
                if fileManager.fileExists(atPath: destinationURL.path) {
                    if overwrite {
                        try fileManager.removeItem(at: destinationURL)
                    } else {
                        print("跳过已存在文件: \(destinationURL.lastPathComponent)")
                        continue
                    }
                }

                // 移动文件
                try fileManager.moveItem(at: fileURL, to: destinationURL)
                print("已移动文件: \(fileURL.lastPathComponent)")

            } catch {
                print("移动文件出错: \(fileURL.lastPathComponent), 错误: \(error)")
            }
        }
    }
}
