//
//  IDManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/9/22.
//

import Foundation
import Security

final nonisolated class IDManager: Sendable {
    
    private static let shared = IDManager()

    private static let alphabet: [Character] = Array(
        "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    )

    private static let alphabetIndex: [Character: Int] = {
        Dictionary(uniqueKeysWithValues: alphabet.enumerated().map { ($1, $0) })
    }()

    private static let alphaLen = alphabet.count

    private static let encodedLength = Int(
        ceil((128 * log(2.0)) / log(Double(alphaLen)))
    )

    private static let account = "NOLETACCOUNTDEVICEID"

    private static let service =
        Bundle.main.bundleIdentifier ?? "me.uuneo.Meoworld"

    private init() {}

    static var id: String {
        if let id = IDManager.shared.read() {
            return id
        }
        let id = IDManager.shared.encode(uuid: UUID())
        IDManager.shared.save(id)
        return id
    }

    private func save(_ id: String) {
        guard let data = id.data(using: .utf8) else { return }
        // 先删除旧数据，防止重复
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]
        SecItemDelete(queryDelete as CFDictionary)

        // 添加新数据
        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecValueData as String: data,
        ]
        SecItemAdd(queryAdd as CFDictionary, nil)
    }

    private func read() -> String? {
        let queryRead: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(queryRead as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data,
           let id = String(data: data, encoding: .utf8)
        {
            return id
        }
        return nil
    }

    func encode(uuid: UUID = UUID()) -> String {
        var uuidBytes = [UInt8](repeating: 0, count: 16)
        let uuidTuple = uuid.uuid
        uuidBytes[0] = uuidTuple.0; uuidBytes[1] = uuidTuple.1; uuidBytes[2] = uuidTuple
            .2; uuidBytes[3] = uuidTuple.3
        uuidBytes[4] = uuidTuple.4; uuidBytes[5] = uuidTuple.5; uuidBytes[6] = uuidTuple
            .6; uuidBytes[7] = uuidTuple.7
        uuidBytes[8] = uuidTuple.8; uuidBytes[9] = uuidTuple.9; uuidBytes[10] = uuidTuple
            .10; uuidBytes[11] = uuidTuple.11
        uuidBytes[12] = uuidTuple.12; uuidBytes[13] = uuidTuple.13; uuidBytes[14] = uuidTuple
            .14; uuidBytes[15] = uuidTuple.15

        var resultChars = [Character]()
        var numberBytes = uuidBytes

        while !numberBytes.allSatisfy({ $0 == 0 }) {
            var remainder = 0
            for i in 0..<numberBytes.count {
                let current = remainder * 256 + Int(numberBytes[i])
                numberBytes[i] = UInt8(current / Self.alphaLen)
                remainder = current % Self.alphaLen
            }
            resultChars.append(Self.alphabet[remainder])
        }

        let padLength = Self.encodedLength
        if resultChars.count < padLength {
            let needed = padLength - resultChars.count
            resultChars.append(contentsOf: repeatElement(Self.alphabet[0], count: needed))
        }

        return String(resultChars.reversed())
    }

    // MARK: - Decode (Short String -> UUID)

    func decode(string: String) -> UUID? {
        var numberBytes = [UInt8](repeating: 0, count: 16)

        for char in string {
            guard let charValue = Self.alphabetIndex[char] else {
                return nil
            }

            var carry = charValue
            for i in (0..<16).reversed() {
                let current = Int(numberBytes[i]) * Self.alphaLen + carry
                numberBytes[i] = UInt8(current & 0xFF)
                carry = current >> 8
            }
        }
        let tuple = (
            numberBytes[0], numberBytes[1], numberBytes[2], numberBytes[3],
            numberBytes[4], numberBytes[5], numberBytes[6], numberBytes[7],
            numberBytes[8], numberBytes[9], numberBytes[10], numberBytes[11],
            numberBytes[12], numberBytes[13], numberBytes[14], numberBytes[15]
        )
        return UUID(uuid: tuple)
    }
}
