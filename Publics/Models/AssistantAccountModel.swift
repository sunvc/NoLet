//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AssistantAccountModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/12/24 21:34.

import Defaults
import Foundation

struct AssistantAccount: Codable, Identifiable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var current: Bool = false
    var timestamp: Date = .now
    var name: String
    var host: String
    var basePath: String
    var key: String
    var model: String

    func toBase64() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }

    init(
        current: Bool = false,
        name: String,
        host: String,
        basePath: String,
        key: String,
        model: String
    ) {
        self.current = current
        self.name = name
        self.host = host
        self.basePath = basePath
        self.key = key
        self.model = model
    }

    init?(base64: String) {
        guard let data = Data(base64Encoded: base64), let decoded = try? JSONDecoder().decode(
            Self.self,
            from: data
        ) else {
            return nil
        }
        self = decoded
        id = UUID().uuidString
    }

    static let data = AssistantAccount(
        name: String(localized: "智能助手"),
        host: "api.openai.com",
        basePath: "/v1",
        key: "",
        model: "gpt-4o-mini"
    )
}

extension AssistantAccount {
    mutating func trimAssistantAccountParameters() {
        name = name.removingAllWhitespace
        host = host.removingAllWhitespace
        host = host.removeHTTPPrefix()
        basePath = basePath.removingAllWhitespace
        key = key.removingAllWhitespace
        model = model.removingAllWhitespace
    }
}

extension Defaults.Keys {
    static let assistantAccouns = Key<[AssistantAccount]>("AssistantAccount", [], iCloud: true)
}

extension AssistantAccount: @MainActor Defaults.Serializable {}
