//
//  openChatManager.swift
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

final class openChatManager: ObservableObject {
    static let shared = openChatManager()

    @Published var currentRequest: String = ""
    @Published var currentContent: String = ""

    @Published var currentMessageID: String = UUID().uuidString
    @Published var isFocusedInput: Bool = false

    @Published var groupsCount: Int = 0
    @Published var promptCount: Int = 0

    @Published var chatPrompt: ChatPrompt? = nil
    @Published var chatMessages: [ChatMessage] = []
    @Published private(set) var chatGroup: ChatGroup? = nil

    private let DB: DatabaseManager = .shared

    private var observationCancellable: AnyDatabaseCancellable?
    @Published var cancellableRequest: Task<Void, Never>?

    var currentChatMessage: ChatMessage {
        ChatMessage(
            id: currentMessageID,
            timestamp: .now,
            chat: "",
            request: currentRequest,
            content: currentContent,
            message: AppManager.shared.askMessageID
        )
    }

    private init() {
        startObservingUnreadCount()
    }

    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int, [ChatMessage], Int, ChatGroup?) in
            let id = try? ChatGroup.filter { $0.current }.fetchOne(db)?.id
            let groupsCount: Int = try ChatGroup.fetchCount(db)
            let messages: [ChatMessage] = try ChatMessage
                .filter(ChatMessage.Columns.chat == id).fetchAll(db)
            let promptCount: Int = try ChatPrompt.fetchCount(db)
            let current = try ChatGroup.filter { $0.current }.fetchOne(db)
            return (groupsCount, messages, promptCount, current)
        }

        observationCancellable = observation.start(
            in: DB.dbQueue,
            scheduling: .mainActor,
            onError: { error in
                NLog.error("Failed to observe unread count:", error)
            },
            onChange: { [weak self] datas in
                self?.groupsCount = datas.0
                self?.chatMessages = datas.1
                self?.promptCount = datas.2
                self?.chatGroup = datas.3
            }
        )
    }

    func setGroup(group: ChatGroup? = nil) {
        do {
            _ = try DB.dbQueue.write { db in
                if let group = group {
                    try ChatGroup
                        .filter { $0.id != group.id }
                        .updateAll(db, ChatGroup.Columns.current.set(to: false))
                    try ChatGroup
                        .filter { $0.id == group.id }
                        .updateAll(db, ChatGroup.Columns.current.set(to: true))
                } else {
                    try ChatGroup
                        .filter { $0.current }
                        .updateAll(db, ChatGroup.Columns.current.set(to: false))
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
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
                NLog.error("更新失败: \(error)")
            }
        }
    }

    func loadData() {
        Task.detached(priority: .background) {
            let results = try await self.DB.dbQueue.read { db in
                let group = try ChatGroup.filter(ChatGroup.Columns.current == true).fetchOne(db)
                let results = try ChatMessage
                    .filter(ChatMessage.Columns.chat == group?.id)
                    .order(ChatMessage.Columns.timestamp)
                    .limit(10)
                    .fetchAll(db)

                return results
            }
            await MainActor.run {
                self.chatMessages = results
            }
        }
    }
}

extension openChatManager {
    func test(account: AssistantAccount) async -> Bool {
        do {
            if account.host.isEmpty || account.key.isEmpty || account.basePath.isEmpty || account
                .model.isEmpty
            {
                NLog.log(account)
                return false
            }

            guard let openchat = getReady(account: account) else { return false }

            let query = ChatQuery(
                messages: [.user(.init(content: .string("Hello")))],
                model: account.model
            )

            _ = try await openchat.chats(query: query)

            return true

        } catch {
            NLog.error(error)
            return false
        }
    }

