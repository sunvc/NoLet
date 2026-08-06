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

    @State private var showDeleteView: Bool = false
    @State private var deleteDate: Date = Date().zeroDate()

    var body: some View {
        ZStack {
            ChatMessageArrayView()
            if chatManager.chatMessages.isEmpty {
                spaceHome.allowsHitTesting(true)
            }
        }
        .background(ContentBackgroundView())
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
        .sheet(isPresented: $chatManager.showPromptChooseView) {
            PromptChooseView(show: $chatManager.showPromptChooseView)
                .customPresentationCornerRadius(30)
                .customDetents([.medium, .large])
        }
        .sheet(item: $chatManager.showReason) { _ in
            ReasonMessageView(message: $chatManager.showReason)
                .customPresentationCornerRadius(30)
                .customDetents([.medium, .large])
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
        .contentShape(Rectangle())
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

        guard !text.isEmpty else { return }

        let userMessageID = UUID().uuidString
        let assistantMessageID = UUID().uuidString

        Task { @MainActor in
            chatManager.currentMessageID = assistantMessageID
            withAnimation {
                manager.isLoading = true
            }
            self.inputText = ""
            chatManager.currentContent = ""
        }

        chatManager.appendUserMessage(
            id: userMessageID,
            content: text,
            quoteMessageID: manager.askMessageID
        )

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

            // 用最终的 assistantMessageID 固化这条助手消息
            Task { @MainActor in
                chatManager.currentMessageID = assistantMessageID
                chatManager.updateTemMessage()
                clearCurrent()
            }
        } catch is CancellationError {
            logger.debug("取消请求")
            Task { @MainActor in
                clearCurrent()
            }
        } catch {
            logger.error("\(error.localizedDescription)")
            Task { @MainActor in
                Toast.shared.present(title: error.localizedDescription, symbol: .error)
                clearCurrent()
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

    func runChatCall(params: [Int: (name: String, args: String)]) async -> [String: String] {
        var results: [String: String] = [:]
        for (_, (name, args)) in params {
            if !name.isEmpty, !args.isEmpty {
                if let json = args.jsonData() {
                    let result = await NoLetChatAction.runFunc(
                        name: name,
                        args: json
                    )

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
