//
//  NoLetChatClient.swift
//  NoLet
//
//  极简 OpenAI 兼容流式大模型客户端。
//  只覆盖本 App 实际用到的 Chat Completions（流式 + 非流式）能力，
//  替代第三方 OpenAI 包：URLSession + SSE 行解析 + Codable。
//

import Foundation

// MARK: - ReasoningEffort

enum ReasoningEffort: Codable, Equatable, Hashable, Sendable {
    case none
    case minimal
    case low
    case medium
    case high
    case customValue(String)

    var rawValue: String {
        switch self {
        case .none: "none"
        case .minimal: "minimal"
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .customValue(let v): v
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "none": self = .none
        case "minimal": self = .minimal
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        default: self = .customValue(rawValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }
}

// MARK: - JSONSchema（请求侧构造，输出为 JSONSerialization 可用的 Any）

enum JSONSchemaInstanceType: String {
    case integer, string, boolean, array, object, number, null
}

struct JSONSchemaField {
    let key: String
    let value: Any

    static func type(_ t: JSONSchemaInstanceType) -> JSONSchemaField {
        .init(key: "type", value: t.rawValue)
    }

    static func description(_ s: String) -> JSONSchemaField {
        .init(key: "description", value: s)
    }

    static func properties(_ p: [String: JSONSchema]) -> JSONSchemaField {
        .init(key: "properties", value: p.mapValues { $0.jsonValue })
    }

    static func additionalProperties(_ s: JSONSchema) -> JSONSchemaField {
        .init(key: "additionalProperties", value: s.jsonValue)
    }

    static func required(_ r: [String]) -> JSONSchemaField {
        .init(key: "required", value: r)
    }

    static func enumValues(_ v: [Any]) -> JSONSchemaField {
        .init(key: "enum", value: v)
    }
}

struct JSONSchema: @unchecked Sendable {
    let jsonValue: Any

    static func boolean(_ v: Bool) -> JSONSchema { .init(jsonValue: v) }

    init(_ fields: JSONSchemaField...) {
        self.init(fields: fields)
    }

    init(fields: [JSONSchemaField]) {
        var dict: [String: Any] = [:]
        for f in fields { dict[f.key] = f.value }
        self.jsonValue = dict
    }

    init(jsonValue: Any) {
        self.jsonValue = jsonValue
    }
}

// MARK: - 消息参数

enum ChatMessageContent {
    case string(String)
    case textContent(String)

    var text: String {
        switch self {
        case .string(let s), .textContent(let s): s
        }
    }
}

struct SystemMessageParam {
    let content: ChatMessageContent
    let name: String?
    init(content: ChatMessageContent, name: String? = nil) {
        self.content = content
        self.name = name
    }
}

struct UserMessageParam {
    let content: ChatMessageContent
    init(content: ChatMessageContent) { self.content = content }
}

struct AssistantMessageParam {
    let content: ChatMessageContent
    init(content: ChatMessageContent) { self.content = content }
}

enum ChatCompletionMessageParam {
    case system(SystemMessageParam)
    case user(UserMessageParam)
    case assistant(AssistantMessageParam)

    func json() -> [String: Any] {
        switch self {
        case .system(let p):
            var m: [String: Any] = ["role": "system", "content": p.content.text]
            if let name = p.name { m["name"] = name }
            return m
        case .user(let p):
            return ["role": "user", "content": p.content.text]
        case .assistant(let p):
            return ["role": "assistant", "content": p.content.text]
        }
    }
}

// MARK: - Tools

struct ChatCompletionToolParam {
    let function: FunctionDefinition

    struct FunctionDefinition {
        let name: String
        let description: String?
        let parameters: JSONSchema?
        let strict: Bool?

        init(
            name: String,
            description: String? = nil,
            parameters: JSONSchema? = nil,
            strict: Bool? = nil
        ) {
            self.name = name
            self.description = description
            self.parameters = parameters
            self.strict = strict
        }

        func json() -> [String: Any] {
            var m: [String: Any] = ["name": name]
            if let description { m["description"] = description }
            if let parameters { m["parameters"] = parameters.jsonValue }
            if let strict { m["strict"] = strict }
            return m
        }
    }

    init(function: FunctionDefinition) {
        self.function = function
    }

    func json() -> [String: Any] {
        ["type": "function", "function": function.json()]
    }
}

// MARK: - Web Search

struct WebSearchOptions {
    struct UserLocation {
        var country: String
        var city: String
    }

    enum SearchContextSize: String {
        case low, medium, high
    }

    var userLocation: UserLocation?
    var searchContextSize: SearchContextSize?

    func json() -> [String: Any] {
        var m: [String: Any] = [:]
        if let userLocation {
            m["user_location"] = [
                "type": "approximate",
                "approximate": [
                    "country": userLocation.country,
                    "city": userLocation.city,
                ],
            ]
        }
        if let searchContextSize {
            m["search_context_size"] = searchContextSize.rawValue
        }
        return m
    }
}

// MARK: - ChatQuery

struct ChatQuery {
    var messages: [ChatCompletionMessageParam]
    var model: String
    var reasoningEffort: ReasoningEffort?
    var temperature: Double?
    var tools: [ChatCompletionToolParam]?
    var webSearchOptions: WebSearchOptions?
    var stream: Bool

    init(
        messages: [ChatCompletionMessageParam],
        model: String,
        reasoningEffort: ReasoningEffort? = nil,
        temperature: Double? = nil,
        tools: [ChatCompletionToolParam]? = nil,
        webSearchOptions: WebSearchOptions? = nil,
        stream: Bool = true
    ) {
        self.messages = messages
        self.model = model
        self.reasoningEffort = reasoningEffort
        self.temperature = temperature
        self.tools = tools
        self.webSearchOptions = webSearchOptions
        self.stream = stream
    }

    func body() throws -> Data {
        var m: [String: Any] = [
            "model": model,
            "messages": messages.map { $0.json() },
            "stream": stream,
        ]
        if let reasoningEffort { m["reasoning_effort"] = reasoningEffort.rawValue }
        if let temperature { m["temperature"] = temperature }
        if let tools { m["tools"] = tools.map { $0.json() } }
        if let webSearchOptions { m["web_search_options"] = webSearchOptions.json() }
        return try JSONSerialization.data(withJSONObject: m)
    }
}

// MARK: - ChatStreamResult（仅解码消费侧用到的字段）

struct ChatStreamResult: Decodable, Sendable {
    struct Choice: Decodable, Sendable {
        struct Delta: Decodable, Sendable {
            let content: String?
            let toolCalls: [ToolCall]?
            private let _reasoning: String?
            private let _reasoningContent: String?

            var reasoning: String? { _reasoning ?? _reasoningContent }

            struct ToolCall: Decodable, Sendable {
                let index: Int
                let id: String?
                let function: Function?
                let type: String?

                struct Function: Decodable, Sendable {
                    let name: String?
                    let arguments: String?
                }

                enum CodingKeys: String, CodingKey {
                    case index, id, function, type
                }
            }

            enum CodingKeys: String, CodingKey {
                case content
                case toolCalls = "tool_calls"
                case _reasoning = "reasoning"
                case _reasoningContent = "reasoning_content"
            }
        }

        let delta: Delta
    }

    let choices: [Choice]
}

// MARK: - Client

struct NoLetChatClient {
    let account: AssistantAccount

    func chatsStream(query: ChatQuery) -> AsyncThrowingStream<ChatStreamResult, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var query = query
                    query.stream = true
                    let (bytes, response) = try await makeRequest(query: query)
                    if let http = response as? HTTPURLResponse,
                       !(200 ... 299).contains(http.statusCode)
                    {
                        var detail = ""
                        for try await line in bytes.lines { detail += line }
                        throw NoletError(message: "HTTP \(http.statusCode) \(detail)")
                    }
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        guard
                            let data = payload.data(using: .utf8),
                            let result = try? JSONDecoder().decode(
                                ChatStreamResult.self, from: data
                            )
                        else { continue }
                        continuation.yield(result)
                    }
                    continuation.finish()
                } catch {
                    if Task.isCancelled { continuation.finish() }
                    else { continuation.finish(throwing: error) }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// 非流式调用，目前仅用于连通性测试。
    func chats(query: ChatQuery) async throws {
        var query = query
        query.stream = false
        let (asyncBytes, response) = try await makeRequest(query: query)
        if let http = response as? HTTPURLResponse,
           !(200 ... 299).contains(http.statusCode)
        {
            var data = Data()
            for try await byte in asyncBytes { data.append(byte) }
            let detail = String(data: data, encoding: .utf8) ?? ""
            throw NoletError(message: "HTTP \(http.statusCode) \(detail)")
        }
    }

    private func makeRequest(
        query: ChatQuery
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        let basePath = account.basePath.isEmpty ? "/v1" : account.basePath
        let host = account.host.hasPrefix("http") ? account.host : "https://\(account.host)"
        guard let url = URL(string: "\(host)\(basePath)/chat/completions") else {
            throw NoletError(message: "Invalid endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(account.key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try query.body()

        return try await URLSession.shared.bytes(for: request)
    }
}
