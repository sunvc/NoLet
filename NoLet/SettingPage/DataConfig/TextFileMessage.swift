//
//  TextFileMessage.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//
//
//  History:
//    Created by Neo on 2025/6/5.
//
import SwiftUI
import UniformTypeIdentifiers

struct TextFileMessage: FileDocument, @unchecked Sendable {
    static var readableContentTypes: [UTType] { [.trnExportType] }

    var content: [[AnyHashable: Any]]

    init(content: [[AnyHashable: Any]]) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let decoded = try JSONSerialization.jsonObject(with: data) as? [[AnyHashable: Any]]
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = decoded
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONSerialization.data(
            withJSONObject: content,
            options: [.sortedKeys, .prettyPrinted, .fragmentsAllowed]
        )
        return FileWrapper(regularFileWithContents: data)
    }
}
