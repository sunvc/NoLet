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
import UIKit


extension Character {
    var isEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji } &&
            (unicodeScalars.first?.properties.isEmojiPresentation == true || unicodeScalars
                .count > 1)
    }
}



extension String {
    
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
}
