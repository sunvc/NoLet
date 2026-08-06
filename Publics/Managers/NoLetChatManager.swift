//
//  NoLetChatManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/3/4.
//

import Defaults
import Foundation
import UIKit

struct ChatMessage: Identifiable, Hashable {
    let id: String
    var timestamp: Date
    var role: String
    var content: String
    var message: String?
    var reason: String?
    var result: [String: String]?
}

@MainActor
final class NoLetChatManager: ObservableObject {
    static let shared = NoLetChatManager()

    @Published var currentRequest: String = ""
    @Published var currentContent: String = ""
    @Published var currentReason: String = ""
    @Published var currentResult: [String: String] = [:]

    @Published var currentMessageID: String = UUID().uuidString
    @Published var isFocusedInput: Bool = false

    @Published var promptCount: Int = 0
    @Published var chatPrompt: ChatPrompt? = ChatPrompt.ChatPromptMode.mcp(Defaults[.lang]).prompt
    @Published var chatMessages: [ChatMessage] = []

    @Published var showPromptChooseView: Bool = false

    @Published var reasoningEffort: ReasoningEffort = .low

    @Published var startReason: String? = nil

    @Published var showReason: ChatMessage? = nil

    /// 此索引之前的消息不进入 API 上下文（"清除上下文"）。
    private var contextOffset: Int = 0

    /// ponytail: 消息只在内存中保存，固定保留最近若干条。
    private static let maxMessages = 10

    lazy var contentActor = StreamTextAggregator { [weak self] chunk in
        Task { @MainActor in
            self?.currentContent.append(chunk)
            self?.updateTemMessage()
        }
    }

    lazy var reasonActor = StreamTextAggregator { [weak self] chunk in
        Task { @MainActor in
            self?.currentReason.append(chunk)
            self?.updateTemMessage()
        }
    }

    private let webSearchConfig = WebSearchOptions(
        userLocation: .init(
            country: Locale.current.region?.identifier ?? "",
            city: ""
        ),
        searchContextSize: .high
    )

    var cancellableRequest: Task<Void, Never>?

    var currentChatMessage: ChatMessage {
        ChatMessage(
            id: currentMessageID,
            timestamp: .now,
            role: "assistant",
            content: currentContent,
            message: AppManager.shared.askMessageID,
            reason: currentReason,
            result: currentResult
        )
    }

    private init() {}

    func appendUserMessage(
        id: String,
        content: String,
        timestamp: Date = .now,
        quoteMessageID: String? = nil
    ) {
        chatMessages.append(ChatMessage(
            id: id,
            timestamp: timestamp,
            role: "user",
            content: content,
            message: quoteMessageID,
            reason: nil,
            result: nil
        ))
        trimToLast10()
    }

    func updateTemMessage() {
        let id = currentChatMessage.id
        if let index = chatMessages.firstIndex(where: { $0.id == id }) {
            chatMessages[index] = currentChatMessage
        } else {
            chatMessages.append(currentChatMessage)
            trimToLast10()
        }
    }

    private func trimToLast10() {
        while chatMessages.count > Self.maxMessages {
            chatMessages.removeFirst()
            contextOffset = max(0, contextOffset - 1)
        }
    }

    /// "清除上下文"：当前屏幕上的消息不再发送给 API。
    @discardableResult
    func setPoint() -> Bool {
        contextOffset = chatMessages.count
        return true
    }

    /// 清空屏幕，开始新对话。
    func clear() {
        contextOffset = 0
        chatMessages = []
        currentRequest = ""
        currentContent = ""
        currentReason = ""
        currentResult = [:]
    }
}

extension NoLetChatManager {
    func test(account: AssistantAccount) async -> Bool {
        do {
            if account.host.isEmpty || account.key.isEmpty || account.basePath.isEmpty || account
                .model.isEmpty
            {
                logger.info("\(String(describing: account))")
                return false
            }

            guard let openchat = getReady(account: account) else { return false }

            let query = ChatQuery(
                messages: [.user(.init(content: .string("Hello")))],
                model: account.model
            )

            try await openchat.chats(query: query)
            return true

        } catch {
            logger.error("\(error)")
            return false
        }
    }

