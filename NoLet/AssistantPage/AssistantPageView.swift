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

struct AssistantPageView: View {
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.showAssistantAnimation) var showAssistantAnimation

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var manager: AppManager
    @StateObject private var chatManager = openChatManager.shared

    @State private var inputText: String = ""

    @FocusState private var isInputActive: Bool

    @State private var showMenu: Bool = false
    @State private var rotateWhenExpands: Bool = false
    @State private var disablesInteractions: Bool = true
    @State private var disableCorners: Bool = true

    @State private var showChangeGroupName: Bool = false

    @State private var offsetX: CGFloat = 0
    @State private var offsetHistory: CGFloat = 0
    @State private var fengche: Bool = false

    var body: some View {
        VStack {
            if chatManager.chatMessages.count > 0 || manager.isLoading {
                ChatMessageListView()
                    .onTapGesture {
                        self.hideKeyboard()
                        Haptic.impact()
                    }

            } else {
                VStack {
                    Spacer()

                    VStack {
                        AssistantIcon()
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
                }
                .transition(.slide)
                .onTapGesture {
                    self.hideKeyboard()
                    Haptic.impact()
                }
            }

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
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
            .padding(.bottom, 10)
            .onDrag(towards: .bottom, ofAmount: 100..., perform: {
                self.hideKeyboard()
            })
        }
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
            principalToolbarTitleContent
            principalToolbarToolContent
        }
        .sheet(isPresented: $showMenu) {
            OpenChatHistoryView(show: $showMenu)
                .onChange(of: showMenu) { _ in
                    Task { @MainActor in
                        self.hideKeyboard()
                    }
                }
                .customPresentationCornerRadius(20)
        }
        .onAppear {
            manager.inAssistant = true
        }
        .environmentObject(chatManager)
        .onDisappear {
            manager.askMessageID = nil
            manager.inAssistant = false
        }
    }

    private var principalToolbarTitleContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            StreamingLoadingView(showLoading: manager.isLoading, group: chatManager.chatGroup)
                .transition(.scale)
        }
    }

    private var principalToolbarToolContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section {
                    Button(action: {
                        chatManager.cancellableRequest?.cancel()
                        chatManager.setGroup()
                        Haptic.impact()
                    }) {
                        Label(String(localized: "新对话"), systemImage: "plus.message")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, .primary)
                    }
                }

                Section {
                    Button {
                        self.showMenu = true
                        Haptic.impact()

                    } label: {
                        Label("所有对话", systemImage: "clock.arrow.circlepath")
                    }
                }

                Section {
                    Button(action: {
                        manager.router.append(.assistantSetting(nil))
                        Haptic.impact()
                    }) {
                        Label(String(localized: "设置"), systemImage: "gear.circle")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, .primary)
                    }
                }

                Section {
                    Button {
                        if let id = chatManager.chatGroup?.id {
                            Task.detached(priority: .background) {
                                await chatManager.delete(groupID: id)
                            }
                        }

                    } label: {
                        Label("删除对话", systemImage: "trash")
                    }.tint(.red)
                }

            } label: {
                Label("更多", systemImage: "ellipsis")
            }
        }
    }

    // 发送消息
    private func sendMessage(_ text: String) async {
        hideKeyboard()

        guard assistantAccouns.first(where: { $0.current }) != nil else {
            manager.router.append(.assistantSetting(nil))
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

            let newGroup: ChatGroup? = {
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
            }()

            guard let newGroup = newGroup else { return }

            let results = chatManager.chatsStream(
                text: text,
                messageID: manager.askMessageID,
                systemInstruction: chatManager.useFunctionCall ? AppSettingAction
                    .systemInstruction : nil,
                functions: chatManager.useFunctionCall ? AppSettingAction.getFuncs() : []
            )

            // Map to handle parallel tool calls: index -> (name, args)
            var toolCallsMap: [Int: (name: String, args: String)] = [:]

            do {
                for try await result in results {
                    for choice in result.choices {
                        if let outputItem = choice.delta.content {
                            Task { @MainActor in
                                chatManager.currentContent = chatManager.currentContent + outputItem
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
                                    NLog.log("Tool call name received for index \(index): \(name)")
                                }
                                if let args = toolCall.function?.arguments {
                                    current.args += args
                                }
                                toolCallsMap[index] = current
                            }
                        }
                        
                    }
                }

                for (index, (name, args)) in toolCallsMap {
                    if !name.isEmpty, !args.isEmpty {
                        NLog
                            .log(
                                "Attempting to run function [\(index)]: \(name) with args: \(args)"
                            )
                        if let data = args.data(using: .utf8),
                           let json = try? JSONSerialization
                           .jsonObject(with: data, options: []) as? [String: Any]
                        {
                            runFunc(name: name, args: json)
                        } else {
                            NLog
                                .error(
                                    "Failed to parse tool arguments JSON for [\(index)]: \(args)"
                                )
                            Task { @MainActor in
                                Toast.error(title: "Function call failed: Invalid JSON")
                            }
                        }
                    }
                }

                Haptic.impact()

                let responseMessage: ChatMessage? = {
                    if chatManager.currentChatMessage.content.isEmpty {
                        return nil
                    }
                    var message = chatManager.currentChatMessage
                    message.chat = newGroup.id
                    return message
                }()

                if let responseMessage = responseMessage {
                    try await DatabaseManager.shared.dbQueue.write { db in
                        try responseMessage.insert(db)
                    }
                }

                chatManager.currentRequest = ""
                AppManager.shared.isLoading = false
                

            } catch {
                // Handle chunk error here
                NLog.error(error)
                Task { @MainActor in
                    Toast.error(title: "发生错误\(error.localizedDescription)")
                    manager.isLoading = false
                    chatManager.currentRequest = ""
                    chatManager.currentContent = ""
                }
                return
            }
            
            
            
        }
    }
}

