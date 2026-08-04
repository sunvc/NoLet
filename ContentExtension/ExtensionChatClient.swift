//
//  ExtensionChatClient.swift
//  ContentExtension
//
//  通知扩展内部使用的极简流式大模型客户端：
//  直接从 App Group 共享的 UserDefaults 读取主 App 配置的 AssistantAccount
//  和目标翻译语言，复用 OpenAI 兼容的 /chat/completions SSE 流式接口。
//  不依赖 NoLetChatManager / OpenAI 包，避免把 GRDB 等主 App 依赖拖进扩展。
//

import Foundation
import Defaults

struct ExtensionChatClient {
    private struct Account: Decodable {
        let current: Bool?
        let host: String
        let basePath: String?
        let key: String
        let model: String
    }

    private struct Country: Decodable {
        let code: String
        let name: String
    }

    enum Mode {
        case translate
        case abstract

        func systemPrompt(lang: String) -> String {
            switch self {
            case .translate:
                String(
                    localized: """
                    你是一名专业翻译，精通多国语言，能够准确传达原文含义与风格。翻译时请遵循以下要点：
                    1. 保持语气一致，忠实还原原文风格。
                    2. 合理调整以符合目标语言习惯与文化。
                    3. 优先选择自然、通顺的表达方式, 只返回翻译，不要添加任何其他内容。
                    下面我给你内容，直接按照 \(lang) 进行翻译.
                    """
                )
            case .abstract:
                String(
                    localized: """
                    你是一名专业摘要助手，擅长用简洁准确的语言提炼关键信息。
                    请基于以下内容，提炼出 2~3 句话，清晰概括核心观点和情感基调。
                    仅输出摘要内容，不添加解释或说明。
                    下面我给你内容，直接按照 \(lang) 语言给我回复
                    """
                )
            }
        }
    }

    enum ClientError: Error {
        case noAccount
    }

    /// 流式请求，每个 delta 片段回调一次。
    func stream(
        text: String,
        mode: Mode,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        guard let account = Defaults[.assistantAccouns].first else {
            throw ClientError.noAccount
        }
        
       
        let lang = Self.systemLanguageName()
        let basePath = account.basePath.isEmpty == false ? account.basePath : "/v1"
        let host = account.host.hasPrefix("http") ? account.host : "https://\(account.host)"
        guard let url = URL(string: "\(host)\(basePath)/chat/completions") else {
            throw ClientError.noAccount
        }

        let body: [String: Any] = [
            "model": account.model,
            "stream": true,
            "messages": [
                ["role": "system", "content": mode.systemPrompt(lang: lang)],
                ["role": "user", "content": text],
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(account.key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            var detail = ""
            for try await line in bytes.lines { detail += line }
            throw NSError(
                domain: "ExtensionChatClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: detail]
            )
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard
                let chunkData = payload.data(using: .utf8),
                let chunk = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any],
                let choices = chunk["choices"] as? [[String: Any]],
                let delta = choices.first?["delta"] as? [String: Any],
                let content = delta["content"] as? String,
                !content.isEmpty
            else {
                continue
            }
            onDelta(content)
        }
    }

    private static func systemLanguageName() -> String {
        if let code = Locale.current.language.languageCode?.identifier,
           let name = Locale.current.localizedString(forLanguageCode: code)
        {
            return name
        }
        return "English"
    }
}
