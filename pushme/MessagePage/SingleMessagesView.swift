//
//  SingleMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import GRDB
import Defaults



struct SingleMessagesView: View {


    @Default(.showMessageAvatar) var showMessageAvatar
    
    @State private var isLoading: Bool = false
    
 
    @State private var showAllTTL:Bool = false
    
    @EnvironmentObject private var manager:AppManager
    @EnvironmentObject private var messageManager: MessagesManager
   

    @State private var showLoading:Bool = false
    @State private var scrollItem:String = ""

    @State private var selectMessage: Message? = nil
    @State private var messages:[Message] = []
    
    private let messagePage:Int = 100

    var body: some View {
        
        ScrollViewReader { proxy in
            List{
                
                ForEach(messages, id: \.id) { message in
                    
                    MessageCard(message: message, searchText: "",showAllTTL: showAllTTL,showAvatar:showMessageAvatar){
                        withAnimation(.easeInOut) {
                            manager.selectMessage = message
                        }
                    }delete:{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                            withAnimation(.default){
                                messages.removeAll(where: {$0.id == message.id})
                            }
                        }
                        
                        Task.detached(priority: .background){
                            _ = await messageManager.delete(message)
                        }
                        Toast.success(title: "删除成功")
                    }
                    .id(message.id)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                    .onAppear{
                        if messages.count < messageManager.allCount &&
                            messages.last == message{
                            self.loadData(proxy: proxy, item: message)
                        }
                    }
                    
                    
                }
                
                if messages.count == 0 && showLoading{
                    HStack{
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                .scaleEffect(2)
                                .padding(.vertical, 30)
                                .padding()
                            
                            Text("数据加载中...")
                                .foregroundColor(.primary)
                                .font(.body)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(24)
                    .shadow(radius: 10)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
                }
                
            }
            .listStyle(.grouped)
            .animation(.easeInOut, value: messages)
            .refreshable {
                self.loadData(proxy: proxy , limit: min(messages.count, messagePage * 2))
            }
            .onChange(of: messageManager.updateSign) {  newValue in
                loadData(proxy: proxy, limit: max(messages.count, messagePage))
            }
        }
        .diff{ view in
            Group{
                if #available(iOS 26.0, *){
                    view
                        .toolbar {
                            if !(messages.count == 0 || messages.count == messageManager.allCount){
                                ToolbarItem(placement: .subtitle) {
                                    allMessageCount
                                }
                            }
                        }
                }else{
                    view
                        .safeAreaInset(edge: .bottom){
                            HStack{
                                Spacer()
                                allMessageCount
                                    .padding(.horizontal, 10)
                                    .background26(.ultraThinMaterial, radius: 5)
                            }.opacity((messages.count == 0 || messages.count == messageManager.allCount) ? 0 : 1)
                        }
                }
            }
        }
        .task {
            self.loadData()
            Task.detached(priority: .background) {
                
                guard let count = await messageManager.updateRead() else{ return }
                
                // 清除徽章
                if Defaults[.badgeMode] == .auto {
                    try await UNUserNotificationCenter.current().setBadgeCount(0)
                }
                
                NLog.log("更新未读条数: \(count)")
            }
            
        }


    }

    private var allMessageCount: some View{
        Text(verbatim: "\(messages.count) / \(max(messageManager.allCount, messages.count))")
            .font(.caption)
            .foregroundStyle(.gray)
    }

    private func proxyTo(proxy: ScrollViewProxy, selectId:String?){
        if let selectId = selectId{
            withAnimation {
                proxy.scrollTo(selectId, anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                manager.selectId = nil
                manager.selectGroup = nil
            }
        }
    }
    
    private func loadData(proxy:ScrollViewProxy? = nil,
                          limit:Int = 100,
                          item:Message? = nil){
        guard !self.showLoading else { return }
        self.showLoading = true

       Task.detached(priority: .userInitiated) {

           let results = await MessagesManager.shared.query( limit: limit, item?.createDate)
            
           await MainActor.run {
 
                if item == nil {
                    self.messages = results
                }else{
                    self.messages += results
                }
                if let selectId = manager.selectId{
                    proxy?.scrollTo(selectId, anchor: .center)
                    manager.selectId = nil
                    manager.selectGroup = nil
                }
                self.showLoading = false
            }
        }
    }
    
}

#Preview {
    SingleMessagesView()
}
