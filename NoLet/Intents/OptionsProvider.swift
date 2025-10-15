//
//  OptionsProvider.swift
//  Bark
//
//  Created by huangfeng on 2/21/25.
//  Copyright © 2025 Fin. All rights reserved.
//
import AppIntents
import Defaults





struct ServerAddressProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        Defaults[.servers].map { $0.server }
    }
    
    func defaultResult() async -> String? {
        Defaults[.servers].first?.server
    }
}


struct SoundOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let (customSounds , defaultSounds) = AudioManager.shared.getFileList()
        return (customSounds + defaultSounds).map {
            $0.deletingPathExtension().lastPathComponent
        }
    }
    
    func defaultResult() async -> String? {
        return "xiu"
    }
}




struct LevelClassProvider:  DynamicOptionsProvider{
    func results() async throws -> [String] {
        return LevelTitle.allCases.map { level in
            level.name
        }
    }
    
    func defaultResult() async -> String? {
        return LevelTitle.active.name
    }
}


struct VolumeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [Int] {
        return Array(0...10)
    }
    
    func defaultResult() async -> Int? {
        return 5
    }
}

struct CategoryParamsProvider: DynamicOptionsProvider{
    func results() async throws -> [String] {
        Identifiers.allCases.compactMap { item in
            item.name
        }
    }
    func defaultResult() async -> String? {
        return Identifiers.myNotificationCategory.name
    }
    
}


struct APIPushToDeviceResponse: Codable {
    let code: Int
    let message: String
    let timestamp: Int
}


