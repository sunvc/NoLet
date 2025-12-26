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

import CommonCrypto
import Compression
import Defaults
import Foundation
import UniformTypeIdentifiers
import UIKit

class NetworkManager: NSObject, Sendable{
    private var session: URLSession!

    enum requestMethod: String {
        case GET
        case POST
        case HEAD

        var method: String { rawValue }
    }

    struct EmptyResponse: Codable {}

    /// 通用网络请求方法
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法（默认为 GET）
    ///   - params: 请求参数（支持 GET 查询参数或 POST body）
    /// - Returns: 返回泛型解码后的模型数据
    func fetch<T: Codable>(
        url: String,
        path: String = "",
        method: requestMethod = .GET,
        params: [String: Any] = [:],
        headers: [String: String] = [:],
        timeout: Double = 30
    ) async throws -> T {
        let (data, response) = try await fetch(
            url: url,
            path: path,
            method: method,
            params: params,
            headers: headers,
            timeout: timeout
        )

        guard let response = response as? HTTPURLResponse else { throw APIError.invalidURL }
        guard 200...299 ~= response.statusCode else {
            throw APIError.invalidCode(response.statusCode)
        }

        // 尝试将响应的 JSON 解码为泛型模型 T
        let result = try JSONDecoder().decode(T.self, from: data)
        return result
    }

    func fetch(
        url: String,
        path: String = "",
        method: requestMethod = .GET,
        params: [String: Any] = [:],
        headers: [String: String] = [:],
        timeout: Double = 30
    ) async throws -> (Data, URLResponse) {
        if session == nil {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
        }

        // 尝试将字符串转换为 URL，如果失败则抛出错误
        let url = (url + path).normalizedURLString()
        guard var requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        // 如果是 GET 请求并且有参数，将参数拼接到 URL 的 query 中
        if method == .GET, !params.isEmpty {
            if var urlComponents = URLComponents(string: url) {
                urlComponents.queryItems = params.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                if let composedURL = urlComponents.url {
                    requestURL = composedURL
                }
            }
        }

        // 构造 URLRequest 请求对象
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.method // .get 或 .post

        request.setValue(await self.customUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(UTType.json.preferredMIMEType, forHTTPHeaderField: "Content-Type")

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 如果是 POST 请求，将参数编码为 JSON 设置到 httpBody
        if method == .POST, !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        request.timeoutInterval = timeout

        request.assumesHTTP3Capable = true

        NLog.log(request.description, params)
        let (data, response) = try await session.data(for: request)
        NLog.log(String(data: data, encoding: .utf8))
        return (data, response)
    }

    func test(url: String = "https://example.com") async -> Bool {
        guard
            let (_, response) = try? await fetch(url: url, method: .HEAD, timeout: 3),
            let response = response as? HTTPURLResponse
        else {
            return false
        }
        return response.statusCode == 200
    }

    func health(url: String) async -> Bool {
        guard let data = try? await fetch(url: url + "/health", method: .GET, timeout: 3),
              let response = data.1 as? HTTPURLResponse
        else {
            return false
        }
        return String(bytes: data.0, encoding: .utf8) == "OK" && response.statusCode == 200
    }

    enum APIError: Error {
        case invalidURL
        case invalidCode(Int)
    }

    func download(
        from fileURL: URL,
        headers: [String: String] = [:],
        timeout: Double = 15
    ) async throws -> URL {
        var request = URLRequest(url: fileURL)

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.timeoutInterval = timeout

        // 创建下载任务
        let (downloadedURL, response) = try await session.download(for: request)

        // 验证响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidCode(httpResponse.statusCode)
        }

        // 将下载的临时文件移动到应用沙盒的缓存目录
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
        let destinationURL = cachesDirectory.appendingPathComponent(fileURL.lastPathComponent)

        // 如果目标文件已存在则删除
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        // 移动文件
        try FileManager.default.moveItem(at: downloadedURL, to: destinationURL)

        return destinationURL
    }
   
    func customUserAgent() async -> String {
        let info = Bundle.main.infoDictionary

        let appName = NCONFIG.appSymbol
        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let buildNumber = info?["CFBundleVersion"] as? String ?? "0"

        var systemInfo = utsname()
        uname(&systemInfo)

        let deviceModel = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        let systemVer = await MainActor.run{ UIDevice.current.systemVersion }
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? "CN" // e.g. CN
        let language = locale.language.languageCode?.identifier ?? "en" // e.g. zh

        return "\(appName)/\(appVersion) (Build \(buildNumber); \(deviceModel); iOS \(systemVer); \(regionCode)-\(language))"
    }
}
