//
//  cryptoManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/8.
//

import CommonCrypto
import CryptoKit
import Defaults
import Foundation

final class CryptoManager {
    typealias BASE64 = String

    private let algorithm: CryptoAlgorithm
    private let mode: CryptoMode
    private let key: Data
    private let iv: Data
    private let nonceSize = 12
    private let tagSize = 16

    init(_ data: CryptoModelConfig) {
        key = data.key.data(using: .utf8)!
        iv = CryptoModelConfig.random().prefix(nonceSize).data(using: .utf8)!
        mode = data.mode
        algorithm = data.algorithm
    }

    // MARK: - Public Methods

    func encrypt(_ plaintext: String) -> BASE64? {
        guard let plaintextData = plaintext.data(using: .utf8) else { return nil }
        return encrypt(plaintextData)
    }

    func encrypt(_ plaintext: Data) -> BASE64? {
        let data: Data? = encrypt(data: plaintext)
        /// .replacingOccurrences(of: "+", with: "%2B")
        return data?.base64EncodedString()
    }

    func decrypt(base64 plaintext: BASE64) -> String? {
        guard let plaintextData = Data(base64Encoded: plaintext),
              let decryptedData = decrypt(data: plaintextData) else { return nil }
        return String(data: decryptedData, encoding: .utf8)
    }

    // CryptoKit (GCM) Encryption
    func encrypt(data: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: key)

        do {
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
            return nonce + sealedBox.ciphertext + sealedBox.tag // Nonce + Ciphertext + Tag
        } catch {
            logger.error("❌GCM Encryption error: \(error)")
            return nil
        }
    }

    // CryptoKit (GCM) Decryption
    func decrypt(data: Data) -> Data? {
        guard data.count > nonceSize + tagSize else { return nil }

        let symmetricKey = SymmetricKey(data: key)
        let nonce = try? AES.GCM.Nonce(data: data.prefix(nonceSize))
        let ciphertext = data.dropFirst(nonceSize).dropLast(tagSize)
        let tag = data.suffix(tagSize)
        

        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce!, ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            logger.error("❌GCM Decryption error: \(error)")
            return nil
        }
    }
    
    static func signature(sign: String?, server key: String?) -> [String: String] {
        var result: [String: String] = [:]
        let data = "\(Int(Date().timeIntervalSince1970))"
        var signInt: String {
            guard let sign = sign,
                  let config = CryptoModelConfig(inputText: sign),
                  let signTem = CryptoManager(config).encrypt(data)
            else {
                let signTem = CryptoManager(.data).encrypt(data)
                return signTem?.safeBase64 ?? ""
            }
            return signTem.safeBase64
        }

        result["X-Device"] = Defaults[.id]
        result["X-USER"] = key
        result["Authorization"] = signInt
        result["X-Signature"] = signInt
        
        return result
    }

}

extension Defaults.Keys {
    static let cryptoConfigs = Key<[CryptoModelConfig]>("CryptoSettingFieldsList", [])
}

// MARK: - CryptoMode

enum CryptoMode: String, Codable, CaseIterable, RawRepresentable, Defaults.Serializable {
    case GCM
    var Icon: String {
        switch self {
        case .GCM: "circle.grid.cross.right.filled"
        }
    }
}

enum CryptoAlgorithm: Int, Codable, CaseIterable, RawRepresentable, Defaults.Serializable {
    case AES128 = 16 // 16 bytes = 128 bits
    case AES192 = 24 // 24 bytes = 192 bits
    case AES256 = 32 // 32 bytes = 256 bits

    var name: String {
        switch self {
        case .AES128: "AES128"
        case .AES192: "AES192"
        case .AES256: "AES256"
        }
    }

    var Icon: String {
        switch self {
        case .AES128: "gauge.low"
        case .AES192: "gauge.medium"
        case .AES256: "gauge.high"
        }
    }
}

struct CryptoModelConfig: Identifiable, Equatable, Codable, Hashable,
    @MainActor Defaults.Serializable
{
    var id: String = UUID().uuidString
    var algorithm: CryptoAlgorithm
    var mode: CryptoMode
    var key: String
    var iv: String

    var length: Int { algorithm.rawValue }

    static let data = CryptoModelConfig(
        algorithm: .AES256,
        mode: .GCM,
        key: Domap.KEY,
        iv: Domap.IV
    )

    static func random(_ length: Int = 16) -> String {
        Domap.generateRandomString(length)
    }

    static func creteNewModel() -> Self {
        CryptoModelConfig(
            id: UUID().uuidString,
            algorithm: .AES256,
            mode: .GCM,
            key: random(32),
            iv: random()
        )
    }

    static func == (lls: CryptoModelConfig, rls: CryptoModelConfig) -> Bool {
        return lls.algorithm == rls.algorithm && lls.mode == rls.mode && lls.key == rls.key
    }
}

extension CryptoModelConfig {
    func obfuscator(sign: Bool = false) -> String? {
        guard let result = Domap.obfuscator(m: mode.rawValue, k: key, iv: iv) else { return nil }
        return sign ? CryptoManager(.data).encrypt(result) : result
    }

    init?(inputText: String, sign: Bool = false) {
        var result: String {
            if sign, let result = CryptoManager(.data).decrypt(base64: inputText) {
                return result
            }
            return inputText
        }

        guard let (mode, key, iv) = Domap.deobfuscator(result: result),
              let mode = CryptoMode(rawValue: mode),
              let algorithm = CryptoAlgorithm(rawValue: key.count)
        else { return nil }
        self.init(algorithm: algorithm, mode: mode, key: key, iv: iv)
    }

    func encrypt(inputData: Data) -> Data? {
        CryptoManager(self).encrypt(data: inputData)
    }

    func decrypt(inputData: Data) -> Data? {
        CryptoManager(self).decrypt(data: inputData)
    }
    
    
    
}

///  pb://crypto?text=eIxk2XSXdVeC3zsMwmlJevVaXGncCTiUHg5lLiK0S2sG3QLuGMU
extension [CryptoModelConfig] {
    func config(_ number: Int = 0) -> CryptoModelConfig {
        /// number = 0 count > 0 , number = 1 count > 1, number = 3 count > 3
        count > number ? self[number] : first ?? .data
    }
}

extension String {
    var safeBase64: String {
        replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
