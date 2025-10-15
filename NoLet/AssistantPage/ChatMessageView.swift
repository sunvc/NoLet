

import SwiftUI
import Defaults

struct ChatMessageView: View {
    @EnvironmentObject private var chatManager:openChatManager
    let message: ChatMessage
    let isLoading:Bool
    
    
    private var quote:Message?{
        guard let messageId = AppManager.shared.askMessageId  else { return nil }
        return  MessagesManager.shared.query(id: messageId)
    }
    
    
    
    var body: some View {
        
        VStack{
            
            timestampView
            
            
            if message.request.count > 0 || quote != nil {
                VStack{
                    if let quote = quote{
                        HStack{
                            Spacer()
                            QuoteView(message: quote)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                    }
                    if message.request.count > 0{
                        HStack {
                            Spacer()
                            
                            userMessageView
                                .if(isLoading) {  $0.lineLimit(2) }
                                .assistantMenu(message.request)
                                
                            
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            
            
            if  !message.content.isEmpty {
                HStack{
                    assistantMessageView
                        .assistantMenu(message.content)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            
        }
        .padding(.vertical, 4)
    }
    
    
    
    // MARK: - View Components
    
    
    /// 时间戳视图
    private var timestampView: some View {
        HStack {
            Spacer()
            Text("\(message.timestamp.formatString())" + "\n")
                .font(.caption2)
                .foregroundStyle(.gray)
                .padding(.horizontal)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
    
    /// 用户消息视图
    private var userMessageView: some View {
        MarkdownCustomView(content: message.request)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .overlay {
                Color.blue.opacity(0.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        
    }
    
    /// AI助手消息视图
    private var assistantMessageView: some View {
        MarkdownCustomView(content: message.content)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        
    }
    
}


extension View{
    
    func assistantMenu(_ text:String)-> some View{
        self
            .onTapGesture(count: 2){
                Clipboard.set(text)
                Toast.success(title: "复制成功")
            }
            .contextMenu{
                
                Section {
                    Button {
                        Task(priority: .high) {
                            guard let player = await AudioManager.shared.speak(PBMarkdown.plain(text)) else { return }
                            player.play()
                        }
                    }label: {
                        Label("朗读内容",  systemImage: "waveform")
                            .symbolEffect(.variableColor)
                            .customForegroundStyle(.accent, .primary)
                    }
                }
                
                Section{
                    Button(action: {
                        Clipboard.set(text)
                        Toast.success(title: "复制成功")
                    }) {
                        Label("复制", systemImage: "doc.on.doc")
                            .customForegroundStyle(.accent, .primary)
                    }
                }
                
            }
    }
}

struct QuoteView:View {
    var message:Message
    
    var body: some View {
        HStack(spacing: 5) {
            
            Text(verbatim: "\(message.search.trimmingSpaceAndNewLines)")
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.caption2)
            
            
            Image(systemName: "quote.bubble")
                .foregroundColor(.gray)
                .padding(.leading, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ChatMessageView(message: ChatMessage(id: "", timestamp: .now, chat: "", request: "", content: "", message: ""), isLoading: false)
}



