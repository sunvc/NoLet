//
//  NoletFileList.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/13.
//

import Foundation
import ImageIO
import QuickLook
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - 文件项数据模型

struct FileItem: Identifiable, Hashable {
    
    var id: String { url.path }
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date

    var children: [FileItem]?

    init(url: URL) {
        self.url = url
        name = url.lastPathComponent

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        isDirectory = exists && isDir.boolValue

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            size = attributes[.size] as? Int64 ?? 0
            modificationDate = attributes[.modificationDate] as? Date ?? Date()
        } catch {
            size = 0
            modificationDate = Date()
        }
    }

    var formattedSize: String {
        if isDirectory {
            return String(localized: "文件夹")
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var icon: String {
        isDirectory ? "folder.fill" : "doc.fill"
    }

    var isPreferencesProtected: Bool {
        guard let libraryURL = NCONFIG.Path(.preferences) else {
            return false
        }

        let folderPath = libraryURL.standardizedFileURL.path
        let urlPath = url.standardizedFileURL.path

        return urlPath == folderPath || urlPath.hasPrefix(folderPath + "/")
    }

    /// Library 文件夹受保护，不允许清空（内含 Preferences 等应用数据）。
    var isLibraryProtected: Bool {
        guard let libraryURL = NCONFIG.Path(.library) else {
            return false
        }
        return url.standardizedFileURL.path == libraryURL.standardizedFileURL.path
    }

    var isPreviewForbidden: Bool {
        url.pathExtension.lowercased() == "plist"
    }

    var isImageFile: Bool {
        if let utType = UTType(filenameExtension: url.pathExtension),
           utType.conforms(to: .image)
        {
            return true
        }
        return imageContentType != nil
    }

    var imageContentType: UTType? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let typeID = CGImageSourceGetType(source) as String?,
              let type = UTType(typeID)
        else { return nil }
        return type.conforms(to: .image) ? type : nil
    }

    var previewURL: URL {
        if !url.pathExtension.isEmpty { return url }
        guard let type = imageContentType,
              let ext = type.preferredFilenameExtension
              ?? type.tags[.filenameExtension]?.first
        else { return url }

        let linkDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoLetPreviews", isDirectory: true)
        try? FileManager.default.createDirectory(at: linkDir, withIntermediateDirectories: true)
        let copy = linkDir.appendingPathComponent("\(url.lastPathComponent).\(ext)")
        if FileManager.default.fileExists(atPath: copy.path) {
            try? FileManager.default.removeItem(at: copy)
        }
        do {
            try FileManager.default.copyItem(at: url, to: copy)
        } catch {
            return url
        }
        return copy
    }
}

// MARK: - 文件管理器

@MainActor
class FileTreeManager: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var expandedPaths: Set<String> = []

    private let rootURL: URL

    init(rootURL: URL) {
        self.rootURL = rootURL
        loadRootItems()
    }

    // 加载根目录项
    func loadRootItems() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                self.rootItems = try self.loadItems(at: self.rootURL)
                for path in self.expandedPaths {
                    self.loadChildren(for: URL(fileURLWithPath: path))
                }
                self.isLoading = false
            } catch {
                self.errorMessage = String(localized: "加载文件失败")
                self.isLoading = false
            }
        }
    }

    // 加载指定目录的项 (非递归)
    private func loadItems(at url: URL) throws -> [FileItem] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey,
            ],
            options: [.skipsHiddenFiles]
        )

        return contents.map { FileItem(url: $0) }
            .sorted { item1, item2 in
                if item1.isDirectory != item2.isDirectory {
                    return item1.isDirectory
                }
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
    }

    func loadChildren(for url: URL) {
        let loaded = (try? loadItems(at: url)) ?? []
        assignChildren(loaded, to: url, in: &rootItems)
    }

    private func assignChildren(_ children: [FileItem], to url: URL, in items: inout [FileItem]) {
        for index in items.indices where items[index].url == url {
            items[index].children = children
            return
        }
        for index in items.indices where items[index].children != nil {
            var nested = items[index].children!
            assignChildren(children, to: url, in: &nested)
            items[index].children = nested
        }
    }

    func setExpanded(_ expanded: Bool, for item: FileItem) {
        if expanded {
            expandedPaths.insert(item.url.path)
            if item.children == nil {
                let url = item.url
                Task { @MainActor in self.loadChildren(for: url) }
            }
        } else {
            expandedPaths.remove(item.url.path)
        }
    }

    // 删除文件或文件夹
    func deleteItem(_ item: FileItem) {
        guard !item.isPreferencesProtected, !item.isLibraryProtected else {
            errorMessage = String(localized: "没有权限")
            return
        }
        do {
            try FileManager.default.removeItem(at: item.url)
            expandedPaths.remove(item.url.path)
            loadRootItems()
        } catch {
            errorMessage = String(localized: "删除失败")
        }
    }

    // 清空文件夹内容（保留文件夹本身），Library 文件夹除外
    func clearFolder(_ item: FileItem) {
        guard item.isDirectory, !item.isLibraryProtected else {
            errorMessage = String(localized: "没有权限")
            return
        }
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: item.url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            for url in contents {
                let child = FileItem(url: url)
                if child.isPreferencesProtected { continue }
                try? FileManager.default.removeItem(at: url)
            }
            loadRootItems()
        } catch {
            errorMessage = String(localized: "清空失败")
        }
    }
}

// MARK: - 文件项视图

struct FileItemView: View {
    let item: FileItem
    let fileManager: FileTreeManager

    @State private var isExpanded = false

