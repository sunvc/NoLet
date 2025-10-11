//
//  HistoryMessage.swift
//  pushback
//
//  Created by lynn on 2025/5/28.
//
import SwiftUI
import GRDB


struct HistoryMessage:View {
    @Binding var showHistory:Bool
    let group:String
    
    @State private var messages:[ChatMessage] = []
    @State private var allCount:Int = 10000
    var body: some View {
        NavigationStack{
            ScrollView{
                LazyVStack{
                    ForEach(messages, id:\.id) { message in
                        
                        ChatMessageView(message: message,isLoading: false)
                            .id(message.id)
                            .onAppear{
                                if messages.count < allCount && messages.last == message{
                                    self.loadData(item: message)
                                }
                            }
                    }
                    
                    Text("已加载全部数据")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
            }
            
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.showHistory = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text(verbatim: "\(messages.count)")
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                }
            }
            .task {
                self.loadData()
            }
           
        }
    }
    
    private func loadData(limit:Int =  50, item:ChatMessage? = nil){
        
        
        Task.detached(priority: .userInitiated) {
            
            let results = await self.query(group: group, limit: limit, item?.timestamp)
            let count = try await DatabaseManager.shared.dbQueue.read { db in
                try ChatMessage.fetchCount(db)
            }
            await MainActor.run {
                self.allCount = count
                if item == nil {
                    self.messages = results
                }else{
                    self.messages += results
                }
            }
        }
    }
    
    func query(group: String? = nil, limit lim: Int = 50, _ date: Date? = nil) async -> [ChatMessage] {
        do {
            return try await  DatabaseManager.shared.dbQueue.read { db in
                var request = ChatMessage.order(ChatMessage.Columns.timestamp.desc)
                
                if let group = group {
                    request = request.filter(ChatMessage.Columns.chat == group)
                }
                
                if let date = date {
                    request = request.filter(ChatMessage.Columns.timestamp < date)
                }
                
                return try request.limit(lim).fetchAll(db)
            }
        } catch {
            NLog.error("Query failed:", error)
            return []
        }
    }
}
