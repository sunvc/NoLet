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

final class NoLetChatManager: ObservableObject {
    static let shared = NoLetChatManager()

    @Published var currentRequest: String = ""
    @Published var currentContent: String = ""
    @Published var currentReason: String = ""
    @Published var currentResult: [String: String] = [:]

    @Published var currentMessageID: String = UUID().uuidString
    @Published var isFocusedInput: Bool = false

    @Published var groupsCount: Int = 0
    @Published var messagesCount: Int = 0
    @Published var promptCount: Int = 0

    @Published var chatPrompt: ChatPrompt? = nil
    @Published var chatMessages: [ChatMessage] = []
    @Published private(set) var chatGroup: ChatGroup? = nil

    @Published var showPromptChooseView: Bool = false
    @Published var showAllHistory: Bool = false

    @Published var reasoningEffort: ReasoningEffort = .low

    @Published var startReason: String? = nil

    @Published var showReason: ChatMessage? = nil
    @Published var page: Int = 1

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

    private let groupDB: ChatGroupDBManager = .shared
    private let messageDB: ChatMessageDBManager = .shared

    private var groupObservationTask: Task<Void, Never>?
    private var messageCountObservationTask: Task<Void, Never>?

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
            chat: "",
            role: ChatMessage.Role.assistant.rawValue,
            content: currentContent,
            message: AppManager.shared.askMessageID,
            reason: currentReason,
            result: currentResult
        )
    }

    private init() {
        startObservingUnreadCount()
    }

    func updateTemMessage() {
        let id = currentChatMessage.id
        if let index = chatMessages.firstIndex(where: { $0.id == id }) {
            chatMessages[index] = currentChatMessage
        } else {
            chatMessages.append(currentChatMessage)
        }
    }

    private func startObservingUnreadCount() {
        groupObservationTask?.cancel()
        groupObservationTask = Task { [weak self] in
            guard let stream = self?.groupDB.observeSummary() else { return }
            for await summary in stream {
                guard let self = self else { break }
                await MainActor.run {
                    self.groupsCount = summary.groupsCount
                    self.chatGroup = summary.current
                }
                self.restartMessageCountObservation(groupID: summary.current?.id)
                await self.updateMessage()
            }
        }
    }

    private func restartMessageCountObservation(groupID: String?) {
        messageCountObservationTask?.cancel()
        messageCountObservationTask = Task { [weak self] in
            guard let stream = self?.messageDB.observeCount(inGroup: groupID) else { return }
            for await count in stream {
                await MainActor.run {
                    self?.messagesCount = count
                }
            }
        }
    }

    func updateMessage() async {
        let page = self.page
        guard let current = await groupDB.fetchCurrent() else { return }
        let messages = await messageDB.fetch(
            inGroup: current.id,
            ascending: true,
            limit: page * 50
        )
        await MainActor.run {
            self.chatMessages = messages
        }
    }


    func setPoint() async -> Bool {
        guard let chatGroup else { return false }
        return await groupDB.setPointToNow(id: chatGroup.id)
    }

    func setGroup(group: ChatGroup? = nil) {
        self.page = 1
        self.chatMessages = []
        self.chatGroup = group
        Task.detached(priority: .userInitiated) { [groupDB] in
            await groupDB.setCurrent(group)
        }
    }

    func updateGroupName(groupID: String, newName: String) {
        Task.detached(priority: .userInitiated) { [groupDB] in
            await groupDB.rename(id: groupID, newName: newName, makeCurrent: true)
        }
    }

    func delete(groupID: String? = nil) async {
        self.page = 1
        let targetID: String? = {
            if let groupID { return groupID }
            return self.chatGroup?.id
        }()
        guard let targetID = targetID else { return }
        await groupDB.delete(id: targetID)
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

        params += getHistory(Defaults[.historyMessageCount])

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

    private func getHistory(
        _ limit: Int
    ) -> [ChatCompletionMessageParam] {
        var params: [ChatCompletionMessageParam] = []
        let group = groupDB.fetchCurrentSync()
        let messageRaw = messageDB.fetchHistorySync(
            groupID: group?.id ?? "",
            after: group?.point,
            limit: limit
        )
        for message in messageRaw.reversed() {
            if message.role == ChatMessage.Role.user.rawValue {
                params.append(.user(.init(content: .string(message.content))))
            } else if message.role == ChatMessage.Role.assistant.rawValue {
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
                continuation.finish(throwing: NoletError(message: "No Account Or Query"))
            }
        }

        return openchat.chatsStream(query: query)
    }

    func clearunuse() {
        Task.detached(priority: .background) { [groupDB] in
            await groupDB.deleteEmpty()
        }
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
