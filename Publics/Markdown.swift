//
//  Markdown.swift
//  NoLet
//
//  Created by lynn on 2025/5/15.
//

import Foundation
import cmark_gfm
import cmark_gfm_extensions


class PBMarkdown{
    class func plain(_ markdown: String) -> String {
        // 注册 GFM 扩展
        cmark_gfm_core_extensions_ensure_registered()
        
        // 创建解析器
        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else { return "" }
        let extensionNames: Set<String> =  ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        
        for extensionName in extensionNames {
            guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
                continue
            }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }
        // 解析 Markdown
        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        
        guard let doc = cmark_parser_finish(parser) else { return "" }
        
        // 渲染为 HTML
        
        if let text = cmark_render_plaintext(doc, 0, 0) {
            return stripMarkdown(String(cString: text))
        }
        
        
        
        defer {
            // 释放资源
            cmark_node_free(doc)
            cmark_parser_free(parser)
        }
        
        return ""
    }

    class func stripMarkdown(_ markdown: String) -> String {
        var text = markdown
        
        // 移除HTML标签
        text = text.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        
        // 移除Markdown标题
        text = text.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: [.regularExpression])
        
        // 移除Markdown强调符号（粗体、斜体）
        text = text.replacingOccurrences(of: #"(\*\*|__)(.*?)\1"#, with: "$2", options: .regularExpression) // 粗体
        text = text.replacingOccurrences(of: #"(\*|_)(.*?)\1"#, with: "$2", options: .regularExpression) // 斜体
        
        // 移除Markdown链接
        text = text.replacingOccurrences(of: #"\[([^\]]+)\]\([^\)]+\)"#, with: "$1", options: .regularExpression) // [text](url)
        text = text.replacingOccurrences(of: #"\[([^\]]+)\]\[[^\]]+\]"#, with: "$1", options: .regularExpression) // [text][id]
        text = text.replacingOccurrences(of: #"<(https?://[^>]+)>"#, with: "$1", options: .regularExpression) // <url>
        
        // 移除Markdown图片
        text = text.replacingOccurrences(of: #"!\[([^\]]*)\]\([^\)]+\)"#, with: "", options: .regularExpression)
        
        // 移除Markdown列表
        text = text.replacingOccurrences(of: #"^[\*\-+]\s+"#, with: "", options: .regularExpression) // 无序列表
        text = text.replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression) // 有序列表
        
        // 移除Markdown引用
        text = text.replacingOccurrences(of: #"^>\s+"#, with: "", options: .regularExpression)
        
        // 移除Markdown代码块
        text = text.replacingOccurrences(of: #"```[\s\S]*?```"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression) // 行内代码
        
        // 移除Markdown水平线
        text = text.replacingOccurrences(of: #"^([\*\-_])\s*\1\s*\1[\1\s]*$"#, with: "", options: .regularExpression)
        
        // 处理Markdown表格 - 保留内容但去除表格符号
        // 移除表格分隔符行（包含 -: 的行）
        text = text.replacingOccurrences(of: #"\|[\s\-:\|]+\|\n"#, with: "\n", options: .regularExpression)
        
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
        text = text.replacingOccurrences(of: #"^\s*- \[[x ]\]\s+"#, with: "", options: .regularExpression)
        
        // 移除删除线
        text = text.replacingOccurrences(of: #"~~(.*?)~~"#, with: "$1", options: .regularExpression)
        
        // 移除多余的空行
        text = text.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    class func markdownToHTML(_ markdown: String) -> String? {
        // 注册 GFM 扩展
        cmark_gfm_core_extensions_ensure_registered()

        // 创建解析器
        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else {
            
            return nil
        }
        let extensionNames: Set<String> =  ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        
        for extensionName in extensionNames {
          guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
            continue
          }
          cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }
        // 解析 Markdown
        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        
        guard let doc = cmark_parser_finish(parser) else { return nil }

        // 渲染为 HTML
       
        if let html = cmark_render_html(doc, 0, nil) {
           return String(cString: html)
        }
        
       

        defer {
            // 释放资源
            cmark_node_free(doc)
            cmark_parser_free(parser)
        }
       
        return nil
    }
}
