//
//  String+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//
import CryptoKit
import SwiftUI

public func NSLocalizedString(
    _ key: String,
    tableName: String? = nil,
    bundle: Bundle = Bundle.main,
    value: String = "",
    comment: String? = nil
) -> String {
    NSLocalizedString(
        key,
        tableName: tableName,
        bundle: bundle,
        value: value,
        comment: comment ?? ""
    )
}

extension String: @retroactive Error {}

extension String {
    /// 移除 URL 的 HTTP/HTTPS 前缀
    func removeHTTPPrefix() -> String {
        return replacingOccurrences(of: "^(https?:\\/\\/)?", with: "", options: .regularExpression)
    }

    nonisolated
    var hasHttp: Bool { ["http", "https"].contains { self.lowercased().hasPrefix($0) } }

    func sha256() -> String {
        // 计算 SHA-256 哈希值
        // 将哈希值转换为十六进制字符串
        guard let data = data(using: .utf8) else {
            return String(prefix(10))
        }
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }

    nonisolated var trimmingSpaceAndNewLines: String {
        replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }

    func avatarImage(size: CGFloat = 300, padding: CGFloat = 16) -> UIImage? {
        guard let textColor = trimmingSpaceAndNewLines.decomposeTextAndColor() else { return nil }

        let singleEmoji = textColor.text.first?.isEmoji ?? false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let backgroundColor: UIColor = singleEmoji ? .clear : textColor.background

        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)

            // 可用绘图区域为去除 padding 后的部分
            let availableRect = rect.insetBy(dx: padding, dy: padding)

            let fontSize = availableRect.height * (singleEmoji ? 1 : 0.85)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: textColor.color,
            ]

            let textSize = textColor.text.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            )

            textColor.text.draw(at: textOrigin, withAttributes: attributes)
        }
    }

    func decomposeTextAndColor(
        _ defaultColor: UIColor = .white,
        _ backgroundColor: UIColor = .systemBlue
    )
        -> (text: String, color: UIColor, background: UIColor)?
    {
        // 拆分字符串，最多取 3 个
        let parts = split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let first = parts.first, !first.isEmpty else {
            return nil // 第一个为空，返回 nil
        }

        // 转成字符数组（注意 Character 可以表示 emoji）
        let chars = Array(first)
        var firstChar: String

        // 如果第一个是 emoji，直接只取一个
        if chars.first?.isEmoji == true {
            firstChar = String(chars[0])
        } else {
            if chars.count >= 2 {
                if chars[0].isLetter || chars[0].isNumber,
                   chars[1].isLetter || chars[1].isNumber
                {
                    firstChar = String(chars[0...1]) // 前两个都是字母/数字
                } else {
                    firstChar = String(chars[0]) // 否则只取第一个
                }
            } else {
                firstChar = String(chars[0])
            }
        }

        switch parts.count {
        case 1:
            return (firstChar, defaultColor, backgroundColor)
        case 2:
            return (firstChar, .white, UIColor(hexString: parts[1]) ?? backgroundColor)
        case 3...:
            return (
                firstChar,
                UIColor(hexString: parts[1]) ?? defaultColor,
                UIColor(hexString: parts[2]) ?? backgroundColor
            )
        default:
            return nil
        }
    }
}

extension Character {
    var isEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji } &&
            (unicodeScalars.first?.properties.isEmojiPresentation == true || unicodeScalars
                .count > 1)
    }
}

extension String {
    nonisolated func normalizedURLString() -> String {
        // 尝试解析
        if let url = URL(string: self),
           let scheme = url.scheme?.lowercased(), scheme.hasHttp
        {
            // 已经是 http/https
            return self
        }

        // 否则强制替换掉错误的 scheme 或缺省情况
        var trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        // 如果原本就带 "://"，去掉前缀再补 https://
        if let range = trimmed.range(of: "://") {
            trimmed = String(trimmed[range.upperBound...])
        }

        return "https://" + trimmed
    }

    /// 仅保留字母和数字字符
    /// - Parameter allowUnicode: 是否保留所有语言的字母（默认仅保留英文和数字）
    /// - Returns: 清理后的字符串
    func onlyLettersAndNumbers(allowUnicode: Bool = false) -> String {
        if allowUnicode {
            // 使用 Unicode 属性，保留所有语言的字母和数字
            return replacing(/[^\p{L}\p{N}]/, with: "")
        } else {
            // 只保留 ASCII 字母和数字
            return replacingOccurrences(
                of: "[^A-Za-z0-9]",
                with: "",
                options: .regularExpression
            )
        }
    }

    func jsonData() -> [String: Any]? {
        if let data = data(using: .utf8),
           let json = try? JSONSerialization
           .jsonObject(with: data, options: []) as? [String: Any]
        {
            return json
        }
        return nil
    }
}
