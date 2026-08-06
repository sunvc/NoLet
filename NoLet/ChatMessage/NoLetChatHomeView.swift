//
//  AssistantPageView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo on 2025/3/5.
//

import Combine
import Defaults
import SwiftUI

struct NoLetChatHomeView: View {
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.showAssistantAnimation) var showAssistantAnimation

    @ObservedObject private var manager = AppManager.shared
    @ObservedObject private var chatManager = NoLetChatManager.shared

    @State private var inputText: String = ""

    @FocusState private var isInputActive: Bool

    @State private var rotateWhenExpands: Bool = false
    @State private var disablesInteractions: Bool = true
    @State private var disableCorners: Bool = true

    @State private var showChangeGroupName: Bool = false

    @State private var offsetX: CGFloat = 0
    @State private var offsetHistory: CGFloat = 0
    @State private var fengche: Bool = false
    @State private var hidenTabar: Bool = false

    @State private var showDeleteView: Bool = false
    
    @State private var deleteDate: Date = Date().zeroDate()

    var body: some View {
        ZStack {
            ChatMessageArrayView()
            if chatManager.chatMessages.count == 0 {
                spaceHome
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatInputView(
                text: $inputText,
                onSend: { text in
                    chatManager.cancellableRequest?.cancel()
                    chatManager.cancellableRequest = Task
                        .detached(priority: .userInitiated) {
                            await sendMessage(text)
                        }
                }
            )
            
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .popView(isPresented: $showChangeGroupName) {
            showChangeGroupName = false
        } content: {
            if let chatgroup = chatManager.chatGroup {
                CustomAlertWithTextField($showChangeGroupName, text: chatgroup.name ?? "") { text in
                    chatManager.updateGroupName(groupID: chatgroup.id ?? "", newName: text)
                }
            } else {
                Spacer()
                    .onAppear {
                        self.showChangeGroupName = false
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                StreamingLoadingView(showLoading: manager.isLoading)
                    .transition(.scale)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    AppManager.hideKeyboard()
                    manager.router.append(.noletChatSetting(nil))
                    Haptic.impact()
                }) {
                    Label("打开设置", systemImage: "gear")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, .primary)
                }
            }
        }

        .onAppear {
            Task { @MainActor in
                manager.inAssistant = true
            }
        }
        .onDisappear {
            manager.askMessageID = nil
            manager.inAssistant = false
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $chatManager.showAllHistory) {
            ChatGroupHistoryView(show: $chatManager.showAllHistory)
                .customPresentationCornerRadius(30)
                .presentationDetents([.height(UIScreen.main.bounds.size.height * 0.7), .large])
        }
        .sheet(isPresented: $chatManager.showPromptChooseView) {
            PromptChooseView(show: $chatManager.showPromptChooseView)
                .customPresentationCornerRadius(30)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $chatManager.showReason) { _ in
            ReasonMessageView(message: $chatManager.showReason)
                .customPresentationCornerRadius(30)
                .presentationDetents([.medium, .large])
        }
        .deleteTips($showDeleteView, date: deleteDate)
    }

    private var spaceHome: some View {
        VStack {
            Spacer()
            VStack {
                Image("agent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .minimumScaleFactor(0.5)
                
                
                Text("Less Talk, More Action.")
                    .font(.custom("SavoyeLetPlain", size: 39))
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal)
        .transition(.opacity)
        .onTapGesture {
            AppManager.hideKeyboard()
            Haptic.impact()
        }
    }

    // 发送消息
    private func sendMessage(_ text: String) async {
        AppManager.hideKeyboard()

        guard assistantAccouns.first(where: { $0.current }) != nil else {
            manager.router.append(.noletChatSetting(nil))
            return
        }

        if !text.isEmpty {
            let userMessageID = UUID().uuidString
            let assistantMessageID = UUID().uuidString
            
            Task { @MainActor in
                chatManager.currentMessageID = assistantMessageID
                withAnimation {
                    manager.isLoading = true
                }

                self.inputText = ""
                chatManager.currentContent = ""
                chatManager.updateTemMessage()
            }

            guard let newGroup = await getGroup(text: text) else { return }
            
            let userMessage = ChatMessageDBManager.shared.makeTransient(
                id: userMessageID,
                timestamp: .now,
                chat: newGroup.id ?? "",
                role: "user",
                content: text,
                message: manager.askMessageID,
                reason: nil,
                result: nil
            )

            do {
                try await ChatMessageDBManager.shared.insert(userMessage)
            } catch {
                logger.error("保存用户消息失败: \(error.localizedDescription)")
            }

            let results = chatManager.chatsStream(text: text, messageID: manager.askMessageID)

            var toolCallsMap: [Int: (name: String, args: String)] = [:]

            do {
                for try await result in results {
                    if let choice = result.choices.first {
                        toolCallsMap = resultHandler(choice: choice, toolCallsMap: toolCallsMap)
                    }
                }
                await chatManager.contentActor.finish()
                await chatManager.reasonActor.finish()
                Haptic.impact()

                if !toolCallsMap.isEmpty {
                    chatManager.currentResult = await runChatCall(params: toolCallsMap)

                    if !chatManager.currentResult.isEmpty,
                       let text = chatManager.currentResult.text()
                    {
                        Task { @MainActor in
                            chatManager.currentContent += "\n"
                        }

                        let results = chatManager.chatsStream(
                            text: "Function Call Results:\(text)",
                            messageID: manager.askMessageID,
                            rounds: 2
                        )

                        for try await result in results {
                            if let choice = result.choices.first {
                                resultHandler(choice: choice)
                            }
                        }

                        await chatManager.contentActor.finish()
                        await chatManager.reasonActor.finish()
                    }
                }

                let responseMessage = chatManager.currentChatMessage
                responseMessage.id = assistantMessageID
                responseMessage.chat = newGroup.id

                try await ChatMessageDBManager.shared.insert(responseMessage)

                Task { @MainActor in
                    self.clearCurrent()
                }
            } catch is CancellationError {
                logger.debug("取消请求")
                Task { @MainActor in
                    self.clearCurrent()
                }
                return
            } catch {
                logger.error("\(error.localizedDescription)")
                Task { @MainActor in
                    Toast.shared.present(title: error.localizedDescription, symbol: .error)
                    self.clearCurrent()
                }
                return
            }
        }
    }

    @discardableResult
    func resultHandler(
        choice: ChatStreamResult.Choice,
        toolCallsMap: [Int: (name: String, args: String)] = [:]
    ) -> [Int: (name: String, args: String)] {
        var toolCallsMap = toolCallsMap
        if let text = choice.delta.reasoning {
            Task { @MainActor in
                await chatManager.reasonActor.append(text)
                if chatManager.startReason == nil {
                    chatManager.startReason = chatManager.currentMessageID
                }
            }
        } else {
            if chatManager.startReason != nil {
                chatManager.startReason = nil
            }
        }

        if let outputItem = choice.delta.content {
            Task { @MainActor in
                await chatManager.contentActor.append(outputItem)
                if AppManager.shared.inAssistant && showAssistantAnimation {
                    Haptic.selection()
                }
            }
        }

        if let toolCalls = choice.delta.toolCalls {
            for toolCall in toolCalls {
                let index = toolCall.index

                var current = toolCallsMap[index] ?? ("", "")

                if let name = toolCall.function?.name {
                    current.name = name
                    logger.info("Tool call name received for index \(index): \(name)")
                }
                if let args = toolCall.function?.arguments {
                    current.args += args
                }

                toolCallsMap[index] = current
            }
        }
        return toolCallsMap
    }

    func clearCurrent() {
        chatManager.currentRequest = ""
        chatManager.currentContent = ""
        chatManager.currentReason = ""
        chatManager.currentResult = [:]
        manager.isLoading = false
    }

    func getGroup(text: String) async -> ChatGroupEntity? {
        if let group = chatManager.chatGroup {
            return group
        } else {
            let id = manager.askMessageID ?? UUID().uuidString
            let name = String(text.removingAllWhitespace.prefix(10))
            do {
                return try await ChatGroupDBManager.shared.insert(
                    id: id, timestamp: .now, name: name, host: "", current: true
                )
            } catch {
                return nil
            }
        }
    }

    func runChatCall(params: [Int: (name: String, args: String)]) async -> [String: String] {
        var results: [String: String] = [:]
        for (_, (name, args)) in params {
            if !name.isEmpty, !args.isEmpty {
                if let json = args.jsonData() {
                    let result = await NoLetChatAction.runFunc(
                        name: name,
                        args: json
                    )

                    // BUG: - 
                    if let date = result.0 {
                        self.deleteDate = date
                        self.showDeleteView = true
                    }

                    results += result.1
                } else {
                    results[name] = "Error JSON"
                }
            }
        }
        return results
    }
}

fileprivate extension String {
    
    func jsonData() -> [String: Any]? {
        if let data = data(using: .utf8),
           let json = try? JSONSerialization
            .jsonObject(with: data, options: []) as? [String: Any]
        {
            return json
        }
        return nil
    }
}

#Preview {
    NoLetChatHomeView()
}
