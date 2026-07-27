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

}

nonisolated extension Character {
    var isEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji } &&
            (unicodeScalars.first?.properties.isEmojiPresentation == true || unicodeScalars
                .count > 1)
    }
}

extension String {
    /// 仅保留字母和数字字符
    /// - Parameter allowUnicode: 是否保留所有语言的字母（默认仅保留英文和数字）
    /// - Returns: 清理后的字符串
    func onlyLettersAndNumbers(allowUnicode: Bool = false) -> String {
        if allowUnicode {
            return replacing(/[^\p{L}\p{N}]/, with: "")
        } else {
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

// MARK: - 字符串 MD5 转 UUID

nonisolated extension String {
    /// 把当前字符串 MD5 后转为标准 UUID 格式
    func toUUID() -> String {
        guard let data = self.data(using: .utf8) else {
            return ""
        }
        let md5Digest = Insecure.MD5.hash(data: data)

        let md5Hex = md5Digest.map { String(format: "%02hhx", $0) }.joined()

        let start8 = md5Hex.prefix(8)
        let part2 = md5Hex.dropFirst(8).prefix(4)
        let part3 = md5Hex.dropFirst(12).prefix(4)
        let part4 = md5Hex.dropFirst(16).prefix(4)
        let last12 = md5Hex.dropFirst(20).prefix(12)

        return "\(start8)-\(part2)-\(part3)-\(part4)-\(last12)"
    }
}

nonisolated extension String {
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
}
