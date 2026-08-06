//
//  PendingMessageStore.swift
//  NoLet
//
//  Cross-process inbox between the Notification Service Extension and the app.
//  The extension writes each incoming message as a JSON file named after the
//  SHA256 of its id (Bark-style), then posts a Darwin notification. The app
//  drains the directory and applies each JSON dictionary directly onto a
//  MessageEntity in Core Data — no intermediate DTO.
//

import CryptoKit
import Foundation
import OSLog

struct PendingMessageStore {
    private let logger = Logger(subsystem: "app.wzs.logger", category: "MessageDBManager")
    static let directoryName = "pending_messages"

    let directory: URL

    init(container: URL = NCONFIG.localContainer) {
        directory = container.appendingPathComponent(Self.directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    private func fileURL(for id: String) -> URL {
        let digest = SHA256.hash(data: Data(id.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return directory.appendingPathComponent(digest).appendingPathExtension("json")
    }

    /// Writes a message JSON dictionary. Returns true if a new file was created
    /// (i.e. a genuinely new message — the caller should bump the shared unread
    /// counter). Returns false if a file for this id already existed.
    @discardableResult
    func write(_ json: [AnyHashable: Any]) -> Bool {
        guard let id = (json[.id] as? String)?.nilIfEmpty else { return false }
        let url = fileURL(for: id)
        guard !FileManager.default.fileExists(atPath: url.path) else { return false }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            logger.error("PendingMessageStore write failed: \(error)")
            return false
        }
    }

    /// Reads and removes every pending JSON file, returning decoded dictionaries.
    /// Malformed files are deleted and skipped.
    func drain() -> [[AnyHashable: Any]] {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else { return [] }

        var messages: [[AnyHashable: Any]] = []
        for url in urls {
            defer { try? FileManager.default.removeItem(at: url) }
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any]
            else { continue }
            messages.append(json)
        }
        return messages
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
