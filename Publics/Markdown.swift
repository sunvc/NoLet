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
    static let extensionNames: Set<String> = [
        "autolink",
        "strikethrough",
        "tagfilter",
        "tasklist",
        "table",
    ]

    static func plain(_ markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else { return "" }
        // 确保 parser 最终被释放
        defer { cmark_parser_free(parser) }

        for extensionName in extensionNames {
            if let syntaxExtension = cmark_find_syntax_extension(extensionName) {
                cmark_parser_attach_syntax_extension(parser, syntaxExtension)
            }
        }

        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        guard let doc = cmark_parser_finish(parser) else { return "" }

        defer { cmark_node_free(doc) }

        if let vPtr = cmark_render_plaintext(doc, 0, 0) {
            let result = String(cString: vPtr)
            free(vPtr)
            return result
        }

        return ""
    }

    static func markdownToHTML(_ markdown: String) -> String? {
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else { return nil }

        defer { cmark_parser_free(parser) }

        for name in extensionNames {
            if let syntaxExtension = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, syntaxExtension)
            }
        }
        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        guard let doc = cmark_parser_finish(parser) else { return nil }
        defer { cmark_node_free(doc) }

        if let cStringPtr = cmark_render_html(doc, 0, nil) {
            let htmlString = String(cString: cStringPtr)
            free(cStringPtr)
            return htmlString
        }

        return nil
    }
}
