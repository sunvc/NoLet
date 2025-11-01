//
//  cryptoManager.swift
//  NoLet
//
//  Created by uuneo 2024/10/8.
//

import Foundation
import CommonCrypto
import CryptoKit
import Defaults



extension Defaults.Keys {
    /// 去除icloud，防止泄漏
    static let cryptoConfigs = Key<[CryptoModelConfig]>(.CryptoSettingFieldsList, [])
    
}
extension CryptoModelConfig: Defaults.Serializable{}
extension CryptoAlgorithm: Defaults.Serializable{}
extension CryptoMode: Defaults.Serializable{}


// MARK: - CryptoMode
enum CryptoMode: String, Codable,CaseIterable, RawRepresentable {
    
    case GCM
    var Icon:String{ "circle.grid.cross.right.filled" }
    
}

enum CryptoAlgorithm: Int, Codable, CaseIterable,RawRepresentable {
    case AES128 = 16 // 16 bytes = 128 bits
    case AES192 = 24 // 24 bytes = 192 bits
    case AES256 = 32 // 32 bytes = 256 bits
    
    var name:String{
        switch self {
        case .AES128: "AES128"
        case .AES192: "AES192"
        case .AES256: "AES256"
        }
    }
    
    var Icon:String{
        switch self{
        case .AES128: "gauge.low"
        case .AES192: "gauge.medium"
        case .AES256: "gauge.high"
        }
    }
    
    
    
}

struct CryptoModelConfig: Identifiable, Equatable, Codable, Hashable{
    var id: String = UUID().uuidString
    var algorithm: CryptoAlgorithm
    var mode: CryptoMode
    var key: String
    var iv: String
    
    var length:Int{ algorithm.rawValue }

    static let data = CryptoModelConfig(algorithm: .AES256, mode: .GCM,
                                        key: Domap.KEY, iv: Domap.IV)
    
    static func random(_ length: Int = 16) -> String {
        Domap.generateRandomString(length)
    }
    
    static func creteNewModel() -> Self{
        CryptoModelConfig(id: UUID().uuidString,
                          algorithm: .AES256,
                          mode: .GCM,
                          key: Self.random(32),
                          iv: Self.random())
    }
    
    static func ==(lls:CryptoModelConfig, rls: CryptoModelConfig) -> Bool{
        return lls.algorithm == rls.algorithm && lls.mode == rls.mode && lls.key == rls.key 
    }
    
}
///  pb://crypto?text=eIxk2XSXdVeC3zsMwmlJevVaXGncCTiUHg5lLiK0S2sG3QLuGMU
extension [CryptoModelConfig]{
    func config(_ number: Int = 0) -> CryptoModelConfig {
        /// number = 0 count > 0 , number = 1 count > 1, number = 3 count > 3
        self.count > number ? self[number] : self.first ?? .data
    }
}

extension CryptoModelConfig {
    func obfuscator(sign:Bool = false) -> String? {
        guard let result = Domap.obfuscator(m: mode.rawValue, k: key, iv: iv)else{ return nil }
        return sign ? CryptoManager(.data).encrypt(result) : result
    }
    
    init?(inputText: String, sign:Bool = false){
        var result:String{
            if sign, let result = CryptoManager(.data).decrypt(base64: inputText){
                return result
            }
            return inputText
        }
        
        guard let (mode, key, iv) = Domap.deobfuscator(result: result),
              let mode = CryptoMode(rawValue: mode),
              let algorithm = CryptoAlgorithm(rawValue: key.count)
        else { return nil}
        self.init(algorithm: algorithm, mode: mode, key: key, iv: iv)
    }
    
    
    func encrypt(inputData: Data) -> Data?{
        CryptoManager(self).encrypt(data: inputData)
    }
    
    func decrypt(inputData: Data) -> Data? {
       CryptoManager(self).decrypt(data: inputData)
    }
    
}




final class CryptoManager {
	
    typealias BASE64 = String
    
	private let algorithm: CryptoAlgorithm
	private let mode: CryptoMode
	private let key: Data
	private let iv: Data
    private let nonceSize = 12
    private let tagSize = 16

	init(_ data: CryptoModelConfig) {
		self.key = data.key.data(using: .utf8)!
        self.iv = CryptoModelConfig.random().prefix(nonceSize).data(using: .utf8)!
		self.mode = data.mode
		self.algorithm = data.algorithm
	}

    
    // MARK: - Public Methods
	func encrypt(_ plaintext: String) -> BASE64? {
		guard let plaintextData = plaintext.data(using: .utf8) else { return nil }
        return self.encrypt(plaintextData)
	}
    
    func encrypt(_ plaintext: Data) -> BASE64? {
        let data:Data? = self.encrypt(data: plaintext)
            /// .replacingOccurrences(of: "+", with: "%2B")
        return data?.base64EncodedString()
    }
    
    func decrypt(base64 plaintext: BASE64) -> String? {
        
        guard let plaintextData = Data(base64Encoded: plaintext),
              let decryptedData = self.decrypt(data: plaintextData) else { return nil }
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
            NLog.error("GCM Encryption error: \(error)")
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
            NLog.error("GCM Decryption error: \(error)")
			return nil
		}
	}

}


extension String{
    var safeBase64: String{
        self
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