    func onceParams(text: String, tips: ChatPromptMode) -> ChatQuery? {
        guard let account = Defaults[.assistantAccouns].first(where: { $0.current }) else {
            return nil
        }
        let params: [ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(tips.prompt.content), name: tips.prompt.title)),
            .user(.init(content: .string(text))),
        ]

        return ChatQuery(messages: params, model: account.model)
    }

    func getHistoryParams(text: String, messageID: String? = nil) -> ChatQuery? {
        guard let account = Defaults[.assistantAccouns].first(where: { $0.current }) else {
            return nil
        }
        var params: [ChatQuery.ChatCompletionMessageParam] = []

        ///  增加system的前置参数
        if let promt = try? DB.dbQueue.read({ db in
            try ChatPrompt.filter(ChatPrompt.Columns.id == chatPrompt?.id).fetchOne(db)
        }) {
            params.append(.system(.init(content: .textContent(promt.content), name: promt.title)))
        }

        var inputText: String {
            if let messageID = messageID,
               let message = MessagesManager.shared.query(id: messageID)
            {
                return message.search + "\n" + text
            }
            return text
        }

        let limit = Defaults[.historyMessageCount]
        if let messageRaw = try? DB.dbQueue.read({ db in
            let group = try ChatGroup.filter(ChatGroup.Columns.current == true).fetchOne(db)
            return try ChatMessage
                .filter(ChatMessage.Columns.chat == group?.id)
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
        }) {
            for message in messageRaw {
                params.append(.user(.init(content: .string(message.request))))
                params.append(.assistant(.init(content: .textContent(message.content))))
            }
            params.append(.user(.init(content: .string(inputText))))
        }

        return ChatQuery(messages: params, model: account.model)
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
        tips: ChatPromptMode? = nil
    ) -> AsyncThrowingStream<ChatStreamResult, Error> {
        var query: ChatQuery? {
            if let tips = tips, let query = onceParams(text: text, tips: tips) {
                return query
            } else {
                return getHistoryParams(
                    text: text,
                    messageID: AppManager.shared.askMessageID
                )
            }
        }

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
                NLog.error("GRDB 错误: \(error)")
            }
        }
    }
}

extension ChatPromptMode {
    var prompt: ChatPrompt {
        switch self {
        case .summary(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "总结助手"),
                content: String(localized: """
                    你是一名专业总结助手，擅长从大量信息中提炼关键内容。总结时请遵循以下原则：
                    1. 提取核心观点，排除冗余信息。
                    2. 保持逻辑清晰，结构紧凑, 确定文章的中心主题，理解作者的论点和观点。
                    3. 列出关键点来传达文章的信息和细节。确保总结保持一致性，语言简洁明了
                    4. 可根据需要生成段落式或要点式总结, 遵循原文结构以提升阅读体验。
                    5. 有效地传达主要观点和情感层面，同时使用简洁清晰的语言
                    下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                    """),
                inside: true
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
                inside: true
            )
        case .writing(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "写作助手"),
                content: String(localized: """
                    你是一名专业写作助手，擅长各类文体的写作与润色。请根据以下要求优化文本：
                    1. 明确文章结构，增强逻辑连贯性。
                    2. 优化用词，使语言更准确流畅。
                    3. 强调重点，突出核心信息。
                    4. 使风格贴合目标读者的阅读习惯。
                    5. 纠正语法、标点和格式错误。
                    下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                    """),
                inside: true
            )
        case .code(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "代码助手"),
                content: String(localized: """
                    你是一位经验丰富的程序员，擅长编写清晰、简洁、易于维护的代码。请根据以下原则回答问题：
                    1. 提供完整、可运行的代码示例。
                    2. 简明解释关键实现细节。
                    3. 指出潜在的性能或结构优化点。
                    4. 关注代码的可扩展性、安全性和效率。
                    下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                    """),
                inside: true
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
                inside: true
            )
        }
    }

    static var prompts: [ChatPrompt] {
        [
            summary(lang()).prompt,
            translate(lang()).prompt,
            writing(lang()).prompt,
            code(lang()).prompt,
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
