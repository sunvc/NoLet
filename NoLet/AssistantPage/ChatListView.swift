

import SwiftUI
import Defaults
import Combine
import GRDB


struct ChatMessageListView: View {
    
    @EnvironmentObject private var chatManager:openChatManager
    @EnvironmentObject private var manager:AppManager
    
    @State private var showHistory:Bool = false
    
    @State private var messageCount:Int = 10
    
    let chatLastMessageId = "currentChatMessageId"
    
    let throttler = Throttler(delay: 0.1)
    
    @State private var offsetY: CGFloat = 0
    
    var suffixCount:Int{
        min(chatManager.chatMessages.count, 10)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            
            ScrollView {
                
                if chatManager.chatMessages.count > suffixCount{
                    Button{
                        self.showHistory.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text(verbatim: "\(suffixCount)/\(chatManager.chatMessages.count)")
                                .padding(.trailing, 10)
                            Text("点击查看更多")
                           
                            Spacer()
                        }
                        .padding(.vertical)
                        .contentShape(Rectangle())
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    }
                }
                
            
                
                ForEach(chatManager.chatMessages,id: \.id) { message in
                    ChatMessageView(message: message,isLoading: manager.isLoading)
                        .id(message.id)
                }
                
                VStack{
                    if manager.isLoading{
                        
                        ChatMessageView(message: chatManager.currentChatMessage,isLoading: manager.isLoading)
                    }
                    
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.clear)
                        .opacity(0.001)
                        .frame(height: 50)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: OffsetKey.self, value: proxy.frame(in: .global).maxY)
                            }
                        )
                        .onPreferenceChange(OffsetKey.self) { newValue in
                            offsetY = newValue
                        }
                        .id(chatLastMessageId)
                }
                
            }
            .onChange(of: chatManager.isFocusedInput) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    withAnimation(.snappy(duration: 0.3)){
                        scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                    }
                    
                }
            }
            .onChange(of: chatManager.currentContent){ value in
                throttler.throttle {
                    if offsetY < 800{
                        withAnimation(.snappy(duration: 0.1)){
                            scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                        }
                    }
                   
                }
            }
            .onChange(of: chatManager.chatMessages) { value in
                if offsetY < 800{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                        scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                if let chatgroup = chatManager.chatgroup{
                    HistoryMessage(showHistory: $showHistory, group: chatgroup.id)
                        .customPresentationCornerRadius(20)
                }else{
                    Spacer()
                        .onAppear{
                            self.showHistory.toggle()
                        }
                }
                
            }
            .task {
                chatManager.loadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                }
            }
           
        }
    }
}




class Throttler {
    private var lastExecution: Date = .distantPast
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private var pendingWorkItem: DispatchWorkItem?
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func throttle(_ action: @escaping () -> Void) {
        let now = Date()
        let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
        
        if timeSinceLastExecution >= delay {
            // 超过 1 秒，立即执行
            lastExecution = now
            action()
        } else {
            // 取消之前的任务，确保 1 秒内只执行最后一次
            pendingWorkItem?.cancel()
            
            let workItem = DispatchWorkItem {
                self.lastExecution = Date()
                action()
            }
            
            pendingWorkItem = workItem
            queue.asyncAfter(deadline: .now() + delay - timeSinceLastExecution, execute: workItem)
        }
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
