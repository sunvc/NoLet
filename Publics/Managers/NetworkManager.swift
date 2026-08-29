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
import OSLog
import UIKit
import UniformTypeIdentifiers

final class NetworkManager: NSObject, Sendable {
    private let logger = Logger(subsystem: "app.wzs.logger", category: "NetworkManager")
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

    struct Response: Sendable {
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

    func fetch(
        url: String,
        path: String? = nil,
        method: requestMethod = .GET,
        headers: [String: String]? = nil,
        params: [String: String]? = nil,
        body: (Encodable & Sendable)? = nil,
        timeout: Double = 30
    ) async throws -> Response {
        guard var baseURL = URL(string: url.normalizedURLString()) else {
            throw APIError.invalidURL
        }

        if let path, !path.isEmpty {
            let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            baseURL.appendPathComponent(cleanedPath)
        }

        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if let params, !params.isEmpty {
            components.queryItems = try params.queryItems()
        }

        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.method

        request.setValue(await customUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue(UTType.json.preferredMIMEType, forHTTPHeaderField: "Content-Type")

        if let headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        request.timeoutInterval = timeout

        request.assumesHTTP3Capable = true

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidURL }

        #if DEBUG
        let res = String(data: data, encoding: .utf8)
        logger.info("\(res as NSObject?)")
        #endif

        return Response(data: data, header: response)
    }

    func test(url: String = "https://www.apple.com") async -> Bool {
        return (try? await fetch(url: url, method: .HEAD))?.check() ?? false
    }

    func health(url: String) async -> Bool {
        return (try? await fetch(url: url, path: "/health"))?.check("OK") ?? false
    }

    enum APIError: Error {
        case invalidURL
        case invalidCode(Int)
    }

    @discardableResult
    func download(
        from fileURL: URL,
        to local: URL? = nil,
        headers: [String: String] = [:],
        timeout: Double = 15
    ) async throws -> URL {
        var request = URLRequest(url: fileURL)

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.timeoutInterval = timeout

        let (downloadedURL, response) = try await session.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidCode(httpResponse.statusCode)
        }

        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
        let destinationURL = local ?? cachesDirectory
            .appendingPathComponent(fileURL.lastPathComponent)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: downloadedURL, to: destinationURL)

        return destinationURL
    }

    func customUserAgent() async -> String {
        let info = Bundle.main.infoDictionary

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
        let regionCode = locale.region?.identifier ?? "CN"
        let language = locale.language.languageCode?.identifier ?? "en"

        return "NoLet/\(appVersion) (Build \(buildNumber); \(deviceModel); iOS \(systemVer); \(regionCode)-\(language))"
    }

    struct EmptyParams: Codable, Sendable {}

    func uploadFile(
        data: Data,
        url: String,
        path: String? = nil,
        headers: [String: String] = [:]
    ) async throws -> Data {
        guard var url = URL(string: url) else {
            throw APIError.invalidURL
        }

        if let path {
            let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            url.appendPathComponent(cleanedPath)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let useragent = await self.customUserAgent()
        request.setValue(useragent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await self.session.upload(for: request, from: data)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode
        else {
            throw APIError.invalidCode(-1)
        }

        return data
    }
}

extension Encodable {
    fileprivate func queryItems() throws -> [URLQueryItem] {
        let data = try JSONEncoder().encode(self)

        let object = try JSONSerialization.jsonObject(
            with: data
        )

        guard let dict = object as? [String: Any] else {
            return []
        }

        return dict.compactMap { key, value in
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                if mirror.children.isEmpty { return nil }
            }
            let rawValue: Any
            if let firstChild = mirror.children.first {
                rawValue = firstChild.value
            } else {
                rawValue = value
            }
            let valueString = String(describing: rawValue)
            guard valueString != "nil" else { return nil }

            return URLQueryItem(name: key, value: valueString)
        }
    }
}

// MARK: -  URLSession+.swift

extension URLSession {
    enum APIError: Error {
        case invalidURL
        case invalidCode(Int)
    }

    func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await self.data(for: request)

        guard let response = response as? HTTPURLResponse else { throw APIError.invalidURL }
        guard 200...299 ~= response.statusCode
        else { throw APIError.invalidCode(response.statusCode) }
        return data
    }
}

// MARK: -  URLComponents+.swift

extension URLComponents {
    func getParams() -> [String: String] {
        var parameters = [String: String]()
        if let queryItems = queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value {
                    parameters[queryItem.name] = value
                }
            }
        }
        return parameters
    }

    func getParams(from params: [String: Any]) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        return queryItems
    }
}
