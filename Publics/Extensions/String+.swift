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


nonisolated extension Character {
    var isEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji } &&
            (unicodeScalars.first?.properties.isEmojiPresentation == true || unicodeScalars
                .count > 1)
    }
}



nonisolated extension String {
    
    /// 移除 URL 的 HTTP/HTTPS 前缀
    func removeHTTPPrefix() -> String {
        return replacingOccurrences(of: "^(https?:\\/\\/)?", with: "", options: .regularExpression)
    }

    var hasHttp: Bool { ["http", "https"].contains { self.lowercased().hasPrefix($0) } }

    func sha256() -> String {
        guard let data = data(using: .utf8) else {
            return String(prefix(10))
        }
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }

    var removingAllWhitespace: String {
        self.filter { !$0.isWhitespace }
    }

    
    func normalizedURLString() -> String {
        if self.isEmpty { return self }
        if let url = URL(string: self),
           let scheme = url.scheme?.lowercased(), scheme.hasHttp
        {
            return self
        }

        var trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        if let range = trimmed.range(of: "://") {
            trimmed = String(trimmed[range.upperBound...])
        }

        return "https://" + trimmed
    }
    
    func avatarImage(size: CGFloat = 300, padding: CGFloat = 16) -> UIImage? {
        guard let textColor = (self.filter { !$0.isWhitespace }).decomposeTextAndColor()
        else { return nil }

        let singleEmoji = textColor.text.first?.isEmoji ?? false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let backgroundColor: UIColor = singleEmoji ? .clear : textColor.background

        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)

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
    ) -> (text: String, color: UIColor, background: UIColor)? {
        let parts = split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let first = parts.first, !first.isEmpty else {
            return nil
        }

        let chars = Array(first)
        var firstChar: String

        if chars.first?.isEmoji == true {
            firstChar = String(chars[0])
        } else {
            if chars.count >= 2 {
                if chars[0].isLetter || chars[0].isNumber,
                   chars[1].isLetter || chars[1].isNumber
                {
                    firstChar = String(chars[0...1])
                } else {
                    firstChar = String(chars[0])
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
