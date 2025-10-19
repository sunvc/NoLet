//
//  Lang.swift
//  NoLet
//
//  Created by lynn on 2025/7/12.
//
import Foundation
import Defaults

extension Multilingual.Country: Defaults.Serializable{}

extension Defaults.Keys{
    static let translateLang = Key<Multilingual.Country>("MultilingualCountry", default: Multilingual.commonLanguages.first!)
}

enum Multilingual{
    struct Country: Identifiable, Equatable, Hashable, Codable {
        var id: String { code }
        let code: String // e.g. "US"
        let name: String // e.g. "United States"
        let flag: String
    }
    
    static let commonLanguages: [Country] = [
        Country(code: "zh", name: String(localized: "中文"), flag: "🇨🇳"),
        Country(code: "en", name: String(localized: "英语"), flag: "🇺🇸"),
        Country(code: "ja", name: String(localized: "日语"), flag: "🇯🇵"),
        Country(code: "ko", name: String(localized: "韩语"), flag: "🇰🇷"),
        Country(code: "fr", name: String(localized: "法语"), flag: "🇫🇷"),
        Country(code: "de", name: String(localized: "德语"), flag: "🇩🇪"),
        Country(code: "es", name: String(localized: "西班牙语"), flag: "🇪🇸"),
        Country(code: "pt", name: String(localized: "葡萄牙语"), flag: "🇧🇷"),
        Country(code: "ru", name: String(localized: "俄语"), flag: "🇷🇺"),
        Country(code: "ar", name: String(localized: "阿拉伯语"), flag: "🇸🇦"),
        Country(code: "hi", name: String(localized: "印地语"), flag: "🇮🇳"),
        Country(code: "id", name: String(localized: "印尼语"), flag: "🇮🇩"),
        Country(code: "vi", name: String(localized: "越南语"), flag: "🇻🇳"),
        Country(code: "th", name: String(localized: "泰语"), flag: "🇹🇭")
    ]
    
    static func resetTransLang(){
        let current = Defaults[.translateLang]
        if let newCurrent = Self.commonLanguages.first(where: {$0.id == current.id}){
            Defaults[.translateLang] = newCurrent
        }
    }
    
}
