//
//  File name:     NetworkManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/4.
	
import UIKit
import Foundation
import CommonCrypto
import Defaults


class NetworkManager: NSObject {

    let session = URLSession(configuration: .default)
    

	enum requestMethod:String{
		case GET = "GET"
		case POST = "POST"
        case HEAD = "HEAD"
		
		var method:String{ self.rawValue }
	}
    
    struct EmptyResponse: Codable {}
   
    
    
    /// 无返回值
    func fetchVoid(url: String, method: requestMethod = .GET, params: [String: Any] = [:], sign: String? = nil) async {
        _ = try? await self.fetch(url: url, method: method, params: params, timeout: 3, sign: sign)
    }
    
    /// 通用网络请求方法
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法（默认为 GET）
    ///   - params: 请求参数（支持 GET 查询参数或 POST body）
    /// - Returns: 返回泛型解码后的模型数据
    func fetch<T: Codable>(url: String, method: requestMethod = .GET, params: [String: Any] = [:], headers:[String:String] = [:], timeout:Double = 30, sign: String? = nil) async throws -> T {
        let data  = try await self.fetch(url: url, method: method, params: params, headers: headers, timeout: timeout, sign: sign)
        
        guard let response = data.1 as? HTTPURLResponse else{ throw APIError.invalidURL}
        guard 200...299 ~= response.statusCode else{ throw APIError.invalidCode(response.statusCode)}
        
        // 尝试将响应的 JSON 解码为泛型模型 T
        do{
            let result = try JSONDecoder().decode(T.self, from: data.0)
            return result
        }catch{
            NLog.error(String(data: data.0, encoding: .utf8))
            throw error
        }
        
    }
    
    func health(url: String, sign: String? = nil) async -> Bool {
        guard let data  = try? await self.fetch(url: url + "/health", method: .GET, params: [:], headers: [:], timeout: 3, sign: sign),  let response = data.1 as? HTTPURLResponse  else {
            return false
        }
        return String(bytes: data.0, encoding: .utf8) == "OK" && response.statusCode == 200
    }

    
    func fetch(url: String, method: requestMethod = .GET, params: [String: Any] = [:], headers:[String:String] = [:], timeout:Double = 30, sign: String? = nil) async throws -> (Data, URLResponse) {
        
        // 尝试将字符串转换为 URL，如果失败则抛出错误
        guard var requestUrl = URL(string: url) else {
            throw APIError.invalidURL
        }

        // 如果是 GET 请求并且有参数，将参数拼接到 URL 的 query 中
        if method == .GET && !params.isEmpty {
            if var urlComponents = URLComponents(string: url) {
                urlComponents.queryItems = params.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                if let composedUrl = urlComponents.url {
                    requestUrl = composedUrl
                }
            }
        }

        // 构造 URLRequest 请求对象
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.method  // .get 或 .post
        
        if let signStr = signature(url: url, sign: sign){
            request.setValue( signStr, forHTTPHeaderField:"X-Signature")
        }
        request.setValue(self.customUserAgentDetailed(), forHTTPHeaderField: "User-Agent" )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization")



        for (key,value) in headers{
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 如果是 POST 请求，将参数编码为 JSON 设置到 httpBody
        if method == .POST && !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        request.timeoutInterval = timeout
        
        // 打印请求信息（用于调试）
        NLog.log(request.debugDescription)
        

       return try await session.data(for: request)
    }

    func signature( url: String, sign:String? = nil) -> String?{
        var config:CryptoModelConfig?{
            if url.contains(BaseConfig.defaultServer){
                return .data
            }
            if let sign {
                return CryptoModelConfig(inputText: sign)
            }
            return .data
        }
        guard let config else{ return nil }
        return CryptoManager(config)
            .encrypt("\(Int(Date().timeIntervalSince1970))")?
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }


    func customUserAgentDetailed() -> String {
        let info = Bundle.main.infoDictionary
        
        let appName     = BaseConfig.appSymbol
        let appVersion  = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let buildNumber = info?["CFBundleVersion"] as? String ?? "0"
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        let systemVer   = UIDevice.current.systemVersion
        
        let locale      = Locale.current
        let regionCode  = locale.region?.identifier ?? "XX"   // e.g. CN
        let language    = locale.language.languageCode?.identifier ?? "en" // e.g. zh
        
        return "\(appName)/\(appVersion) (Build \(buildNumber); \(deviceModel); iOS \(systemVer); \(regionCode)-\(language))"
    }
    

    func appendQueryParameter(to urlString: String, key: String, value: String) -> String? {
        guard var components = URLComponents(string: urlString) else { return nil }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: key, value: value))
        components.queryItems = queryItems

        return components.url?.absoluteString
    }
    
    enum APIError:Error{
        case invalidURL
        case invalidCode(Int)
    }
    
   
}

extension NetworkManager {

    /// 上传文件
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法，默认为 POST
    ///   - fileData: 要上传的文件数据
    ///   - fileName: 文件名
    ///   - mimeType: 文件 MIME 类型
    ///   - params: 其他表单数据
    /// - Returns: 返回服务器响应的 Data
    func uploadFile(url: String,
                    method: requestMethod = .POST,
                    fileData: Data,
                    fileName: String,
                    mimeType: String,
                    params: [String: Any] = [:]) async throws -> Data {
        
        guard let url = URL(string: url) else {
            throw "Invalid URL"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.method
        
        // 生成唯一的 boundary 字符串
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // 设置 Content-Type 为 multipart/form-data
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(self.customUserAgentDetailed(), forHTTPHeaderField: "User-Agent")
        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization")
        
        // 生成表单数据
        var body = Data()
        
        // 添加普通表单字段（如果有的话）
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 添加文件字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 结束 boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 设置 HTTPBody
        request.httpBody = body
        
        // 设置请求超时时间
        request.timeoutInterval = 60
        
        // 打印请求信息（用于调试）
        NLog.log(request)
        
        // 发送请求并等待响应
        let data = try await session.data(for: request)
        
        return data
    }
}
