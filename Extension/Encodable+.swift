//
//  Equatable+.swift
//  NoLet
//
//  Created by lynn on 2025/6/5.
//

import SwiftUI


extension Encodable {
    func toEncodableDictionary() -> [String: Any]? {
        // 1. 使用 JSONEncoder 将结构体编码为 JSON 数据
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        // 2. 使用 JSONSerialization 将 JSON 数据转换为字典
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    
    /// 转成 [String: String]，可排除一些 key
    func toStringDict(excluding keysToExclude: [String] = []) -> [String: String] {
  
        var result: [String: String] = [:]
        for (keyAny, valueAny) in self {
            // 只处理 key 为 String 的情况
            guard let key = keyAny as? String, !keysToExclude.contains(key) else { continue }
            
            // 将 value 转成 String
            let strValue: String
            switch valueAny {
            case let v as String: strValue = v
            case let v as CustomStringConvertible: strValue = v.description
            default:
                strValue = String(describing: valueAny)
            }
            
            result[key] = strValue
        }
        return result
    }
    
    /// 转成 JSON 字符串
    func toJSONString(excluding keysToExclude: [String] = []) -> String? {
        
        let stringDict = self.toStringDict(excluding: keysToExclude)
         
        guard JSONSerialization.isValidJSONObject(stringDict),
              let data = try? JSONSerialization.data(withJSONObject: stringDict, options: [.prettyPrinted]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// 转成 URL query 样式字符串 key=value&key2=value2
    func toQueryString(excluding keysToExclude: [String] = []) -> String {
        let stringDict = self.toStringDict(excluding: keysToExclude)
        return stringDict.map { "\($0.key)=\($0.value)" }
                         .joined(separator: "&")
    }
}
