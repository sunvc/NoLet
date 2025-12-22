//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - AppIconEnum.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 21:35.
    
import Foundation

// MARK: - AppIconMode
enum AppIconEnum: String, CaseIterable, Equatable {
    case nolet
    case nolet0
    case nolet1
    case nolet2
    case nolet3

    var name: String? { self == .nolet ? nil : rawValue }

    var logo: String {
        switch self {
        case .nolet: "logo"
        case .nolet0: "logo0"
        case .nolet1: "logo1"
        case .nolet2: "logo2"
        case .nolet3: "logo3"
        }
    }
}

