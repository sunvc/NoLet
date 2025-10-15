

import SwiftUI

struct PromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let prompt: ChatPrompt?
    
    @State private var title: String
    @State private var content: String
    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    
    init(prompt: ChatPrompt?) {
        self.prompt = prompt
        _title = State(initialValue: prompt?.title ?? "")
        _content = State(initialValue: prompt?.content ?? "")
        _isEditing = State(initialValue: prompt == nil)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    titleSection
                    contentSection
                    promptInfoSection
                    actionButtonsSection
                }
                .padding(.vertical)
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                trailingToolbarItem
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - View Components
    private var titleSection: some View {
        SectionView(title: String(localized: "标题")) {
            if isEditing {
                TextField("请输入提示词标题", text: $title)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(title).font(.body)
            }
        }
    }

    
    private var contentSection: some View {
        SectionView(title: String(localized: "内容")) {
            if isEditing {
                TextEditor(text: $content)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .systemGray6))
                    )
            } else {
                Text(content).font(.body)
            }
        }
    }
    
    private var promptInfoSection: some View {
        Group {
            if let prompt = prompt {
                VStack(spacing: 12) {
                    if prompt.inside {
                        InfoBanner(
                            icon: "info.circle",
                            title: String(localized: "内置提示词"),
                            message:  String(localized: "这是一个内置提示词，你可以基于它创建一个新的自定义提示词")
                        )
                    } else {
                        InfoBanner(
                            icon: "calendar",
                            title: String(localized:"创建时间"),
                            message: prompt.timestamp.formatted(
                                .dateTime
                                    .year().month().day()
                                    .hour().minute()
                            )
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        Group {
            if !isEditing {
                VStack(spacing: 12) {
                    Button {
                        handleUsePrompt()
                    } label: {
                        Text("使用此提示词创建新提示词")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if prompt?.inside == false {
                if isEditing {
                    Button("保存") {
                        handleSavePrompt()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                } else {
                    Button("编辑") {
                        isEditing = true
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func getNavigationTitle() -> String {
        if prompt == nil {
            return String(localized: "新建提示词")
        } else if isEditing {
            return String(localized: "编辑提示词")
        } else {
            return String(localized: "提示词详情")
        }
    }
    
    private func handleUsePrompt() {
        guard prompt != nil else { return }
            
            let chatPrompt = ChatPrompt(
                title: title,
                content: content,
                inside: false
            )
        Task.detached(priority: .userInitiated) {
            
            do {
                try await  DatabaseManager.shared.dbQueue.write { db in
                    try chatPrompt.insert(db)
                }
                await MainActor.run {
                    self.dismiss()
                }
            } catch {
                NLog.error("❌ 插入 ChatPrompt 失败:", error)
            }
        }
       
    }
    
    private func handleSavePrompt() {
        let title = self.title
        let content = self.content
        Task.detached(priority: .userInitiated) {
            do {
                try await  DatabaseManager.shared.dbQueue.write { db in
                    if var item = try ChatPrompt.fetchOne(db, key: prompt?.id){
                        item.title = title
                        item.content = content
                        try item.update(db)
                    }
                }
            } catch {
                NLog.error("❌ 更新 ChatPrompt 失败:", error)
            }
            await MainActor.run {
                if prompt == nil {
                    self.dismiss()
                } else {
                    self.isEditing = false
                }
            }
        }
    }
}

// MARK: - SectionView
private struct SectionView<Content: View>: View {
    let title: String
    let center:Bool
    let content: Content
    
    
    init(_ center:Bool = true, title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.center = center
        self.content = content()
      
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            content
        }
        .padding(.horizontal)
        .if(!center){ view in
            HStack{
               view
                Spacer()
            }
        }
        
        
    }
}

// MARK: - InfoBanner
private struct InfoBanner: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(10)
    }
}


#Preview("提示词详情") {
    PromptDetailView(
        prompt: ChatPrompt(id: "", timestamp: .now, title: "", content: "", inside: false)
    )
}
