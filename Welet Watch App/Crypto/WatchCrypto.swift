//
//  WatchCrypto.swift
//  Welet Watch App
//
//  与手机端 cryptoManager 字节级一致的 AES-GCM 实现:
//  密文 = 12B nonce + ciphertext + 16B tag,整体标准 base64;
//  签名头 = timestamp 加密后做 URL-safe base64。
//
//  密钥配置只存在手表本地(UserDefaults),不上传 CloudKit。
//  与手机的密钥需用户手动保持一致(手输/服务器 sign 串)。
//

import CryptoKit
import Foundation

/// 手表本地的一条加密配置。仅本机持久化,永不上云。
/// 不含 iv:GCM 的 nonce 每次加密随机生成并附在密文前 12 字节。
struct WatchCryptoConfig: Identifiable, Codable, Equatable {
    var id: String
    /// 16 / 24 / 32,对应 AES128/192/256
    var algorithm: Int
    /// "GCM"
    var mode: String
    var key: String

    init(
        id: String = UUID().uuidString,
        algorithm: Int,
        mode: String = "GCM",
        key: String
    ) {
        self.id = id
        self.algorithm = algorithm
        self.mode = mode
        self.key = key
    }

    /// 兼容旧版本缓存(曾有 iv 字段),解码时忽略。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        algorithm = try container.decode(Int.self, forKey: .algorithm)
        mode = try container.decode(String.self, forKey: .mode)
        key = try container.decode(String.self, forKey: .key)
    }

    static let fallback = WatchCryptoConfig(
        algorithm: Domap.KEY.count,
        mode: "GCM",
        key: Domap.KEY
    )
}

enum WatchCrypto {
    private static let nonceSize = 12
    private static let tagSize = 16

    static func decrypt(base64: String, config: WatchCryptoConfig) -> String? {
        guard let data = Data(base64Encoded: base64),
              data.count > nonceSize + tagSize
        else { return nil }

        let symmetricKey = SymmetricKey(data: Data(config.key.utf8))
        let nonce = try? AES.GCM.Nonce(data: data.prefix(nonceSize))
        let ciphertext = data.dropFirst(nonceSize).dropLast(tagSize)
        let tag = data.suffix(tagSize)

        guard let nonce,
              let box = try? AES.GCM.SealedBox(
                  nonce: nonce,
                  ciphertext: ciphertext,
                  tag: tag
              ),
              let plain = try? AES.GCM.open(box, using: symmetricKey)
        else { return nil }
        return String(data: plain, encoding: .utf8)
    }

    /// timestamp 签名,与手机 CryptoManager.signature 同构。
    /// sign 为服务器的签名混淆串(k,mode,iv);解析失败回退内置默认密钥。
    static func signature(
        sign: String?,
        deviceID: String,
        serverKey: String,
        configs: [WatchCryptoConfig]
    ) -> [String: String] {
        let timestamp = "\(Int(Date().timeIntervalSince1970))"
        let encrypted = signEncrypt(plaintext: timestamp, sign: sign, configs: configs)

        return [
            "X-Device": deviceID,
            "X-USER": serverKey,
            "Authorization": encrypted,
            "X-Signature": encrypted,
        ]
    }

    private static func signEncrypt(
        plaintext: String,
        sign: String?,
        configs: [WatchCryptoConfig]
    ) -> String {
        if let sign,
           let (mode, key, _) = Domap.deobfuscator(result: sign),
           mode == "GCM"
        {
            // 混淆串自带完整 key,优先直接用;本地列表里有同 key 配置时也复用
            let config = configs.first { $0.key == key }
                ?? WatchCryptoConfig(algorithm: key.count, mode: mode, key: key)
            if let sealed = encrypt(plaintext: plaintext, config: config) {
                return sealed
            }
        }
        return encrypt(plaintext: plaintext, config: .fallback) ?? ""
    }

    private static func encrypt(plaintext: String, config: WatchCryptoConfig) -> String? {
        let symmetricKey = SymmetricKey(data: Data(config.key.utf8))
        let nonceString = String(Domap.generateRandomString(nonceSize).prefix(nonceSize))
        guard let nonce = try? AES.GCM.Nonce(data: Data(nonceString.utf8)),
              let sealed = try? AES.GCM.seal(
                  Data(plaintext.utf8),
                  using: symmetricKey,
                  nonce: nonce
              ),
              let combined = sealed.combined
        else { return nil }
        return combined
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// 与 DecryptionProcessor.decrypt 同语义:
    /// cipherNumber 选配置(越界取第一条,再不行用内置默认),
    /// 解出 JSON 后所有键转小写。
    static func decryptUserInfo(
        _ userInfo: [AnyHashable: Any],
        configs: [WatchCryptoConfig]
    ) -> [AnyHashable: Any]? {
        guard let ciphertext = userInfo[Params.cipherText.name] as? String else {
            return userInfo
        }
        let number = (userInfo[Params.cipherNumber.name] as? NSNumber)?.intValue ?? 0
        let config = configs.indices.contains(number)
            ? configs[number]
            : (configs.first ?? .fallback)

        guard let json = decrypt(base64: ciphertext, config: config),
              let data = json.data(using: .utf8),
              let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        return map.reduce(into: [AnyHashable: Any]()) { $0[$1.key.lowercased()] = $1.value }
    }
}
