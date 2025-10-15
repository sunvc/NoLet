

import SwiftUI
import Combine
import Defaults
import GRDB


struct ChatInputView<Content: View>: View  {
    @EnvironmentObject private var chatManager:openChatManager
    @EnvironmentObject private var manager:AppManager
    @Binding var text: String
    @ViewBuilder var rightBtn: () -> Content
    let onSend: (String) -> Void
    
    
    @State private var showPromptChooseView = false
    @FocusState private var isFocusedInput: Bool
    
    
    private var quote:Message?{
        guard let messageId = manager.askMessageId else { return nil }
        return  MessagesManager.shared.query(id: messageId)
    }
   
    var body: some View {
        VStack {
           
            HStack() {
                PromptLabelView(prompt: chatManager.chatPrompt)
            }.padding(5)
            
            
            
            HStack(spacing: 10) {
                inputField
                    .disabled(manager.isLoading)
                rightActionButton
                
            }
            .padding(.horizontal)
            .animation(.default, value: text)
            
            
            
        }
        .onTapGesture {
            self.isFocusedInput = !manager.isLoading
            Haptic.impact()
        }
    }
    
    // MARK: - Subviews
    private var inputField: some View {
        HStack {
            TextField("给智能助手发消息", text: $text, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .focused($isFocusedInput)
                .frame(minHeight: 50)
                .onChange(of: isFocusedInput){value in
                    
                    chatManager.isFocusedInput = value
                }
               
            PromptButtonView()
                
        }
        .background26(Color(.systemGray6), radius: 17)

        
    }
    
    @ViewBuilder
    private var rightActionButton: some View {
        
        if manager.isLoading{
            Button(action: {
                chatManager.cancellableRequest?.cancelRequest()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                    .background26(Color.white, radius: 20)
                    .tint(.red)
            }
            .transition(.scale)
        }else{
            if !text.isEmpty {
                // 发送按钮
                Button(action: {
                    
                    self.text = text.trimmingCharacters(in: .whitespaces)
                    if text.count > 1{
                        onSend(text)
                        isFocusedInput = false
                    }else {
                        Toast.error(title: "至少2个字符")
                    }
                   
                   
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .background26(Color.white, radius: 20)
                }
                .transition(.scale)
            } else {
                
                // 附件菜单
                Menu {
                    
                    rightBtn()
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .background26(Color.white, radius: 20)
                        .menuStyle(.button)
                }
                .transition(.scale)
            }
        }
        
        
    }

    @ViewBuilder
    func PromptLabelView(prompt: ChatPrompt?)-> some View{
        HStack {

            if let prompt {
                Menu{
                    Button(role: .destructive){
                        chatManager.chatPrompt = nil
                    }label: {
                        Label("清除", systemImage: "eraser")
                            .customForegroundStyle(.accent, .primary)
                    }
                }label: {
                    
                    Text(prompt.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 3, x: 0, y: 2)
                        
                }
            }
           
            
            Spacer()
            
           
            
            if let quote = quote{
                Menu{
                    Button(role: .destructive){
                        AppManager.shared.askMessageId = nil
                    }label: {
                        Label("清除", systemImage: "eraser")
                            .customForegroundStyle(.accent, .primary)
                    }
                }label: {
                    QuoteView(message: quote)
                        .onAppear{
                            Task.detached(priority: .background) {
                                try? await  DatabaseManager.shared.dbQueue.write { db in
                                    Task{@MainActor in
                                        openChatManager.shared.chatgroup = nil
                                    }
                                    
                                    // 尝试查找 quote.id 对应的 group
                                    if let group = try  ChatGroup.fetchOne(db, key: quote.id) {
                                        // 如果存在，就设为 current
                                        Task{@MainActor in
                                            openChatManager.shared.chatgroup = group
                                        }
                                        
                                        try group.update(db)
                                    } else {
                                        // 如果不存在，创建一个新的
                                        let group = ChatGroup(
                                            id: quote.id,
                                            timestamp: .now,
                                            name: quote.search.trimmingSpaceAndNewLines,
                                            host: ""
                                        )
                                        try group.insert(db)
                                        Task{@MainActor in
                                            openChatManager.shared.chatgroup = group
                                        }
                                        
                                    }
                                }
                            }
                        }
                        .onDisappear{
                            Task.detached(priority: .background) {
                                if let group = openChatManager.shared.chatgroup{
                                    let messages = try await DatabaseManager.shared.dbQueue.read { db in
                                        try  ChatMessage
                                            .filter(ChatMessage.Columns.chat == group.id)
                                            .fetchAll(db)
                                    }
                                    
                                    if messages.count == 0{
                                        _ = try await DatabaseManager.shared.dbQueue.write { db in
                                            try group.delete(db)
                                        }
                                        Task{@MainActor in
                                            openChatManager.shared.chatgroup = nil
                                        }
                                    }
                                    
                                }
                                
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
    }

}





