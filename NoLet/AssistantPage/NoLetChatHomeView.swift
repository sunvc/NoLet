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
import GRDB
import OpenAI
import SwiftUI

struct NoLetChatHomeView: View {
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.showAssistantAnimation) var showAssistantAnimation

    @EnvironmentObject private var manager: AppManager
    @StateObject private var chatManager = NoLetChatManager.shared

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

    var body: some View {
        ZStack {
            ChatMessageListView()
            VStack {
                if chatManager.chatMessages.count == 0 && !manager.isLoading {
                    VStack {
                        Spacer()

                        VStack {
                            ChatIcon()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .red, location: 0.0),
                                            .init(color: .yellow, location: 0.5),
                                            .init(color: .green, location: 1.0),
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .scaledToFit()
                                .frame(width: 200)
                                .minimumScaleFactor(0.5)

                            Text("嗨! 我是无字书")
                                .font(.title)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)

                            Text("我可以帮你搜索，答疑，写作，管理App, 请把你的任务交给我吧！")
                                .multilineTextAlignment(.center)
                                .padding(.vertical)
                                .font(.body)
                                .foregroundStyle(.gray)
                        }

                        Spacer()
                        Spacer()
                    }
                    .transition(.slide)
                    .onTapGesture {
                        self.hideKeyboard()
                        Haptic.impact()
                    }
                }

                Spacer()
            }
            VStack {
                Spacer()
                // 底部输入框
                ChatInputView(
                    text: $inputText,
                    onSend: { text in
                        chatManager.cancellableRequest?.cancel()
                        chatManager.cancellableRequest = Task.detached(priority: .userInitiated) {
                            await sendMessage(text)
                        }
                    }
                )
                .transition(.move(edge: .trailing).animation(.easeInOut))
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .popView(isPresented: $showChangeGroupName) {
            showChangeGroupName = false
        } content: {
            if let chatgroup = chatManager.chatGroup {
                CustomAlertWithTextField($showChangeGroupName, text: chatgroup.name) { text in
                    chatManager.updateGroupName(groupID: chatgroup.id, newName: text)
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

            ToolbarItem(placement: .secondaryAction) {
                Button(action: {
                    self.hideKeyboard()
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
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $chatManager.showAllHistory) {
            ChatGroupHistoryView(show: $chatManager.showAllHistory)
                .customPresentationCornerRadius(50)
        }
        .sheet(isPresented: $chatManager.showPromptChooseView) {
            PromptChooseView(show: $chatManager.showPromptChooseView)
                .customPresentationCornerRadius(50)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $chatManager.showReason) { _ in
            ReasonMessageView(message: $chatManager.showReason)
                .customPresentationCornerRadius(50)
                .presentationDetents([.medium, .large])
        }
        .environmentObject(chatManager)
    }

    // 发送消息
    private func sendMessage(_ text: String) async {
        hideKeyboard()

        guard assistantAccouns.first(where: { $0.current }) != nil else {
            manager.router.append(.noletChatSetting(nil))
            return
        }

        if !text.isEmpty {
            Task { @MainActor in
                chatManager.currentMessageID = UUID().uuidString
                manager.isLoading = true
                chatManager.currentRequest = text

                self.inputText = ""
                chatManager.currentContent = ""
            }

            guard let newGroup = getGroup(text: text) else { return }

            let results = chatManager.chatsStream(text: text, messageID: manager.askMessageID)

            // Map to handle parallel tool calls: index -> (name, args)
            var toolCallsMap: [Int: (name: String, args: String)] = [:]

            do {
                for try await result in results {
                    for choice in result.choices {
                        toolCallsMap = resultHandler(choice: choice, toolCallsMap: toolCallsMap)
                    }
                }

                Haptic.impact()

                if !toolCallsMap.isEmpty {
                    chatManager.currentResult = await runChatCall(params: toolCallsMap)
                    debugPrint(chatManager.currentResult)

                    if !chatManager.currentResult.isEmpty,
                       let text = chatManager.currentResult.text()
                    {
                        let results = chatManager.chatsStream(
                            text: "FunctionCall Results:\(text)",
                            messageID: manager.askMessageID,
                            toolCall: true
                        )
                        for try await result in results {
                            for choice in result.choices {
                                resultHandler(choice: choice)
                            }
                        }
                    }
                }

                let responseMessage: ChatMessage? = {
                    var message = chatManager.currentChatMessage
                    message.chat = newGroup.id
                    return message
                }()

                if let responseMessage = responseMessage {
                    try await DatabaseManager.shared.dbQueue.write { db in
                        try responseMessage.insert(db)
                    }
                }

                clearCurrent()
            } catch is CancellationError {
                logger.debug("取消请求")
                Task { @MainActor in
                    self.clearCurrent()
                }
                return
            } catch {
                // Handle chunk error here
                logger.fault("\(error)")
                Task { @MainActor in
                    Toast.error(title: "发生错误")
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
                chatManager.currentReason += text
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
                chatManager.currentContent += outputItem
                if AppManager.shared.inAssistant && showAssistantAnimation {
                    Haptic.selection()
                }
            }
        }

        if let toolCalls = choice.delta.toolCalls {
            for toolCall in toolCalls {
                guard let index = toolCall.index else { continue }
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

    func getGroup(text: String) -> ChatGroup? {
        if let group = chatManager.chatGroup {
            return group
        } else {
            let id = manager.askMessageID ?? UUID().uuidString
            let name = String(text.trimmingSpaceAndNewLines.prefix(10))
            let group = ChatGroup(
                id: id,
                timestamp: .now,
                name: name,
                host: "",
                current: true
            )
            do {
                try DatabaseManager.shared.dbQueue.write { db in
                    try group.insert(db)
                }
                return group
            } catch {
                return nil
            }
        }
    }
}

extension NoLetChatHomeView {
    func runChatCall(params: [Int: (name: String, args: String)]) async -> [String: String] {
        var results: [String: String] = [:]
        for (_, (name, args)) in params {
            if !name.isEmpty, !args.isEmpty {
                if let json = args.jsonData() {
                    let result = await _runFunc(name: name, args: json)
                    results += result
                } else {
                    results[name] = "-1"
                }
            }
        }
        return results
    }

    private func _runFunc(name: String, args: [String: Any]) async -> [String: String] {
        guard NoLetChatAction.AllName.contains(where: {
            $0.localizedCaseInsensitiveContains(name)
        }) else { return ["error": "-1"] }
        var results: [String: String] = [:]
        for (key, value) in args {
            if let action = NoLetChatAction(rawValue: key) {
                let msg = await action.execute(with: value)
                results[action.rawValue] = msg
                
            }
        }
        return results
    }
}

#Preview {
    NoLetChatHomeView()
        .environmentObject(AppManager.shared)
}