extension AssistantPageView {
    func runFunc(name: String, args: [String: Any]) {
        guard name == "manage_app" || name == "update_settings" else { return }

        Task { @MainActor in
            for (key, value) in args {
                if let action = AppSettingAction(rawValue: key) {
                    let success = action.execute(with: value)
                    Toast.success(title: success ? "操作成功" : "操作失败")
                }
            }
        }
    }
}

struct CustomAlertWithTextField: View {
    @State private var text: String = ""
    @Binding var show: Bool
    var confirm: (String) -> Void
    /// View Properties
    ///
    init(_ show: Binding<Bool>, text: String, confirm: @escaping (String) -> Void) {
        self.text = text
        _show = show
        self.confirm = confirm
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 65, height: 65)
                .background {
                    Circle()
                        .fill(.blue.gradient)
                        .background {
                            Circle()
                                .fill(.background)
                                .padding(-5)
                        }
                }

            Text("修改分组名称")
                .fontWeight(.semibold)

            Text("此名称用来查找历史分组使用")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.top, 5)

            TextField("输入分组名称", text: $text, axis: .vertical)
                .frame(maxHeight: 150)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.bar)
                }
                .padding(.vertical, 10)

            HStack(spacing: 10) {
                Button {
                    show = false
                } label: {
                    Text("取消")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red.gradient)
                        }
                }

                Button {
                    show = false
                    confirm(text)
                } label: {
                    Text("确认")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.gradient)
                        }
                }
            }
        }
        .frame(width: windowWidth * 0.8)
        .padding([.horizontal, .bottom], 20)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.background)
                .padding(.top, 25)
        }
    }
}

struct StreamingLoadingView: View {
    var showLoading: Bool
    var group: ChatGroup? = nil
    @EnvironmentObject private var chatManager: openChatManager

    // 使用 TimelineView 自动驱动动画，无需手动管理 Timer
    var body: some View {
        if showLoading {
            Button {
                chatManager.cancellableRequest?.cancel()
            } label: {
                HStack(spacing: 8) {
                    // 图标动画：增加一个呼吸效果
                    Image(systemName: "brain")
                        .foregroundColor(.orange)
                        .symbolEffect(.pulse) // iOS 17+ 呼吸感

                    TimelineView(.periodic(from: .now, by: 0.5)) { context in
                        let dotCount = Int(context.date.timeIntervalSinceReferenceDate * 2) % 4
                        let dots = String(repeating: ".", count: dotCount)

                        HStack(alignment: .bottom, spacing: 0) {
                            Text(chatManager.currentContent.isEmpty ? "思考中" : "回答中")
                            // 固定点号的容器，防止文字左右抖动
                            Text(dots)
                                .frame(width: 15, alignment: .leading)
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    }

                    Image(systemName: "xmark.circle.fill")
                        .padding(5)
                        .foregroundStyle(.red)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: 180)
            }

        } else {
            Button {} label: {
                HStack {
                    Text(group?.name.trimmingSpaceAndNewLines ?? "新建对话")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.trailing, 3)
                        .font(.footnote)

                    Image(systemName: "chevron.down")
                        .imageScale(.large)
                        .foregroundStyle(.gray.opacity(0.5))
                        .imageScale(.small)
                }
                .frame(maxWidth: 180)
            }
        }
    }
}

#Preview {
    AssistantPageView()
        .environmentObject(AppManager.shared)
}
