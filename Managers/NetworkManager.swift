//
//  File name:     NetworkManager.swift
//  NoLet
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://wzs.app
//  E-mail:        to@wzs.app
//
//
//  Description:
//
//  History:
//    Created by Neo on 2024/12/4.
	
import UIKit
import Foundation
import CommonCrypto
import Defaults
import os
import UniformTypeIdentifiers

class NetworkManager: NSObject, URLSessionDataDelegate {

    private var session: URLSession!

	enum requestMethod:String{
		case GET = "GET"
		case POST = "POST"
        case HEAD = "HEAD"
		
		var method:String{ self.rawValue }
	}
    
    
    struct EmptyResponse: Codable {}
   

    /// 通用网络请求方法
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法（默认为 GET）
    ///   - params: 请求参数（支持 GET 查询参数或 POST body）
    /// - Returns: 返回泛型解码后的模型数据
    func fetch<T: Codable>(url: String,
                           path:String = "",
                           method: requestMethod = .GET,
                           params: [String: Any] = [:],
                           headers:[String:String] = [:],
                           timeout:Double = 30) async throws -> T {
        let (data, response)  = try await self.fetch(url: url,
                                                     path: path,
                                                     method: method,
                                                     params: params,
                                                     headers: headers,
                                                     timeout: timeout)
        
        guard let response = response as? HTTPURLResponse else{ throw APIError.invalidURL}
        guard 200...299 ~= response.statusCode else{
            throw APIError.invalidCode(response.statusCode)
        }
        
        // 尝试将响应的 JSON 解码为泛型模型 T
        let result = try JSONDecoder().decode(T.self, from: data)
        return result
        
    }
    
    
    
    func fetch(url: String,
               path:String = "",
               method: requestMethod = .GET,
               params: [String: Any] = [:],
               headers:[String:String] = [:],
               timeout:Double = 30) async throws -> (Data, URLResponse) {
        
        if self.session == nil {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        }
        
        // 尝试将字符串转换为 URL，如果失败则抛出错误
        let url = (url + path).normalizedURLString()
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
        
        
        if let signStr = signature(url: url, data: "\(Int(Date().timeIntervalSince1970))"){
            request.setValue( signStr, forHTTPHeaderField:"X-Signature")
        }
        
        request.setValue(NCONFIG.customUserAgent, forHTTPHeaderField: "User-Agent" )
        request.setValue(UTType.json.preferredMIMEType, forHTTPHeaderField: "Content-Type")
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
        
        request.assumesHTTP3Capable = true
        
        NLog.log(request.description)
        let (data, response) = try await session.data(for: request)
        NLog.log(String(data: data, encoding: .utf8))
        return (data, response)
    }
    
    func test(url: String = "https://example.com") async -> Bool {
        guard let (_, response)  = try? await self.fetch(url: url,
                                                         method: .HEAD,
                                                         params: [:],
                                                         headers: [:],
                                                         timeout: 3),
              let response = response as? HTTPURLResponse  else {
            return false
        }
        return response.statusCode == 200
    }
    
    func health(url: String) async -> Bool {
        guard let data  = try? await self.fetch(url: url + "/health",
                                                method: .GET,
                                                params: [:],
                                                headers: [:],
                                                timeout: 3),  let response = data.1 as? HTTPURLResponse  else {
            return false
        }
        return String(bytes: data.0, encoding: .utf8) == "OK" && response.statusCode == 200
    }


    func signature(url: String, data: String) -> String?{
        
        var config:CryptoModelConfig?{
            
            guard let url = URL(string: url),
                  let scheme = url.scheme,
                  let host = url.host else { return .data }
            
            let baseURL = "\(scheme)://\(host)"
            guard let data = Defaults[.servers].first(where: {$0.url == baseURL}),
                  let sign = data.sign else {
                return .data
            }
            return CryptoModelConfig(inputText: sign) ?? .data
        }
        guard let config else{ return nil }
        
        return CryptoManager(config).encrypt(data)?.safeBase64
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
                    path: String?,
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
        request.setValue(NCONFIG.customUserAgent, forHTTPHeaderField: "User-Agent")
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
        request.timeoutInterval = 15
        
        // 打印请求信息（用于调试）
        NLog.log(request)
        
        // 发送请求并等待响应
        let data = try await session.data(for: request)
        
        return data
    }
    
}

extension NetworkManager {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
#if DEBUG
        let protocols = metrics.transactionMetrics.map { $0.networkProtocolName ?? "-" }.joined(separator: "-")
        os_log("protocols: \(protocols)")
        // 这里获取响应信息
#endif
    }

}
