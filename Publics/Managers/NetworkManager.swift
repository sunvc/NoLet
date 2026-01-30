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
import UIKit
import UniformTypeIdentifiers

class NetworkManager: NSObject {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config, delegate: nil, delegateQueue: .main)
    }()

    enum requestMethod: String {
        case GET
        case POST
        case HEAD

        var method: String { rawValue }
    }

    struct Response {
        var data: Data
        var header: HTTPURLResponse

        func check(_ response: String? = nil, code: ClosedRange<Int> = 200...299) -> Bool {
            if let response {
                return String(bytes: data, encoding: .utf8) == response && code ~= header.statusCode
            }
            return code ~= header.statusCode
        }

        func decode<T: Codable>() throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

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
        let response = try await fetch(
            url: url,
            path: path,
            method: method,
            params: params,
            headers: headers,
            timeout: timeout
        )

        guard response.check() else {
            throw APIError.invalidCode(response.header.statusCode)
        }

        return try response.decode() as T
    }

    func fetch(
        url: String,
        path: String = "",
        method: requestMethod = .GET,
        params: [String: Any] = [:],
        headers: [String: String] = [:],
        timeout: Double = 30
    ) async throws -> Response {
        guard var baseURL = URL(string: url.normalizedURLString()) else {
            throw APIError.invalidURL
        }

        if !path.isEmpty {
            let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            baseURL.appendPathComponent(cleanedPath)
        }

        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if method == .GET, !params.isEmpty {
            var items = components.queryItems ?? []

            let newItems: [URLQueryItem] = params.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }

            items.append(contentsOf: newItems)
            components.queryItems = items
        }

        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.method // .get 或 .post

        request.setValue(await customUserAgent(), forHTTPHeaderField: "User-Agent")
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

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidURL }

//        logger.debug("\(request.description)\(params)\(String(data: data, encoding: .utf8))")
        return Response(data: data, header: response)
    }

    func test(url: String = "https://example.com") async -> Bool {
        return (try? await fetch(url: url, method: .HEAD)) ?? false
    }

    func health(url: String) async -> Bool {
        return ((try? await fetch(url: url + "/health"))?.check("OK")) ?? false
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

        let systemVer = await MainActor.run { UIDevice.current.systemVersion }
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? "CN" // e.g. CN
        let language = locale.language.languageCode?.identifier ?? "en" // e.g. zh

        return "\(appName)/\(appVersion) (Build \(buildNumber); \(deviceModel); iOS \(systemVer); \(regionCode)-\(language))"
    }
}
