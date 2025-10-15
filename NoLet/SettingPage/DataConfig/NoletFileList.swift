import SwiftUI
import Foundation
import QuickLookThumbnailing

// MARK: - 文件项数据模型
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    var children: [FileItem]?
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = exists && isDir.boolValue
        
        // 获取文件大小
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.size = attributes[.size] as? Int64 ?? 0
            self.modificationDate = attributes[.modificationDate] as? Date ?? Date()
        } catch {
            self.size = 0
            self.modificationDate = Date()
        }
        
        // 如果是目录，懒加载子项
        if self.isDirectory {
            self.children = loadChildren()
        }
    }
    
    // 懒加载子项
    private func loadChildren() -> [FileItem]? {
        guard isDirectory else { return nil }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            return contents.map { FileItem(url: $0) }
                .sorted { item1, item2 in
                    // 文件夹排在前面，然后按名称排序
                    if item1.isDirectory != item2.isDirectory {
                        return item1.isDirectory
                    }
                    return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
                }
        } catch {
            NLog.error("加载子项失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // 格式化文件大小
    var formattedSize: String {
        if isDirectory {
            return "文件夹"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    // 文件图标
    var icon: String {
        isDirectory ? "folder.fill" : "doc.fill"
    }
}

// MARK: - 文件管理器
class FileTreeManager: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let rootURL: URL

    init(rootURL: URL ) {
        self.rootURL = rootURL
        loadRootItems()
    }
    
    // 加载根目录项
    func loadRootItems() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let items = try self.loadItems(at: self.rootURL)
                DispatchQueue.main.async {
                    self.rootItems = items
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "加载文件失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // 加载指定目录的项
    private func loadItems(at url: URL) throws -> [FileItem] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [ .skipsHiddenFiles ]
        )
        
        return contents.map { FileItem(url: $0) }
            .sorted { item1, item2 in
                // 文件夹排在前面，然后按名称排序
                if item1.isDirectory != item2.isDirectory {
                    return item1.isDirectory
                }
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
    }
    
    // 删除文件或文件夹
    func deleteItem(_ item: FileItem) {
        do {

            try FileManager.default.removeItem(at: item.url)
            // 重新加载根目录项
            Task {@MainActor in
                self.loadRootItems()
            }
        } catch {
            Task {@MainActor in
                self.errorMessage = "删除失败: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - 文件项视图
struct FileItemView: View {
    let item: FileItem
    let fileManager: FileTreeManager
    
    var body: some View {
        if item.isDirectory && !(item.children?.isEmpty ?? true) {
            // 使用 DisclosureGroup 处理文件夹
            DisclosureGroup {
                ForEach(item.children ?? []) { child in
                    FileItemView(item: child, fileManager: fileManager)
                }
            } label: {
                FileRowContent(item: item, fileManager: fileManager)
            }
        } else {
            // 普通文件或空文件夹
            FileRowContent(item: item, fileManager: fileManager)
        }
    }
}

// MARK: - 文件行内容
struct FileRowContent: View {
    let item: FileItem
    let fileManager: FileTreeManager
    @State private var showDeleteAlert = false

    @State private var imageIcon: Image? = nil

    @State private var sharedFile: URL? = nil

    var body: some View {
        HStack(spacing: 12) {
                // 文件图标

            if item.isDirectory{
                Image(systemName: item.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
            }else{
                if let imageIcon{
                    imageIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                }
            }

                // 文件信息
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack {
                    Text(item.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(DateFormatter.fileDate.string(from: item.modificationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            if let uiImage = imageIcon, let sharedFile, !item.isDirectory{
                ShareLink(
                    item: sharedFile,
                    preview:  SharePreview(
                        item.url.lastPathComponent,
                        image: uiImage
                    )
                ) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                Divider()
            }


            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        

        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                let excludedExtensions: Set<String> = ["plist", "sqlite"]

                if !excludedExtensions.contains(item.url.pathExtension) {
                    fileManager.deleteItem(item)
                }else{
                    Toast.info(title: "系统保留文件!")
                }

            }
        } message: {
            Text("确定要删除 \"\(item.name)\" 吗？此操作无法撤销。")
        }
        .task {
            self.imageIcon = await thumbnail(
                url: item.url,
                defaultIcon: item.icon
            )

            if item.url.pathExtension == "plist"{
                self.sharedFile = AppManager.createDatabaseFileTem()
            }else{
                self.sharedFile = item.url
            }
        }
    }

    func thumbnail(url: URL, size:CGFloat = 100, defaultIcon: String) async  -> Image{

        do{
            NLog.log(url.absoluteString)
            if url.path.contains("ImageCache"), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data){
                return Image(uiImage: uiImage)

            }else if url.pathExtension == "sqlite" {
                return Image("sqlite")
            }

            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: CGSize(width: size, height: size),
                scale: UIScreen.main.scale,
                representationTypes: .all
            )
            let data = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return Image(uiImage: data.uiImage)

        }catch{
            return Image("nolet")
        }



    }


    
}



// MARK: - 主文件列表视图
struct NoletFileList: View {
    @StateObject private var fileManager:FileTreeManager
    
    init(rootURL: URL ) {
        self._fileManager = StateObject(wrappedValue: FileTreeManager(rootURL: rootURL))
    }
    

    var body: some View {

        VStack(spacing: 0) {
            if fileManager.isLoading {
                    // 加载状态
                VStack {
                    Spacer()
                    ProgressView("加载文件中...")
                    Spacer()
                }
            } else if fileManager.rootItems.isEmpty {
                    // 空状态
                VStack {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("没有找到文件")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                    // 文件列表
                List {
                    ForEach(fileManager.rootItems) { item in
                        FileItemView(item: item, fileManager: fileManager)
                    }
                }
                .listStyle(.grouped)
            }
        }
        .navigationTitle("文件管理")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: .constant(""), prompt: Text("搜索"))
        .alert("错误", isPresented: .constant(fileManager.errorMessage != nil)) {
            Button("确定") {
                fileManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = fileManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
}


// MARK: - 扩展
extension DateFormatter {
    static let fileDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}


#Preview {
    NavigationStack {
        NoletFileList(rootURL: CONTAINER!)
    }
}
