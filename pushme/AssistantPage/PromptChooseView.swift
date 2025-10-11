

import SwiftUI
import Foundation
import GRDB

// MARK: - Views
/// 提示词选择视图
struct PromptChooseView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var chatManager:openChatManager
    
    @State private var prompts:[ChatPrompt] = []
    
    @State private var isAddingPrompt = false
    @State private var searchText = ""
    @State private var selectedPrompt: ChatPrompt? = nil


    private var filteredBuiltInPrompts: [ChatPrompt] {  prompts.filter({$0.inside}) }

    private var filteredCustomPrompts: [ChatPrompt] {
        guard !searchText.isEmpty else { return prompts.filter({!$0.inside}) }
        return prompts.filter({!$0.inside}).filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hasSearchResults: Bool {
        !searchText.isEmpty && filteredBuiltInPrompts.isEmpty && filteredCustomPrompts.isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            promptListView
                .navigationTitle("选择提示词")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer,
                    prompt: "搜索提示词"
                )
                .toolbar {
                    toolbarContent
                    addPromptButton
                }
                .task {
                    loadData()
                }
                .onChange(of: chatManager.promptCount) { _ in
                    loadData()
                }
                
        }
    }
    private func loadData(){
        Task.detached(priority: .background) {
            do{
                let results =  try await  DatabaseManager.shared.dbQueue.read{db in
                    try ChatPrompt.fetchAll(db)
                }
                await MainActor.run{
                    self.prompts = results
                }
            }catch{
                NLog.error(error.localizedDescription)
            }
        }
    }

    // MARK: - View Components
    private var promptListView: some View {
        List {
            if hasSearchResults {
                if #available(iOS 17.0, *){
                    ContentUnavailableView("没有找到相关提示词", systemImage: "magnifyingglass")
                }else{
                    VStack{
                        HStack{
                            Spacer()
                            Image("magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .padding()
                            Spacer()
                        }
                        Spacer()
                        HStack{
                            Spacer()
                            Text("没有找到相关提示词")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding()
                            Spacer()
                        }
                    }.frame(height: 300)
                }

            } else {
                promptSections
                    .environmentObject(chatManager)
            }
        }
        .sheet(isPresented: $isAddingPrompt) {
            AddPromptView()
                .customPresentationCornerRadius(20)
        }
    }

    private var promptSections: some View {
        Group {
            if !filteredBuiltInPrompts.isEmpty {
                PromptSection(
                    selectId: chatManager.chatPrompt?.id,
                    title: String(localized: "内置提示词"),
                    prompts: filteredBuiltInPrompts,
                    onPromptTap: handlePromptTap
                )
            }

            if !filteredCustomPrompts.isEmpty {
                PromptSection(
                    selectId: chatManager.chatPrompt?.id,
                    title: String(localized: "自定义提示词"),
                    prompts: filteredCustomPrompts,
                    onPromptTap: handlePromptTap
                )
            }
        }
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消", role: .cancel) {
                    dismiss()
                }
            }
        }
    }
    
    private var addPromptButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isAddingPrompt = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    

    // MARK: - Methods
    private func handlePromptTap(_ prompt: ChatPrompt) {
        if chatManager.chatPrompt == prompt{
            chatManager.chatPrompt = nil
        }else{
            chatManager.chatPrompt = prompt
            dismiss()
        }
        
        
    }
    
    
}

// MARK: - PromptSection
private struct PromptSection: View {
    let selectId:String?
    let title: String
    let prompts: [ChatPrompt]
    let onPromptTap: (ChatPrompt) -> Void
    
    @State private var showDeleteAlert = false
    @State private var promptToDelete: ChatPrompt?
    

    var body: some View {
        Section(title) {
            ForEach(prompts) { prompt in
                PromptRowView(prompt: prompt,selectId: selectId)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPromptTap(prompt)
                       
                    }
                    .modifier(PromptSwipeActions(
                        prompt: prompt,
                        showDeleteAlert: $showDeleteAlert,
                        promptToDelete: $promptToDelete
                    ))
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert, presenting: promptToDelete) { prompt in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let prompt = promptToDelete{
                    Task.detached(priority: .userInitiated) {
                        do {
                            _ = try await  DatabaseManager.shared.dbQueue.write { db in
                                try ChatPrompt
                                    .filter(Column("id") == prompt.id)
                                    .deleteAll(db)
                            }
                        } catch {
                            NLog.error("❌ 删除 ChatPrompt 失败: \(error)")
                        }
                    }
                }
               
            }
        } message: { prompt in
            Text("确定要删除\"\(prompt.title)\"提示词吗？此操作无法撤销。")
        }
    }
}

// MARK: - PromptRowView
private struct PromptRowView: View {
    let prompt: ChatPrompt
    var selectId:String?
    var body: some View {
        HStack(spacing: 12) {
            // 选中状态指示器
            Circle()
                .fill( prompt.id == selectId ? Color.blue : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .strokeBorder(
                            prompt.id == selectId ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )

            // 提示词内容
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if prompt.inside {
                        Text("内置")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }

                Text(prompt.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

// MARK: - PromptSwipeActions
private struct PromptSwipeActions: ViewModifier {
    let prompt:  ChatPrompt
    @Binding var showDeleteAlert: Bool
    @Binding var promptToDelete:  ChatPrompt?


    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
               
                // 编辑按钮
                NavigationLink {
                    PromptDetailView(prompt: prompt)
                } label: {
                    Label("查看", systemImage: "eye")
                }
                .tint(.blue)
            }
            .if(!prompt.inside) {
                $0.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            promptToDelete = prompt
                            showDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        
        
    }
}

// MARK: - PromptButtonView
struct PromptButtonView: View {
    // MARK: - Properties
    @State private var showPromptChooseView = false
    @State private var selectedPromptIndex: Int?
    
    
    // MARK: - Body
    var body: some View {
        Button {
            showPromptChooseView = true
        } label: {
            Image(systemName: "puzzlepiece.extension")
                .tint(.gray)
                .font(.title2)
                .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        }
        .sheet(isPresented: $showPromptChooseView) {
            PromptChooseView()
                .customPresentationCornerRadius(20)
        }
    }
}


// MARK: - 添加Prompt视图
struct AddPromptView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var address = ""

    
    // MARK: - View
    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("网络地址", text: $address)
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            .navigationTitle("添加 Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        
                        let chatprompt = ChatPrompt(
                            id: UUID().uuidString,
                            timestamp: Date(),
                            title: title,
                            content: content,
                            inside: false
                        )
                        Task.detached(priority: .userInitiated) {
                            do {
                                try await  DatabaseManager.shared.dbQueue.write { db in
                                    try chatprompt.insert(db)
                                }
                                await MainActor.run {
                                    self.dismiss()
                                }
                               
                            } catch {
                                NLog.error("❌ 插入 ChatPrompt 失败: \(error)")
                            }
                            
                        }
                    }
                    .disabled(!(!title.isEmpty && !content.isEmpty))
                }
            }
        }
    }
    
}



// MARK: - Preview
#Preview("提示词选择") {
    PromptChooseView()
}
