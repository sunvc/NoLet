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
import GRDB
import OpenAI
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
    @Published var currentMessagesCount: Int = 0
    @Published var promptCount: Int = 0

    @Published var chatPrompt: ChatPrompt? = nil
    @Published var chatMessages: [ChatMessage] = []
    @Published private(set) var chatGroup: ChatGroup? = nil

    @Published var showPromptChooseView: Bool = false
    @Published var showAllHistory: Bool = false

    @Published var reasoningEffort: ReasoningEffort = .minimal

    @Published var startReason: String? = nil

    @Published var showReason: ChatMessage? = nil

    private let DB: DatabaseManager = .shared

    private var observationCancellable: AnyDatabaseCancellable?

    private let webSearchConfig = ChatQuery.WebSearchOptions(
        userLocation: ChatQuery.WebSearchOptions
            .UserLocation(approximate:
                Components.Schemas.WebSearchLocation(
                    country: Locale.current.region?.identifier ?? "",
                    city: ""
                )
            ),
        searchContextSize: .high
    )

    var cancellableRequest: Task<Void, Never>?

    var currentChatMessage: ChatMessage {
        ChatMessage(
            id: currentMessageID,
            timestamp: .now,
            chat: "",
            request: currentRequest,
            content: currentContent,
            message: AppManager.shared.askMessageID,
            reason: currentReason,
            result: currentResult
        )
    }

    private init() {
        startObservingUnreadCount()
    }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (
            Int,
            [ChatMessage],
            Int,
            ChatGroup?,
            Int
        ) in
            let current = try? ChatGroup.filter { $0.current }.fetchOne(db)
            let groupsCount: Int = try ChatGroup.fetchCount(db)

            let messageCount: Int = try ChatMessage
                .filter(ChatMessage.Columns.chat == current?.id)
                .fetchCount(db)

            let messages: [ChatMessage] = try ChatMessage
                .filter(ChatMessage.Columns.chat == current?.id)
                .order(\.timestamp.desc)
                .limit(10)
                .fetchAll(db)
            let promptCount: Int = try ChatPrompt.fetchCount(db)
            return (groupsCount, messages.reversed(), promptCount, current, messageCount)
        }

        observationCancellable = observation.start(
            in: DB.dbQueue,
            scheduling: .mainActor,
            onError: { error in
                logger.error("Failed to observe unread count: \(error)")
            },
            onChange: { [weak self] datas in
                self?.groupsCount = datas.0
                self?.chatMessages = datas.1
                self?.promptCount = datas.2
                self?.chatGroup = datas.3
                self?.currentMessagesCount = datas.4
            }
        )
    }

    func getCurrentMessages() -> [ChatMessage] {
        do {
            return try DB.dbQueue.read { db in
                let current = try? ChatGroup.filter { $0.current }.fetchOne(db)
                return try ChatMessage
                    .filter(ChatMessage.Columns.chat == current?.id)
                    .order(\.timestamp)
                    .limit(10)
                    .fetchAll(db)
            }
        } catch {
            return []
        }
    }

    func setPoint() async -> Bool {
        guard let chatGroup else { return false }
        do {
            return try await DB.dbQueue.write { db in
                if var chatgroup = try ChatGroup.filter(id: chatGroup.id).fetchOne(db) {
                    chatgroup.point = .now
                    try chatgroup.upsert(db)
                    return true
                }
                return false
            }
        } catch {
            return false
        }
    }

    func setGroup(group: ChatGroup? = nil) {
        do {
            _ = try DB.dbQueue.write { [weak self] db in
                if let group = group {
                    try ChatGroup
                        .filter { $0.id != group.id }
                        .updateAll(db, ChatGroup.Columns.current.set(to: false))
                    try ChatGroup
                        .filter { $0.id == group.id }
                        .updateAll(db, ChatGroup.Columns.current.set(to: true))
                    self?.chatGroup = group
                } else {
                    try ChatGroup
                        .filter { $0.current }
                        .updateAll(db, ChatGroup.Columns.current.set(to: false))
                    self?.chatGroup = nil
                }
            }
        } catch {
            debugPrint(error)
        }
    }

    func updateGroupName(groupID: String, newName: String) {
        Task.detached(priority: .userInitiated) {
            do {
                try await self.DB.dbQueue.write { db in
                    var group = try ChatGroup.filter(ChatGroup.Columns.id == groupID).fetchOne(db)
                    group?.name = newName
                    group?.current = true
                    try group?.update(db)
                }
            } catch {
                logger.error("更新失败: \(error)")
            }
        }
    }

    func delete(groupID: String? = nil) async {
        try? await DB.dbQueue.write { db in
            var group: ChatGroup? {
                if let groupID {
                    return try? ChatGroup.fetchOne(db, key: groupID)
                } else {
                    return try? ChatGroup.filter { $0.current }.fetchOne(db)
                }
            }

            if let group = try ChatGroup.filter({ $0.id == group?.id }).fetchOne(db) {
                // 删除与该 group.id 关联的所有 ChatMessage
                try ChatMessage
                    .filter(ChatMessage.Columns.chat == group.id)
                    .deleteAll(db)

                // 删除该 ChatGroup 本身
                try group.delete(db)
            }
        }
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

            let data = try await openchat.chats(query: query)
            logger.info("\(String(describing: data))")
            return true

        } catch {
            logger.error("\(error)")
            return false
        }
    }

    func getHistoryParams(
        text: String,
        messageID: String? = nil,
        tips: ChatPromptMode? = nil,
        rounds: Int = 1
    ) -> ChatQuery? {
        guard let account = Defaults[.assistantAccouns].first(where: { $0.current }) else {
            return nil
        }

        let temperature = Double(Defaults[.temperatureChat]) / 10

        var params: [ChatQuery.ChatCompletionMessageParam] = []

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
                reasoningEffort: reasoningEffort,
                temperature: temperature,
                webSearchOptions: webSearchConfig
            )
        }

        ///  增加system的前置参数
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
                    reasoningEffort: reasoningEffort,
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
            reasoningEffort: reasoningEffort,
            temperature: temperature,
            webSearchOptions: webSearchConfig
        )
    }

    private func getHistory(
        _ limit: Int
    ) -> [ChatQuery.ChatCompletionMessageParam] {
        var params: [ChatQuery.ChatCompletionMessageParam] = []
        if let messageRaw = try? DB.dbQueue.read({ db in
            let group = try ChatGroup.filter(ChatGroup.Columns.current == true).fetchOne(db)
            if let point = group?.point {
                return try ChatMessage
                    .filter(ChatMessage.Columns.chat == group?.id)
                    .filter(ChatMessage.Columns.timestamp > point)
                    .order(\.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)

            } else {
                return try ChatMessage
                    .filter(ChatMessage.Columns.chat == group?.id)
                    .order(\.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }

        }) {
            for message in messageRaw.reversed() {
                params.append(.user(.init(content: .string(message.request))))

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

    func getReady(account: AssistantAccount? = nil) -> OpenAI? {
        if let account = account {
            let config = OpenAI.Configuration(
                token: account.key,
                host: account.host,
                basePath: account.basePath
            )

            return OpenAI(configuration: config)
        } else {
            guard let account = Defaults[.assistantAccouns].first(where: { $0.current }) else {
                return nil
            }
            let config = OpenAI.Configuration(
                token: account.key,
                host: account.host,
                basePath: account.basePath
            )

            return OpenAI(configuration: config)
        }
    }

    func chatsStream(
        text: String,
        tips: ChatPromptMode? = nil,
        messageID: String? = nil,
        rounds: Int = 1
    ) -> AsyncThrowingStream<ChatStreamResult, Error> {
        let query = getHistoryParams(
            text: text, messageID: messageID,
            tips: tips, rounds: rounds
        )
        guard let openchat = getReady(), let query = query else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: "No Account Or Query")
            }
        }

        return openchat.chatsStream(query: query)
    }

    func clearunuse() {
        Task.detached(priority: .background) {
            do {
                try self.DB.dbQueue.write { db in
                    let allGroups = try ChatGroup.fetchAll(db)
                    var deleteList: [ChatGroup] = []

                    for group in allGroups {
                        let messageCount = try ChatMessage
                            .filter(ChatMessage.Columns.chat == group.id)
                            .fetchCount(db)

                        if messageCount == 0 {
                            deleteList.append(group)
                        }
                    }

                    for group in deleteList {
                        try group.delete(db)
                    }
                }
            } catch {
                logger.error("GRDB 错误: \(error)")
            }
        }
    }
}

extension ChatPromptMode {
    var prompt: ChatPrompt {
        switch self {
        case .mcp:
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "APP助手"),
                content: String(
                    localized: "你是由 NoLet App 集成的智能助手. 你可以使用 manage_app 工具来控制应用(设置、导航、数据、缓存、消息管理).当用户要求执行此工具支持的任何操作(例如: 打开设置,清除缓存,更改图标,删除上周的消息)时，你必须立即调用 'manage_app' 并提供正确的参数."
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
                    下面我给你内容，直接按照 \(lang ?? Self.lang()) 进行翻译.
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
                    下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                    """),
                inside: true,
                mode: .promt
            )
        }
    }

    static var prompts: [ChatPrompt] {
        [
            mcp(lang()).prompt,
            translate(lang()).prompt,
            abstract(lang()).prompt,
        ]
    }

    static func lang() -> String {
        let currentLang = Defaults[.lang]
        if let code = Locale(identifier: currentLang).language.languageCode?.identifier,
           let lang = Locale.current.localizedString(forLanguageCode: code)
        {
            return lang
        }
        return "English"
    }
}
