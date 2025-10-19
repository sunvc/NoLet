//
//  ParamsModel.swift
//  NoLet
//
//  Created by lynn on 2025/4/28.
//
import SwiftUI
import Defaults


extension Defaults.Keys {
    static let exampleCustom = Key<PushParams>(.exampleCustom, PushParams.defaultData())
}

struct PushParams: Codable, Defaults.Serializable {
    var id:String = UUID().uuidString
    var server:String = ""
    var group:String = String(localized: "默认")
    var title:String = String(localized: "测试标题")
    var subTitle:String = String(localized: "测试副标题")
    var body:String = String(localized: "测试内容")
    var sound:String = "xiu"
    var call:String = "0"
    var url:String = ""
    var icon:String = BaseConfig.logoImage
    var image:String = BaseConfig.ogImage
    var cipherText:String = ""
    var category:Identifiers = .myNotificationCategory
    var level:LevelTitle = .timeSensitive
    var volume:Double = 5
    var ttl:Int = 999
    var badge:Int = 0
    
    static func defaultData() -> PushParams{
        var data = PushParams()
        if let server = Defaults[.servers].first{
            data.server = server.server
        }
        return data
    }
    
    func getParams() -> [String:Any]{
        guard let data = try? JSONEncoder().encode(self),
              var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        dict.removeValue(forKey: "server")
        
        if group.trimmingSpaceAndNewLines.isEmpty{
            dict["group"] = String(localized: "默认")
        }
        if title.trimmingSpaceAndNewLines.isEmpty{
            dict.removeValue(forKey: "title")
        }
        
        if subTitle.trimmingSpaceAndNewLines.isEmpty{
            dict.removeValue(forKey: "subTitle")
        }
        
        if body.trimmingSpaceAndNewLines.isEmpty{
            dict["body"] = String(localized: "测试内容")
        }
        
        if call == "0"{
            dict.removeValue(forKey: "call")
        }
        
        if url.trimmingSpaceAndNewLines.isEmpty{
            dict.removeValue(forKey: "url")
        }
        
        if icon.trimmingSpaceAndNewLines.isEmpty{
            dict.removeValue(forKey: "icon")
        }
        
        if image.trimmingSpaceAndNewLines.isEmpty{
            dict.removeValue(forKey: "image")
        }
        
        if category == .myNotificationCategory{
            dict.removeValue(forKey: "category")
        }
        
        if level == .active{
            dict.removeValue(forKey: "level")
        }
        
        if level == .critical{
            dict["volume"] = Int(volume)
        }else{
            dict.removeValue(forKey: "volume")
        }
        
        if badge <= 0 {
            dict.removeValue(forKey: "badge")
        }
        
        
        dict.removeValue(forKey: "cipherText")
        
        if !cipherText.isEmpty{
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                  let cipherResult = CryptoManager(Defaults[.cryptoConfigs].config()).encrypt(jsonData) else {
                return [:]
            }
            return ["cipherText":  cipherResult]
        }
        
        return dict
    }
    
    func createParams()-> String{
        guard var components = URLComponents(string: self.server) else { return self.server }
        
        let dict = self.getParams()
        
        if let cipherText = dict["cipherText"] as? String{
            return server + "?cipherText=" + cipherText.replacingOccurrences(of: "+", with: "%2B")
        }
        
        components.queryItems = dict.compactMap { key,value in
            return URLQueryItem(name: key, value: "\(value)")
        }
        
        return components.url?.absoluteString ?? self.server
    }
}


enum LevelTitle: String, CaseIterable, Codable , Defaults.Serializable{
    case passive
    case active
    case timeSensitive
    case critical

    var name: String {
        switch self {
        case .passive: return String(localized: "静默通知")
        case .active: return String(localized: "正常通知")
        case .timeSensitive: return String(localized: "即时通知")
        case .critical: return String(localized: "重要通知")
        }
    }

    // 🔁 从 displayName 获取 rawValue（如："静默通知" -> "passive"）
    static func rawValue(fromDisplayName name: String) -> String? {
        return LevelTitle.allCases.first(where: {$0.name == name})?.rawValue
    }
}
