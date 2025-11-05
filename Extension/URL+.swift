//
//  URL+.swift
//  NoLet
//
//  Created by lynn on 2025/6/5.
//

import SwiftUI


extension URL{
    
    func findNameAndKey() -> (String, String){
        
        guard let scheme = scheme, let host = host() else {
            return ("", "")
        }
        var base = "\(scheme)://\(host)"
        
        if let port = port { base += ":\(port)" }

        let key = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return (base.trimmingCharacters(in: .whitespaces), key.trimmingCharacters(in: .whitespaces))
    }
    
    var hasHttp:Bool{  scheme?.hasHttp ?? false }
}


// MARK: -  URLSession+.swift
extension URLSession{
    enum APIError:Error{
        case invalidURL
        case invalidCode(Int)
    }
    
    func data(for request:URLRequest) async throws -> Data{
    
        let (data,response) = try await self.data(for: request)
       
        guard let response = response as? HTTPURLResponse else{ throw APIError.invalidURL }
        guard 200...299 ~= response.statusCode else {throw APIError.invalidCode(response.statusCode) }
        return data
    }
    
}

// MARK: -  URLComponents+.swift

extension URLComponents{
    func getParams()-> [String:String]{
        var parameters = [String: String]()
        // 遍历查询项目并将它们添加到字典中
        if let queryItems = self.queryItems {
            
            for queryItem in queryItems {
                if let value = queryItem.value {
                    parameters[queryItem.name] = value
                }
            }
        }
        return parameters
    }
    
    func getParams(from params: [String: Any])-> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        return queryItems
    }
    
    
    
}
