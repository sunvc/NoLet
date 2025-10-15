//
//  PushToDeviceIntent.swift
//  pushback
//
//  Created by lynn on 2025/4/13.
//

import AppIntents

struct PushToDeviceIntent: AppIntent {
    
    static var title: LocalizedStringResource = "发送通知到设备"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "服务器", optionsProvider: ServerAddressProvider())
    var address: String
    
    
    @Parameter(title: "通知级别", optionsProvider: LevelClassProvider())
    var level: String?
    
    @Parameter(title: "推送样式", optionsProvider: CategoryParamsProvider())
    var category: String?
    
    @Parameter( title: "铃声", optionsProvider: SoundOptionsProvider())
    var sound: String?
    
    @Parameter(title: "持续响铃")
    var isCall: Bool
    
    @Parameter(title: "重要通知音量", optionsProvider: VolumeOptionsProvider())
    var volume: Int?
    
    @Parameter(title: "加密", default: false)
    var cipher: Bool
    
    @Parameter(title: "推送图标")
    var icon: URL?
    
    @Parameter(title: "推送图片")
    var image: URL?
    
    @Parameter(title: "URL")
    var url: URL?
    
    @Parameter(title: "群组", default: "默认")
    var group: String?
    
    @Parameter(title: "标题")
    var title: String?
    
    @Parameter(title: "副标题")
    var subTitle: String?
    
    @Parameter(title: "内容")
    var body: String?

   

    
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        
        guard let address = URL(string: address) else {
            throw "Invalid URL"
        }
        
        var params: [String: Any] = [:]
        
        if let level, !level.isEmpty,let level = LevelTitle.rawValue(fromDisplayName: level) {
            
            params["level"] = level
            
            if level == LevelTitle.critical.name{
                params["volume"] = volume
            }
        }
        
        if let sound, !sound.isEmpty{
            params["sound"] = sound
        }
        
        if let group, !group.isEmpty{
            params["group"] = group
        }
        
        if let title, !title.isEmpty{
            params["title"] = title
        }
        
        if let subTitle, !subTitle.isEmpty{
            params["subTitle"] = subTitle
        }
        
        if let body, !body.isEmpty{
            params["body"] = body
        }
        
        if isCall{
            params["call"] = "1"
        }
        
        if let icon{
            params["icon"] = icon.absoluteString
        }
        
        if let image{
            params["image"] = image.absoluteString
        }
        
        if let category,category == "Markdown"{
            params["category"] = Identifiers.markdown.rawValue
        }
        
        if let url{
            params["url"] = url.absoluteString
        }
        
        if cipher {
            
            let cryptoConfigs = Defaults[.cryptoConfigs]
            guard let field = cryptoConfigs.first else { return .result(value: false) }
            
            
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            guard let cipherResult = CryptoManager(field).encrypt(jsonData) else {
                return .result(value: false)
            }
            params = ["cipherText": cipherResult]
        }
        
        let http = NetworkManager()
        
        let res:APIPushToDeviceResponse? = try await http.fetch(url: address.absoluteString, method: .POST, params: params)
        
        
        return .result(value: res?.code == 200)
    }
    
    
}

