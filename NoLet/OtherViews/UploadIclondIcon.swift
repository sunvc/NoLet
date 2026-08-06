//
//  UploadIclondIcon.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/2.
//

import SwiftUI
import OSLog


struct UploadIclondIcon: View {
    
    private let logger = Logger(subsystem: "app.wzs.logger", category: "UploadIclondIcon")

    
    var dismiss: (PushIcon) -> Void
    var endEditing: () -> Void

    @State private var isChecking: Bool = false

    @State private var tags: [TagModel] = []

    var tsgsTem: [String] {
        tags.compactMap { $0.value }.filter { !$0.removingAllWhitespace.isEmpty }
    }

    @FocusState private var nameFocus

    @State private var pictureLoading: Bool = false

    @State private var pushIcon: PushIcon
    @State private var tips: String? = nil
    @State private var saveOk: Bool = false
    @State private var status: Bool = false
    @State private var freeCount: Int = 0

    init(
        pushIcon: PushIcon,
        dismiss: @escaping (PushIcon) -> Void,
        endEditing: @escaping () -> Void
    ) {
        self.dismiss = dismiss
        self.endEditing = endEditing
        self.pushIcon = pushIcon
    }

    var btnTitle: String {
        status ? String(localized: "上传到云端") : String(localized: "iCloud状态检查")
    }

    var loadingTitle: String {
        if pictureLoading {
            return status ? String(localized: "正在处理中...") : String(localized: "iCloud状态检查中...")
        } else {
            return ""
        }
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .bottom) {
                if let previewImage = pushIcon.previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .blur(radius: pictureLoading ? 5 : 0)
                        .overlay {
                            ProgressView()
                                .opacity(pictureLoading ? 1 : 0)
                                .tint(.red)
                                .scaleEffect(2.0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            ColoredBorder(cornerRadius: 10)
                        )
                }
                VStack {
                    HStack {
                        Spacer()

                        Text("图标额度剩余")
                            .foregroundStyle(.gray)
                            .font(.footnote)

                        Text(verbatim: "\(freeCount)")
                            .foregroundStyle(freeCount < 5 ? .red : .green)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 10)
                    Spacer()
                    TextField(
                        text: $pushIcon.name,
                        prompt: Text("输入图片名称"),
                        label: { Text("图片Key") }
                    )
                    .focused($nameFocus)
                    .customField(icon: isChecking ? "checkmark.circle.fill" :
                        "checkmark.circle")
                    .padding(.horizontal, 10)
                }
            }
            .padding()

            TagField(tags: $tags)
                .padding()
                .onChange(of: tags) { _ in
                    self.pushIcon.description = self.tsgsTem
                }

            Button {
                if pushIcon.previewImage == nil {
                    self.tips = String(localized: "没有图片")
                } else {
                    if self.freeCount == 0 {
                        self.tips = String(localized: "剩余空间不足")
                        return
                    }
                    Task {
                        await saveItems()
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    Label(
                        loadingTitle.isEmpty ? btnTitle : loadingTitle,
                        systemImage: "externaldrive.badge.icloud"
                    )
                    .foregroundStyle(.white, Color.primary)
                    .fontWeight(.bold)
                    .padding(.vertical, 5)

                    Spacer()
                }
            }
            .diff { view in
                Group {
                    if #available(iOS 26.0, *) {
                        view
                            .buttonStyle(.glassProminent)
                    } else {
                        view
                            .buttonStyle(BorderedProminentButtonStyle())
                    }
                }

            }.disabled(pictureLoading || !status)
            .padding(.horizontal)

        }.simultaneousGesture(
            DragGesture()
                .onEnded { transform in
                    if transform.translation.height > 50 {
                        endEditing()
                    }
                }
        ).alert(isPresented: Binding(get: {
            tips != nil
        }, set: { value in
            if !value {
                tips = nil
            }
        })) {
            Alert(
                title: Text("提示"),
                message: Text(tips ?? ""),
                dismissButton: .default(Text(verbatim: "ok")) {
                    if saveOk {
                        self.dismiss(pushIcon)
                    }
                }
            )
        }
        .disabled(!status || freeCount == 0)
        .onAppear(perform: {
            pictureLoading = true
            Task {
                do {
                    let (success, message) = await NCONFIG.checkAccount()

                    let userID = try await NCONFIG.container.userRecordID()
                    let records = try await PushIcon.query(
                        NSPredicate(format: "creatorUserRecordID == %@", userID),
                        from: NCONFIG.publicCloudDatabase
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.freeCount = Defaults[.freeCloudImageCount] - records.count
                        if !success {
                            self.tips = message
                        }
                        self.status = success && self.freeCount > 0
                        pictureLoading = false
                    }
                } catch {
                    logger.error("\(error.localizedDescription)")
                }
            }
        })
    }

    /// Saving Items to SwiftData
    func saveItems() async {
        DispatchQueue.main.async {
            self.pictureLoading = true
        }

        let (success, msg) = await self.savePushIconModel(pushIcon)

        if success {
            saveOk = true
        }
        if let msg{
            logger.info("\(msg)")
        }
        

        DispatchQueue.main.async {
            self.tips = msg
            self.pictureLoading = false
        }
    }

    func savePushIconModel(_ record: PushIcon, file: URL? = nil) async -> (Bool, String?) {
        do {
            guard !record.name.isEmpty, record.file != nil else {
                return (false, String(localized: "参数不全"))
            }

            let records = try await PushIcon.query(
                NSPredicate(format: "name == %@", record.name),
                from: NCONFIG.publicCloudDatabase
            )
            if records.count == 0 {
                try await record.save(to: NCONFIG.publicCloudDatabase)
                return (true, nil)
            }
            return (false, String(localized: "图片名不可用!"))
        } catch {
            logger.error("\(error.localizedDescription)")
            return (false,"\(error.localizedDescription)")
        }
    }
}
