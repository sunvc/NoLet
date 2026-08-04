//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChatPromptModel.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/8/4 19:49.

import Foundation

nonisolated extension Defaults.Keys {
    static let prompts = Key<[ChatPrompt]>("imageSaveDays", [])
}

nonisolated extension ChatPrompt: Defaults.Serializable {}

nonisolated struct ChatPrompt: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var timestamp: Date = .now
    var title: String
    var content: String
    var inside: Bool
    var mode: Mode = .promt

    enum Mode: String, Codable {
        case promt = "PROMT"
        case mcp = "MCP"
        case call = "CALL"
    }

    enum ChatPromptMode: Equatable, Hashable {
        
        case mcp(String)
        case translate(String)
        case abstract(String)

        var prompt: ChatPrompt {
            switch self {
            case .mcp:
                ChatPrompt(
                    timestamp: .now,
                    title: String(localized: "APP助手"),
                    content: String(
                        localized: "你是本APP内部的智能助手. 你可以使用 manage_app 工具来控制应用(设置、导航、数据、缓存、消息管理).当用户要求执行此工具支持的任何操作(例如: 打开设置,清除缓存,更改图标,删除上周的消息)时，你必须立即调用 'manage_app' 并提供正确的参数."
                    ),
                    inside: true,
                    mode: .call
                )
            case .translate(let lang):
                ChatPrompt(
                    timestamp: .now,
                    title: String(localized: "翻译助手"),
                    content: String(localized: """
                        你是一名专业翻译，精通多国语言，能够准确传达原文含义与风格。翻译时请遵循以下要点：
                        1. 保持语气一致，忠实还原原文风格。
                        2. 合理调整以符合目标语言习惯与文化。
                        3. 优先选择自然、通顺的表达方式, 只返回翻译，不要添加任何其他内容。
                        下面我给你内容，直接按照 \(lang) 进行翻译.
                        """),
                    inside: true,
                    mode: .promt
                )
            case .abstract(let lang):
                ChatPrompt(
                    timestamp: .now,
                    title: String(localized: "摘要助手"),
                    content: String(localized: """
                        你是一名专业摘要助手，擅长用简洁准确的语言提炼关键信息。
                        请基于以下内容，提炼出 2~3 句话，清晰概括核心观点和情感基调。
                        仅输出摘要内容，不添加解释或说明。
                        下面我给你内容，直接按照 \(lang) 语言给我回复
                        """),
                    inside: true,
                    mode: .promt
                )
            }
        }

        static func prompts(lang: String) -> [ChatPrompt] {
            [
                mcp(lang).prompt,
                translate(lang).prompt,
                abstract(lang).prompt,
            ]
        }
    }
}
