//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - PBSchemeEnum.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 21:36.
    

import Foundation


enum PBScheme: String, CaseIterable {
    case pb
    case mw
    case nolet

    static var schemes: [String] { allCases.compactMap { $0.rawValue } }

    enum HostType: String {
        case server
        case crypto
        case assistant
        case openPage
    }

    // pb://openpage?title=string or mw://openpage?title=string
    func scheme(host: HostType, params parameters: [String: Any]) -> URL {
        var components = URLComponents()
        components.scheme = rawValue
        components.host = host.rawValue // 固定 host，如果有 path 也可以加上

        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }

        return components.url!
    }
}
