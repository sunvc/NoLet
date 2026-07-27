//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - AppleArchiveManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/23 12:21.

import AppleArchive
import Foundation
import System

public final class AppleArchiveManager {
    /// 自定义错误枚举
    public enum ArchiveError: Error, LocalizedError {
        case sourceFileNotExist
        case unableToCreateFileStream
        case unableToCreateDecompressionStream
        case unableToCreateDecodeStream
        case unableToCreateExtractStream

        case sourceNotExist
        case unableToCreateCompressionStream
        case unableToCreateEncodeStream
        case unableToCreateKeySet

        public var errorDescription: String? {
            switch self {
            case .sourceFileNotExist: return "源归档文件不存在，请检查路径是否正确"
            case .unableToCreateFileStream: return "无法创建基础文件输入流"
            case .unableToCreateDecompressionStream: return "无法创建解层（Decompression）流"
            case .unableToCreateDecodeStream: return "无法创建解码（Decode）流"
            case .unableToCreateExtractStream: return "无法创建提取（Extract）写入流"
            case .sourceNotExist: return "要归档的源目录或文件不存在"
            case .unableToCreateCompressionStream: return "无法创建 LZFSE 压缩流"
            case .unableToCreateEncodeStream: return "无法创建归档编码（Encode）流"
            case .unableToCreateKeySet: return "无法解析给定的字段键集 (FieldKeySet)"
            }
        }
    }

    /// 解压指定路径的 AppleArchive (.aar) 文件到目标路径
    /// - Parameters:
    ///   - sourcePath: 源 `.aar` 文件的路径（支持绝对路径或带 ~ 的路径，例如 "~/Downloads/sounds.aar"）
    ///   - destinationPath: 目标解压目录路径（例如 "~/Desktop/dest/"）
    public static func extractArchive(
        from sourcePath: String,
        to destinationPath: String
    ) throws {
        let resolvedSource = (sourcePath as NSString).expandingTildeInPath
        let resolvedDestination = (destinationPath as NSString).expandingTildeInPath

        guard FileManager.default.fileExists(atPath: resolvedSource) else {
            throw ArchiveError.sourceFileNotExist
        }

        if !FileManager.default.fileExists(atPath: resolvedDestination) {
            try FileManager.default.createDirectory(
                atPath: resolvedDestination,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        guard let readFileStream = ArchiveByteStream.fileStream(
            path: FilePath(resolvedSource),
            mode: .readOnly,
            options: [],
            permissions: FilePermissions(rawValue: 0o644)
        ) else {
            throw ArchiveError.unableToCreateFileStream
        }
        defer { try? readFileStream.close() }

        guard let decompressStream = ArchiveByteStream
            .decompressionStream(readingFrom: readFileStream)
        else {
            throw ArchiveError.unableToCreateDecompressionStream
        }
        defer { try? decompressStream.close() }

        guard let decodeStream = ArchiveStream.decodeStream(readingFrom: decompressStream) else {
            throw ArchiveError.unableToCreateDecodeStream
        }
        defer { try? decodeStream.close() }

        guard let extractStream = ArchiveStream.extractStream(
            extractingTo: FilePath(resolvedDestination),
            flags: [.ignoreOperationNotPermitted]
        ) else {
            throw ArchiveError.unableToCreateExtractStream
        }
        defer { try? extractStream.close() }

        _ = try ArchiveStream.process(readingFrom: decodeStream, writingTo: extractStream)
    }

    /// 【重载方法】支持用户直接传入 URL 类型的参数
    /// - Parameters:
    ///   - sourceURL: 源文件的 URL 对象
    ///   - destinationURL: 目标目录的 URL 对象
    public static func extractArchive(
        from sourceURL: URL,
        to destinationURL: URL
    ) throws {
        try self.extractArchive(from: sourceURL.path, to: destinationURL.path)
    }

    /// 将指定目录压缩并写入为一个 AppleArchive (.aar) 文件
    /// - Parameters:
    ///   - sourceURL: 要压缩的源目录 URL（对应你代码中的 source）
    ///   - destinationURL: 最终生成的归档文件 URL（对应你代码中的 archiveDestination）
    public static func writeArchive(
        from sourceURL: URL,
        to destinationURL: URL
    ) throws {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw ArchiveError.sourceNotExist
        }

        let archiveFilePath = FilePath(destinationURL.path)

        guard let writeFileStream = ArchiveByteStream.fileStream(
            path: archiveFilePath,
            mode: .writeOnly,
            options: [.create, .truncate],
            permissions: FilePermissions(rawValue: 0o644)
        ) else {
            throw ArchiveError.unableToCreateFileStream
        }
        defer { try? writeFileStream.close() }

        guard let compressStream = ArchiveByteStream.compressionStream(
            using: .lzfse,
            writingTo: writeFileStream
        ) else {
            throw ArchiveError.unableToCreateCompressionStream
        }
        defer { try? compressStream.close() }

        guard let encodeStream = ArchiveStream.encodeStream(writingTo: compressStream) else {
            throw ArchiveError.unableToCreateEncodeStream
        }
        defer { try? encodeStream.close() }

        guard let keySet = ArchiveHeader
            .FieldKeySet("TYP,PAT,LNK,DEV,DAT,UID,GID,MOD,FLG,MTM,BTM,CTM")
        else {
            throw ArchiveError.unableToCreateKeySet
        }

        let sourcePath = FilePath(sourceURL.path)
        try encodeStream.writeDirectoryContents(
            archiveFrom: sourcePath,
            keySet: keySet
        )
    }
}
