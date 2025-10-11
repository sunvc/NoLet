//
//  OpenChatManager.swift
//  pushback
//
//  Created by uuneo on 2025/3/4.
//

import Foundation
import OpenAI
import Defaults
import GRDB
import UIKit


final class openChatManager: ObservableObject {
    
    static let shared = openChatManager()
    
    @Published var currentRequest:String = ""
    @Published var currentContent:String = ""
 
    @Published var currentMessageId:String = UUID().uuidString
    @Published var isFocusedInput:Bool = false
    
    @Published var groupsCount:Int = 0
    @Published var promptCount:Int = 0
    
    @Published var chatgroup:ChatGroup? = nil
    @Published var chatPrompt:ChatPrompt? = nil
    @Published var chatMessages:[ChatMessage] = []
    
    
    private let DB: DatabaseManager = DatabaseManager.shared

    private var observationCancellable: AnyDatabaseCancellable?
    var cancellableRequest:CancellableRequest? = nil
    
    var currentChatMessage:ChatMessage{
        ChatMessage(id: currentMessageId, timestamp: .now, chat: "", request: currentRequest, content: currentContent, message: AppManager.shared.askMessageId)
    }
    
    
    private init(){
        startObservingUnreadCount()
    }
    
    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int,[ChatMessage],Int) in
            let groupsCount:Int =  try ChatGroup.fetchCount(db)
            let messages:[ChatMessage] = try ChatMessage.filter(ChatMessage.Columns.chat == self.chatgroup?.id).fetchAll(db)
            let promptCount:Int = try ChatPrompt.fetchCount(db)
            return (groupsCount, messages, promptCount)
        }
        
        observationCancellable = observation.start(
            in: DB.dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                NLog.error("Failed to observe unread count:", error)
            },
            onChange: { [weak self] newUnreadCount in
                DispatchQueue.main.async {
                    self?.groupsCount = newUnreadCount.0
                    self?.chatMessages = newUnreadCount.1
                    self?.promptCount = newUnreadCount.2
                }
            }
        )
    }
    
    func updateGroupName( groupId: String, newName: String) {
        Task.detached(priority: .userInitiated) {
            do {
                try await self.DB.dbQueue.write { db in
                    if var group = try ChatGroup.filter(ChatGroup.Columns.id == groupId).fetchOne(db) {
                        group.name = newName
                        try group.update(db)
                        DispatchQueue.main.async {
                            openChatManager.shared.chatgroup = group
                        }
                        
                    }
                }
            } catch {
                NLog.error("更新失败: \(error)")
            }
        }
        
    }
    
    func loadData(){
        if let id = chatgroup?.id{
            Task.detached(priority: .background) {
                let results = try await  DatabaseManager.shared.dbQueue.read { db in
                    let results  =  try ChatMessage
                        .filter(ChatMessage.Columns.chat == id)
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
    
}

extension openChatManager{
    func test(account: AssistantAccount) async ->Bool{
        
        do{
            if account.host.isEmpty || account.key.isEmpty || account.basePath.isEmpty || account.model.isEmpty{
                NLog.log(account)
                return false
            }
            
            
            guard let openchat = self.getReady(account: account) else {  return false }
            
            let query = ChatQuery(messages: [.user(.init(content: .string("Hello")))], model: account.model)
            
            _ = try await openchat.chats(query: query)
            
            return true
            
        }catch{
            NLog.error(error)
            return false
        }
        
        
    }
    
    func onceParams(text: String, tips:ChatPromptMode) -> ChatQuery?{

        guard  let account =  Defaults[.assistantAccouns].first(where: {$0.current}) else {
            return nil
        }
        let params:[ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(tips.prompt.content),name: tips.prompt.title)),
            .user(.init(content: .string(text)))
        ]
        
        return ChatQuery(messages: params, model: account.model)
        
    }
    
    func getHistoryParams(text: String, messageId:String? = nil)-> ChatQuery?{
        
        
        guard  let account = Defaults[.assistantAccouns].first(where: {$0.current}) else {
            return nil
        }
        var params:[ChatQuery.ChatCompletionMessageParam] = []
        
        ///  增加system的前置参数
        if let promt = try? DB.dbQueue.read({ db in
            try ChatPrompt.filter(ChatPrompt.Columns.id == chatPrompt?.id).fetchOne(db)
        }){
            params.append(.system(.init(content: .textContent(promt.content), name: promt.title)))
        }
        
        var inputText:String{
            
            if let messageId = messageId, let message = MessagesManager.shared.query(id: messageId){
                return message.search + "\n" + text
            }
            return text
        }
        
        
        let limit = Defaults[.historyMessageCount]
        if  let messageRaw = try? DB.dbQueue.read({ db in
            try ChatMessage
                .filter(ChatMessage.Columns.chat == chatgroup?.id)
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
        }){
            for message in messageRaw{
                params.append(.user(.init(content: .string(message.request))))
                params.append(.assistant(.init(content: .textContent(message.content))))
                
            }
            params.append(.user(.init(content: .string(inputText))))
        }
        
        
        
        
        
        return ChatQuery(messages: params, model: account.model)
    }
    
    func getReady(account:AssistantAccount? = nil) -> OpenAI?{
        if let account = account {
            
            let config = OpenAI.Configuration(token: account.key,host: account.host, basePath: account.basePath)
            
            return OpenAI(configuration: config)
        }else {
            guard  let account = Defaults[.assistantAccouns].first(where: {$0.current}) else {
                return nil
            }
            let config = OpenAI.Configuration(token: account.key,host: account.host, basePath: account.basePath)
            
            return OpenAI(configuration: config)
        }
        
    }
    
    func chatsStream(text:String, account:AssistantAccount? = nil,onResult: @escaping @Sendable (Result<ChatStreamResult, Error>) -> Void, completion: (@Sendable (Error?) -> Void)?)  {
        guard let openchat = self.getReady(), let query = self.getHistoryParams(text: text,messageId: AppManager.shared.askMessageId) else {
            completion?("noConfig")
            return
        }
        self.cancellableRequest = openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    func chatsStream(text:String, tips:ChatPromptMode, account:AssistantAccount? = nil,onResult: @escaping @Sendable (Result<ChatStreamResult, Error>) -> Void, completion: (@Sendable (Error?) -> Void)?) -> CancellableRequest? {
        guard let openchat = self.getReady(), let query = self.onceParams(text: text, tips: tips) else {
            completion?("noConfig")
            return nil
        }
        
        return openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    
    
    func clearunuse(){
        Task.detached(priority: .background) {
            do {
                try self.DB.dbQueue.write { db in
                    
                    // 1. 查找无关联 ChatMessage 的 ChatGroup
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
