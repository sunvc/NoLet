//
//  PushbackManager.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import UIKit
import SwiftUI
import Defaults
import Foundation


class AppManager:  NetworkManager, ObservableObject, @unchecked Sendable {
	static let shared = AppManager()
    
    
    @Published var page:TabPage = .message
	@Published var sheetPage:SubPage = .none
	@Published var fullPage:SubPage = .none
	@Published var scanUrl:String = ""
    @Published var crashLog:String?
    
	@Published var PremiumUser:Bool = false
    
    
    @Published var selectId:String? = nil
    @Published var selectGroup:String? = nil
    @Published var searchText:String = ""
    
    
    @Published var mrouter:[RouterPage] = []
    @Published var srouter:[RouterPage] = []
    @Published var sorouter:[RouterPage] = []
    @Published var prouter:[RouterPage] = []
    
    
    
    
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
	
    private override init() { super.init() }
    
   
    
    
    func restore(address:String, deviceKey:String, sign:String? = nil) async -> Bool{
        let response:baseResponse<String>? = try? await self.fetch(url: address + "/register/\(deviceKey)")
        if let msg = response?.message, let code = response?.code,code == 200, msg == "success"{
            let serever = PushServerModel(url: address,key: deviceKey, sign: sign)
            let success = await self.appendServer(server: serever)
            return success
        }else{
            return false
        }
    }
    
    func registers(msg:Bool = false){
        Task.detached(priority: .userInitiated) {
            let servers = Defaults[.servers]
            let results = await withTaskGroup(of: (Int, PushServerModel).self) { group in
                for (index, server) in servers.enumerated() {
                    group.addTask {
                        let result = await self.register(server: server, msg: msg)
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
                Self.syncLocalToCloud()
            }

        }
    }

    
    func register(server:PushServerModel, reset:Bool = false, msg:Bool = true) async -> PushServerModel{
        var server = server
        
        do{ 
            
            let deviceToken = reset ? UUID().uuidString : Defaults[.deviceToken]
            let params  = DeviceInfo(deviceKey: server.key, deviceToken: deviceToken ).toEncodableDictionary() ?? [:]
            
            let response:baseResponse<DeviceInfo> = try await self.fetch(url: server.url + "/register",method: .POST, params: params, sign: server.sign)
            
            
            if let data = response.data {
                server.key = data.deviceKey
                server.status = true
                
                if msg{
                    if reset{ Toast.info(title: "解绑成功") }else{
                        Toast.success(title: "注册成功")
                    }
                }
            }else{
                server.status = false
                server.voice = false
                if msg{
                    Toast.error(title: "注册失败")
                }
            }
            
            return server
        }catch{
            NLog.error(error.localizedDescription)
            return server
        }
    }
    

    func appendServer(server:PushServerModel) async -> Bool{
        
        guard !appending && !Defaults[.deviceToken].isEmpty else { return false}
        self.appending = true
        
        guard !Defaults[.servers].contains(where: {$0.key == server.key && $0.url == server.url})else{
            Toast.error(title: "服务器已存在")
            return false
        }
        
        
        let server = await self.register(server: server)
        if server.status {
            await MainActor.run {
                Defaults[.servers].insert(server, at: 0)
                Self.syncLocalToCloud()
            }
            Toast.success(title: "添加成功")
        }
        self.appending = false
        return server.status
    }
    
    class func syncLocalToCloud() {
        let locals = Defaults[.servers]
        var clouds = Defaults[.cloudServers]

        let cloudServerSet = Set(clouds.map { $0.server })

        let newItems = locals.filter { !cloudServerSet.contains($0.server) }

        if !newItems.isEmpty {
            clouds.append(contentsOf: newItems)
            Defaults[.cloudServers] = clouds
        }
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
        case .server(let url, let key, let sign):
            Task.detached(priority: .userInitiated) {
                let crypto = CryptoModelConfig(inputText: sign ?? "", sign: true)?.obfuscator()
                let server = PushServerModel(url: url,key: key ?? "", sign: crypto)
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
        case .page(page: let page,title: let title, data: let data):
            switch page{
            case .widget:
                Task{@MainActor in
                    self.page = .setting
                    self.router = [.more, .widget(title: title, data: data)]
                }
            case .icon:
                self.page = .setting
                self.sheetPage = .cloudIcon
            }
            return nil
        default:
            return url

        }
    }
    
}


extension AppManager{
    /// open app settings
    class func openSetting(){
        AppManager.openUrl(url: URL(string: UIApplication.openSettingsURLString)!)
    }
    /// Open a URL or handle a fallback if the URL cannot be opened
    /// - Parameters:
    ///   - url: The URL to open
    ///   - unOpen: A closure called when the URL cannot be opened, passing the URL as an argument
    class func openUrl(url: URL) {
        
        if url.absoluteString.hasHttp() && Defaults[.defaultBrowser] == .app {
            AppManager.shared.fullPage = .web(url.absoluteString)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    class func openUrl(url: String) {
        if let url = URL(string: url) {
            self.openUrl(url: url)
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
                if let url = params["text"],let urlResponse = URL(string: url), url.hasHttp() {
                    let (result, key) = urlResponse.findNameAndKey()
                    return .server(url: result, key:key, sign: params["sign"])
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
                /// pb://openPage?type=widget&page=small
                if let page = params["page"], let page = OutDataType.pageType(rawValue: page){
                    return .page(page: page,title: params["title"], data: params["data"] ?? "")
                }
            default:
                break
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
        guard let path = BaseConfig.configPath else{ return nil }
        do{
            let data = try Data(contentsOf: path)
            if let cryptData = CryptoManager(.data).encrypt(inputData: data){

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

    
}
