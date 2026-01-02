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

enum PBMarkdown {
    static func plain(_ markdown: String) -> String {
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
            free(vPtr) 
            return result
        }

        return ""
    }

    static func markdownToHTML(_ markdown: String) -> String? {
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
