//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - TextView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/11/29 12:46.

import SwiftUI
import UIKit

struct TextView: UIViewRepresentable {
    // 内部存储：统一使用富文本处理
    private var attributedText: NSAttributedString

    // 允许外部传入 highlight 参数（仅当使用 String 初始化时有效）
    var highlightText: String?
    var highlightColor: UIColor = .red

    // --- 构造函数 1: 支持普通 String ---
    init(_ text: String, highlight: String? = nil, color: UIColor = .red) {
        highlightText = highlight
        highlightColor = color
        // 初始构建一次
        attributedText = Self.buildHighlightText(text, highlight: highlight, color: color)
    }

    // --- 构造函数 2: 支持直接传入 NSAttributedString ---
    init(_ attributedText: NSAttributedString) {
        self.attributedText = attributedText
        highlightText = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator

        // 基础配置
        view.dataDetectorTypes = [.phoneNumber, .link]
        view.isScrollEnabled = false
        view.isEditable = false
        view.isUserInteractionEnabled = true
        view.isSelectable = true
        view.backgroundColor = .clear

        // 消除边距
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .zero

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }

        let dimensions = attributedText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return CGSize(width: width, height: ceil(dimensions.height))
    }

    // --- 静态辅助方法：构建高亮逻辑 ---
    private static func buildHighlightText(
        _ text: String,
        highlight: String?,
        color: UIColor
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        // 默认样式
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 17), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)

        guard let highlight = highlight,
              !highlight.trimmingCharacters(in: .whitespaces).isEmpty
        else {
            return attributedString
        }

        let keywords = highlight.lowercased().split(separator: " ").map { String($0) }
        let lowercasedText = text.lowercased() as NSString

        attributedString.beginEditing()
        for keyword in keywords {
            var searchRange = NSRange(location: 0, length: lowercasedText.length)
            while searchRange.location < lowercasedText.length {
                let foundRange = lowercasedText.range(of: keyword, options: [], range: searchRange)
                if foundRange.location == NSNotFound { break }

                attributedString.addAttribute(.foregroundColor, value: color, range: foundRange)
                attributedString.addAttribute(
                    .font,
                    value: UIFont.boldSystemFont(ofSize: 17),
                    range: foundRange
                )

                let nextLoc = foundRange.location + foundRange.length
                searchRange = NSRange(location: nextLoc, length: lowercasedText.length - nextLoc)
            }
        }
        attributedString.endEditing()
        return attributedString
    }
}

extension TextView {
    final class Coordinator: NSObject, UITextViewDelegate {
        private var parent: TextView

        init(_ parent: TextView) {
            self.parent = parent
            super.init()
        }

        // 如果需要双向同步（比如在可编辑模式下），可以在这里处理
        func textViewDidChange(_ textView: UITextView) {}
    }
}

struct HighlightedText: View {
    var text: String
    var searchText: String?
    var body: some View {
        if let searchText, !searchText.isEmpty {
            TextView(text, highlight: searchText, color: .red)
        } else {
            Text(text)
        }
    }
}