    func getHistoryParams(
        text: String,
        messageID: String? = nil,
        tips: ChatPrompt.ChatPromptMode? = nil,
        rounds: Int = 1
    ) -> ChatQuery? {
        guard let account = Defaults[.assistantAccouns].first(where: { $0.current }) else {
            return nil
        }

        let temperature = Double(Defaults[.temperatureChat]) / 10

        var params: [ChatCompletionMessageParam] = []

        if let tips {
            params.append(.system(.init(
                content: .textContent(tips.prompt.content),
                name: tips.prompt.title
            )))

            if rounds > 1 {
                params.append(.user(.init(content: .string(currentRequest))))
            }

            params.append(.user(.init(content: .string(text))))

            return ChatQuery(
                messages: params,
                model: account.model,
                reasoningEffort: reasoningEffort == .none ? nil : reasoningEffort ,
                temperature: temperature,
                webSearchOptions: webSearchConfig
            )
        }

        if let promt = chatPrompt {
            params.append(.system(.init(content: .textContent(promt.content), name: promt.title)))

            if promt.mode == .mcp || promt.mode == .call {
                params += getHistory(2)
                if rounds > 1 {
                    params.append(.user(.init(content: .string(currentRequest))))
                }
                params.append(.user(.init(content: .string(text))))

                return ChatQuery(
                    messages: params,
                    model: account.model,
                    reasoningEffort: reasoningEffort == .none ? nil : reasoningEffort ,
                    temperature: temperature,
                    tools: NoLetChatAction.funcs().map { .init(function: $0) },
                    webSearchOptions: webSearchConfig
                )
            }
        }


        var inputText: String {
            if let messageID = messageID,
               let message = MessagesManager.shared.query(id: messageID)
            {
                return message.search + "\n\n" + text
            }
            return text
        }

        params += getHistory()

        if rounds > 1 {
            params.append(.user(.init(content: .string(currentRequest))))
        }
        params.append(.user(.init(content: .string(inputText))))

        return ChatQuery(
            messages: params,
            model: account.model,
            reasoningEffort: reasoningEffort == .none ? nil : reasoningEffort ,
            temperature: temperature,
            webSearchOptions: webSearchConfig
        )
    }

    private func getHistory(_ limit: Int? = nil) -> [ChatCompletionMessageParam] {
        var messages = Array(chatMessages.dropFirst(contextOffset))
        if let limit, messages.count > limit {
            messages = Array(messages.suffix(limit))
        }

        var params: [ChatCompletionMessageParam] = []
        for message in messages {
            if message.role == "user" {
                params.append(.user(.init(content: .string(message.content))))
            } else if message.role == "assistant" {
                if let result = message.result, !result.isEmpty, let json = result.text() {
                    params.append(.user(.init(
                        content: .string(String(localized: "任务执行结果") + json)
                    )))
                }

                if !message.content.isEmpty {
                    params.append(.assistant(.init(content: .textContent(message.content))))
                }
            }
        }

        return params
    }

    func getReady(account: AssistantAccount? = nil) -> NoLetChatClient? {
        if let account {
            return NoLetChatClient(account: account)
        }
        guard let account = Defaults[.assistantAccouns].first(where: { $0.current }) else {
            return nil
        }
        return NoLetChatClient(account: account)
    }

    func chatsStream(
        text: String,
        tips: ChatPrompt.ChatPromptMode? = nil,
        messageID: String? = nil,
        rounds: Int = 1
    ) -> AsyncThrowingStream<ChatStreamResult, Error> {
        let query = getHistoryParams(
            text: text, messageID: messageID,
            tips: tips, rounds: rounds
        )

        guard let openchat = getReady(), let query = query else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: NoletError( "No Account Or Query"))
            }
        }

        return openchat.chatsStream(query: query)
    }
}

extension NoLetChatManager {
    actor StreamTextAggregator {
        // MARK: - Configuration

        private let minCharsToFlush: Int
        private let maxDelay: UInt64
        private let onFlush: @Sendable (String) -> Void

        // MARK: - State

        private var buffer: String = ""
        private var lastFlushTime: UInt64 = 0
        private var flushTask: Task<Void, Never>?

        // MARK: - Init

        init(
            minCharsToFlush: Int = 30,
            maxDelayMilliseconds: UInt64 = 150,
            onFlush: @escaping @Sendable (String) -> Void
        ) {
            self.minCharsToFlush = minCharsToFlush
            maxDelay = maxDelayMilliseconds * 1_000_000
            self.onFlush = onFlush
        }

        // MARK: - Public API

        func append(_ newText: String) {
            buffer.append(newText)
            scheduleFlushIfNeeded()
        }

        /// 在流结束时调用，确保最后一段内容被刷新
        func finish() {
            flush()
        }

        // MARK: - Private

        private func scheduleFlushIfNeeded() {
            let now = DispatchTime.now().uptimeNanoseconds

            if buffer.count >= minCharsToFlush {
                flush()
                return
            }

            if now - lastFlushTime >= maxDelay {
                flush()
                return
            }

            if flushTask == nil {
                flushTask = Task {
                    try? await Task.sleep(nanoseconds: maxDelay)
                    flush()
                }
            }
        }

        private func flush() {
            guard !buffer.isEmpty else { return }

            let textToSend = buffer
            buffer = ""
            lastFlushTime = DispatchTime.now().uptimeNanoseconds

            flushTask?.cancel()
            flushTask = nil

            onFlush(textToSend)
        }
    }
}
