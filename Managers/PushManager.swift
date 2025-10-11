//
//  PushManager.swift
//  pushme
//
//  Created by lynn on 2025/9/7.
//
import Foundation
import CryptoKit
import Security

class APNs {
    private let teamId = "5U8LBRXG3A"       // Apple Developer Team ID
    private let keyId = "LH4T9V5U4R"        // Key ID
    private let topic = "me.fin.bark"       // App Bundle ID
    private let privateKeyPem = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg4vtC3g5L5HgKGJ2+
    T1eA0tOivREvEAY2g+juRXJkYL2gCgYIKoZIzj0DAQehRANCAASmOs3JkSyoGEWZ
    sUGxFs/4pw1rIlSV2IC19M8u3G5kq36upOwyFWj9Gi3Ejc9d3sC7+SHRqXrEAJow
    8/7tRpV+
    -----END PRIVATE KEY-----
    """

    private var cachedAuthToken: (String, TimeInterval)?

    // MARK: - Generate JWT Token
    private func generateAuthToken() throws -> String {
        
        // 去掉 PEM 头尾并解码
        let keyString = privateKeyPem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(domain: "APNs", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid base64 in private key"])
        }
        NLog.log("Private key length:", keyData.count)
        
        // 使用CryptoKit处理私钥 - 直接使用DER格式
        let privateKey: P256.Signing.PrivateKey

        do {
            // PEM格式的私钥通常是DER编码的，直接使用DER格式
            privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)
        } catch {
            NLog.log("Error creating private key with DER: \(error)")
            throw NSError(domain: "APNs", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to import private key: \(error)"])
        }

       // Header & Claims
       let header: [String: String] = [
           "alg": "ES256",
           "kid": keyId
       ]
       let claims: [String: Any] = [
           "iss": teamId,
           "iat": Int(Date().timeIntervalSince1970)
       ]

       let headerData = try JSONSerialization.data(withJSONObject: header)
       let claimsData = try JSONSerialization.data(withJSONObject: claims)

       let headerBase64 = headerData.base64URLEncodedString()
       let claimsBase64 = claimsData.base64URLEncodedString()
       let signingInput = "\(headerBase64).\(claimsBase64)"
       let signingData = Data(signingInput.utf8)

       // 使用CryptoKit签名
       let signature = try privateKey.signature(for: signingData)
       let signatureData = signature.derRepresentation
       let signatureBase64 = signatureData.base64URLEncodedString()

        return "\(signingInput).\(signatureBase64)"
    }


    private func getAuthToken() throws -> String {
        // 20 分钟内复用 token（Apple 要求每 20 分钟更新）
        let now = Date().timeIntervalSince1970
        if let (token, ts) = cachedAuthToken, now - ts < 1500 {
            return token
        }
        let token = try generateAuthToken()
        cachedAuthToken = (token, now)
        return token
    }

    // MARK: - Push
    func push(deviceToken: String, headers: [String: String] = [:], aps: [String: Any]) async throws -> (Int, Data) {
        let authToken = try getAuthToken()

        var request = URLRequest(url: URL(string: "https://api.push.apple.com/3/device/\(deviceToken)")!)
        request.httpMethod = "POST"
        request.setValue("bearer \(authToken)", forHTTPHeaderField: "authorization")
        request.setValue(topic, forHTTPHeaderField: "apns-topic")
        if let priority = headers["apns-priority"] {
            request.setValue(priority, forHTTPHeaderField: "apns-priority")
        }else{
            request.setValue("10", forHTTPHeaderField: "apns-priority")
        }
        request.setValue(headers["apns-push-type"] ?? "alert", forHTTPHeaderField: "apns-push-type")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: aps)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        return (status, data)
    }

    enum Headers: String{
        case apnsPriority
    }
    
    func ceshi() async{
        let apns = APNs()

        do {
            let aps: [String: Any] = [
                "aps": [
                    "alert": [
                        "title": "你好，世界",
                        "subtitle": "这是一个副标题",
                        "body": "Swift APNs"
                    ],
                    "category" : "myNotificationCategory",
                    "sound": "default",
                    "mutable-content": 1,
                    "interruption-level": "critical"
                ]
            ]

            let (status, data) = try await apns.push(deviceToken: "8ca2f941c93d4058f3003fd2f602b005c3ddd71d5ede389255dc7202847887ec",headers:[
                :
            ] ,aps: aps)
            NLog.log("Status:", status)
            NLog.log("Response:", String(data: data, encoding: .utf8) ?? "")
        } catch {
            NLog.error(error)
        }
    }
    
    struct NotificationData: Codable{
        var aps:Aps
    }

    struct Aps: Codable{
        var alert:Alert
        var badge: Int
        var category: String
        var threadId: String?
        var contentAvailable: Int?
        var mutableContent: Int?
        var targetContentId: String
        var interruptionLevel: InterruptionType
    }


    struct Alert: Codable{
        var sound:Sound?
        
    }

    struct Sound: Codable{
        
    }

    enum InterruptionType: String, Codable{
        case passive
        case active
        case timeSensitive = "time-sensitive"
        case critical
    }

}

// MARK: - Base64URL Encode
fileprivate extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

class APNS {
    struct PushPayload: Codable {
        struct APS: Codable {
            struct Alert: Codable {
                var title: String?
                var subtitle: String?
                var body: String?
                var launchImage: String?
                var titleLocKey: String?
                var titleLocArgs: [String]?
                var subtitleLocKey: String?
                var subtitleLocArgs: [String]?
                var locKey: String?
                var locArgs: [String]?

                enum CodingKeys: String, CodingKey {
                    case title, subtitle, body
                    case launchImage = "launch-image"
                    case titleLocKey = "title-loc-key"
                    case titleLocArgs = "title-loc-args"
                    case subtitleLocKey = "subtitle-loc-key"
                    case subtitleLocArgs = "subtitle-loc-args"
                    case locKey = "loc-key"
                    case locArgs = "loc-args"
                }
            }

            var alert: Alert?
            var badge: Int?
            var sound: String?
            var threadId: String?
            var category: String?
            var contentAvailable: Int?
            var mutableContent: Int?
            var targetContentId: String?
            var interruptionLevel: Level = .active
            var relevanceScore: Double?
            var filterCriteria: String?
            var staleDate: Date?
            var contentState: String?
            var timestamp: Date?
            var event: String?
            var dismissalDate: Date?
            var attributesType: String?
            var attributes: [String: String]?

            enum CodingKeys: String, CodingKey {
                case alert, badge, sound, category, event, attributes
                case threadId = "thread-id"
                case contentAvailable = "content-available"
                case mutableContent = "mutable-content"
                case targetContentId = "target-content-id"
                case interruptionLevel = "interruption-level"
                case relevanceScore = "relevance-score"
                case filterCriteria = "filter-criteria"
                case staleDate = "stale-date"
                case contentState = "content-state"
                case timestamp
                case dismissalDate = "dimissal-date"
                case attributesType = "attributes-type"
            }

            enum Level: String, Codable{
                case passive
                case active
                case timeSensitive = "time-sensitive"
                case critical
            }
        }

        var aps: APS
    }


    struct APNsHeaders: Codable {
        var apnsTopic: String
        var apnsId: String?
        var apnsCollapseId: String?
        var apnsPriority: Int = 10
        var apnsExpiration: Int = Int(Date.now.timeIntervalSince1970)
        var apnsPushType: String = "alert"
        var authorization: String = "bearer "
        var contentType: String = "application/json"

        enum CodingKeys: String, CodingKey {
            case apnsTopic = "apns-topic"
            case apnsId = "apns-id"
            case apnsCollapseId = "apns-collapse-id"
            case apnsPriority = "apns-priority"
            case apnsExpiration = "apns-expiration"
            case apnsPushType = "apns-push-type"
            case authorization
            case contentType = "content-type"
        }
    }


    struct criticalSound: Codable{
        var critical: Int
        var name: String
        var volume: Double
    }
}