    var body: some View {
        if item.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                switch item.children {
                case .none:
                    ProgressView()
                        .padding(.leading, 8)
                case .some(let children) where children.isEmpty:
                    Text("空文件夹")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                case .some(let children):
                    ForEach(children) { child in
                        FileItemView(item: child, fileManager: fileManager)
                    }
                }
            } label: {
                FileRowContent(item: item, fileManager: fileManager)
            }
            .onAppear {
                isExpanded = fileManager.expandedPaths.contains(item.url.path)
            }
            .onChange(of: isExpanded) { newValue in
                fileManager.setExpanded(newValue, for: item)
            }
        } else {
            FileRowContent(item: item, fileManager: fileManager)
        }
    }
}

// MARK: - 文件行内容

private struct FilePreviewTapModifier: ViewModifier {
    @Binding var previewItem: FileRowContent.PreviewItem?
    let item: FileItem

    func body(content: Content) -> some View {
        if item.isDirectory {
            content
        } else {
            content.onTapGesture {
                if item.isPreviewForbidden {
                    Toast.info(title: "没有权限")
                } else {
                    previewItem = FileRowContent.PreviewItem(url: item.previewURL)
                }
            }
        }
    }
}

struct FileRowContent: View {
    let item: FileItem
    let fileManager: FileTreeManager
    @State private var showDeleteAlert = false
    @State private var showClearAlert = false
    @State private var imageIcon: Image?
    @State private var sharedFile: URL?
    @State private var previewItem: PreviewItem?

    struct PreviewItem: Identifiable {
        let url: URL
        var id: String { url.path }
    }

    var body: some View {
        HStack(spacing: 12) {
            if item.isDirectory {
                Image(systemName: item.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
            } else if let imageIcon {
                imageIcon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: item.icon)
                    .foregroundColor(.secondary)
                    .font(.title2)
            }

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
        .modifier(FilePreviewTapModifier(previewItem: $previewItem, item: item))
        .contextMenu(
            menuItems: {
                if item.isDirectory && !item.isLibraryProtected {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("清空文件夹", systemImage: "trash.slash")
                    }
                    Divider()
                }

                if let uiImage = imageIcon, let sharedFile, !item.isDirectory {
                    ShareLink(
                        item: sharedFile,
                        preview: SharePreview(item.url.lastPathComponent, image: uiImage)
                    ) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                }

                if !item.isLibraryProtected {
                    Button(role: .destructive) {
                        if item.isPreferencesProtected {
                            Toast.info(title: "没有权限")
                        } else {
                            showDeleteAlert = true
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            },
            preview: {
                if let image = imageIcon {
                    image
                        .font(.system(size: 200))
                } else {
                    Image(systemName: item.icon)
                        .font(.title2)
                }
            }
        )
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if item.isPreferencesProtected || item.isLibraryProtected {
                    Toast.info(title: "没有权限")
                } else if ["plist", "sqlite"].contains(item.url.pathExtension) {
                    Toast.info(title: "系统保留文件!")
                } else {
                    fileManager.deleteItem(item)
                    AudioManager.shared.updateFileList()
                }
            }
        } message: {
            Text("确定要删除 \"\(item.name)\" 吗？此操作无法撤销。")
        }
        .alert("清空文件夹", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                fileManager.clearFolder(item)
                AudioManager.shared.updateFileList()
            }
        } message: {
            Text("确定要清空 \"\(item.name)\" 内的所有文件吗？此操作无法撤销。")
        }
        .sheet(item: $previewItem) { item in
            QuickLookPreview(url: item.url) { previewItem = nil }
                .ignoresSafeArea()
        }
        .task(id: item.url) {
            guard !item.isDirectory else { return }
            self.imageIcon = await thumbnail()

            if item.url.pathExtension == "plist" {
                self.sharedFile = AppManager.createDatabaseFileTem()
            } else {
                self.sharedFile = item.url
            }
        }
    }

    func thumbnail(size: CGFloat = 100) async -> Image? {
        if item.url.pathExtension == "sqlite" {
            return Image("sqlite")
        }

        if item.isImageFile,
           let uiImage = await ImageManager.loadThumbnail(
               path: item.url.path(),
               maxPixel: size * UIScreen.main.scale
           )
        {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}

// MARK: - 主文件列表视图

struct NoletFileList: View {
    @StateObject private var fileManager: FileTreeManager

    init(rootURL: URL) {
        _fileManager = StateObject(wrappedValue: FileTreeManager(rootURL: rootURL))
    }

    var body: some View {
        VStack(spacing: 0) {
            if fileManager.isLoading {
                VStack {
                    Spacer()
                    ProgressView("加载文件中...")
                    Spacer()
                }
            } else if fileManager.rootItems.isEmpty {
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

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let ql = PreviewController()
        ql.dataSource = context.coordinator
        ql.currentPreviewItemIndex = 0
        ql.onDone = { [weak coordinator = context.coordinator] in coordinator?.done() }

        let nav = UINavigationController(rootViewController: ql)
        nav.modalPresentationStyle = .fullScreen
        return nav
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url, onDone: onDone) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private let url: URL
        private let onDone: () -> Void

        init(url: URL, onDone: @escaping () -> Void) {
            self.url = url
            self.onDone = onDone
        }

        func numberOfPreviewItems(in _: QLPreviewController) -> Int { 1 }

        func previewController(_: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }

        @objc func done() { onDone() }
    }

    final class PreviewController: QLPreviewController {
        var onDone: (() -> Void)?

        override func viewDidLoad() {
            super.viewDidLoad()
            installDoneButton()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            installDoneButton()
        }

        private func installDoneButton() {
            guard navigationItem.leftBarButtonItem?
                .action != #selector(PreviewController.doneTapped) else { return }
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done, target: self,
                action: #selector(PreviewController.doneTapped)
            )
        }

        @objc private func doneTapped() { onDone?() }
    }
}

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
        NoletFileList(rootURL: NCONFIG.localContainer)
    }
}
