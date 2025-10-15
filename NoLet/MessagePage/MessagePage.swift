//
//  MessagePage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import Defaults
import SwiftUI

struct MessagePage: View {
    @EnvironmentObject private var manager: AppManager
    @Default(.showGroup) private var showGroup
    @Default(.servers) private var servers
    @StateObject private var messageManager = MessagesManager.shared
    @State private var showDeleteAction: Bool = false
    @State private var searchText:String = ""
    
    var body: some View {
        ZStack {
            
            if showGroup{
                GroupMessagesView()
                    
            }else{
                SingleMessagesView()
            }
            
            if #unavailable(iOS 26.0){
                if !manager.searchText.isEmpty{
                    SearchMessageView()
                        
                }
            }
            
            
            
        }
        .navigationTitle("消息")
        .animation(.easeInOut, value: showGroup)
        .diff { view in
            Group {
                if #available(iOS 26.0, *) {
                    view
                } else {
                    view
                        .searchable(text: $searchText)
                        .onChange(of: searchText){ value in
                            if value.isEmpty{
                                manager.searchText = ""
                            }
                        }
                        .onSubmit(of: .search){
                            manager.searchText = searchText
                        }
                }
            }
        }

        .environmentObject(messageManager)
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section {
                        Button {
                            manager.router = [.example]
                            Haptic.impact()
                        } label: {
                            Label("使用示例", systemImage: "questionmark.bubble")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(Color.accent, Color.primary)
                        }
                    }

                    Section {
                        Button {
                            self.showGroup.toggle()
                            manager.selectGroup = nil
                            manager.selectId = nil
                            Haptic.impact()
                        } label: {
                            Label(showGroup ? "列表模式" : "分组模式", systemImage: showGroup ? "rectangle.3.group.bubble.left" : "checklist")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, .primary)
                                .animation(.easeInOut, value: showGroup)
                                .symbolEffect(delay: 0)
                        }
                    }
                    Section {
                        Button {
                            manager.router = [.assistant]
                            Haptic.impact()
                        } label: {
                            if #available(iOS 18.0, *) {
                                Label("智能助手", systemImage: "apple.intelligence")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(.accent, .primary)
                            } else {
                                Label("智能助手", systemImage: "atom")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(.accent, .primary)
                            }
                        }
                    }

                    if servers.filter({ $0.voice }).count > 0 {
                        Section {
                            Button {
                                manager.router = [.pushtalk]
                                Haptic.impact()
                            } label: {
                                Label("语音对讲", systemImage: "person.line.dotted.person")
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(.accent, .primary)
                            }
                        }
                    }

                } label: {
                    Label("更多", systemImage: "fuelpump")
                }
            }
        }
        .fullScreenCover(item: $manager.selectMessage){ message in
            NavigationStack{
                SelectMessageView(message: message) {
                    withAnimation {
                        manager.selectMessage = nil
                    }
                }

            }
        }

        
    }
}

#Preview {
    ContentView()
}
