//
//  Markdown.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/15.
//

import cmark_gfm
import cmark_gfm_extensions
import Foundation

final class PBMarkdown {
    class func plain(_ markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else { return "" }
        // 确保 parser 最终被释放
        defer { cmark_parser_free(parser) }

        let extensionNames: Set<String> = ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        for extensionName in extensionNames {
            if let syntaxExtension = cmark_find_syntax_extension(extensionName) {
                cmark_parser_attach_syntax_extension(parser, syntaxExtension)
            }
        }

        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        guard let doc = cmark_parser_finish(parser) else { return "" }
        // 确保 doc 节点树最终被释放
        defer { cmark_node_free(doc) }

        // 渲染
        if let vPtr = cmark_render_plaintext(doc, 0, 0) {
            let result = String(cString: vPtr)
            free(vPtr) // 【关键修复】必须手动释放 cmark 分配的 C 字符串
            return stripMarkdown(result)
        }

        return ""
    }

    class func stripMarkdown(_ markdown: String) -> String {
        var text = markdown

        // 移除HTML标签
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)

        // 移除Markdown标题
        text = text.replacingOccurrences(
            of: #"^#{1,6}\s+"#,
            with: "",
            options: [.regularExpression]
        )

        // 移除Markdown强调符号（粗体、斜体）
        text = text.replacingOccurrences(
            of: #"(\*\*|__)(.*?)\1"#,
            with: "$2",
            options: .regularExpression
        ) // 粗体
        text = text.replacingOccurrences(
            of: #"(\*|_)(.*?)\1"#,
            with: "$2",
            options: .regularExpression
        ) // 斜体

        // 移除Markdown链接
        text = text.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^\)]+\)"#,
            with: "$1",
            options: .regularExpression
        ) // [text](url)
        text = text.replacingOccurrences(
            of: #"\[([^\]]+)\]\[[^\]]+\]"#,
            with: "$1",
            options: .regularExpression
        ) // [text][id]
        text = text.replacingOccurrences(
            of: #"<(https?://[^>]+)>"#,
            with: "$1",
            options: .regularExpression
        ) // <url>

        // 移除Markdown图片
        text = text.replacingOccurrences(
            of: #"!\[([^\]]*)\]\([^\)]+\)"#,
            with: "",
            options: .regularExpression
        )

        // 移除Markdown列表
        text = text.replacingOccurrences(
            of: #"^[\*\-+]\s+"#,
            with: "",
            options: .regularExpression
        ) // 无序列表
        text = text
            .replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression) // 有序列表

        // 移除Markdown引用
        text = text.replacingOccurrences(of: #"^>\s+"#, with: "", options: .regularExpression)

        // 移除Markdown代码块
        text = text.replacingOccurrences(
            of: #"```[\s\S]*?```"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "$1",
            options: .regularExpression
        ) // 行内代码

        // 移除Markdown水平线
        text = text.replacingOccurrences(
            of: #"^([\*\-_])\s*\1\s*\1[\1\s]*$"#,
            with: "",
            options: .regularExpression
        )

        // 处理Markdown表格 - 保留内容但去除表格符号
        // 移除表格分隔符行（包含 -: 的行）
        text = text.replacingOccurrences(
            of: #"\|[\s\-:\|]+\|\n"#,
            with: "\n",
            options: .regularExpression
        )

        // 提取表格单元格内容，保留文本
        var lines = text.components(separatedBy: "\n")
        for i in 0..<lines.count {
            if lines[i].contains("|") {
                // 处理表格行，提取单元格内容
                let cells = lines[i].components(separatedBy: "|")
                var cleanedCells: [String] = []

                for cell in cells {
                    let trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        cleanedCells.append(trimmed)
                    }
                }

                // 用空格连接单元格内容
                lines[i] = cleanedCells.joined(separator: " ")
            }
        }

        text = lines.joined(separator: "\n")

        // 移除任务列表
        text = text.replacingOccurrences(
            of: #"^\s*- \[[x ]\]\s+"#,
            with: "",
            options: .regularExpression
        )

        // 移除删除线
        text = text.replacingOccurrences(of: #"~~(.*?)~~"#, with: "$1", options: .regularExpression)

        // 移除多余的空行
        text = text.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    class func markdownToHTML(_ markdown: String) -> String? {
        // 1. 注册扩展（通常只需全局注册一次，但重复调用无害）
        cmark_gfm_core_extensions_ensure_registered()

        // 2. 创建解析器
        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else { return nil }
        // 【修复】立即注册释放逻辑，确保函数结束时一定执行
        defer { cmark_parser_free(parser) }

        let extensionNames: [String] = ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        for name in extensionNames {
            if let syntaxExtension = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, syntaxExtension)
            }
        }

        // 3. 解析
        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        guard let doc = cmark_parser_finish(parser) else { return nil }
        // 【修复】立即注册释放逻辑
        defer { cmark_node_free(doc) }

        // 4. 渲染为 HTML
        // 注意：第三个参数在 GFM 中通常传入已注册的扩展列表，如果只是简单渲染可传 nil
        if let cStringPtr = cmark_render_html(doc, 0, nil) {
            let htmlString = String(cString: cStringPtr)
            // 【核心修复】必须手动释放 C 字符串内存
            free(cStringPtr) 
            return htmlString
        }

        return nil
    }
}
