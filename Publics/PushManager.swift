//
//  PushManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/9/7.
//
import CryptoKit
import Foundation
import Security

class APNs {
    static let shared = APNs()

    private init() {}

    private var apnsInfo: ApnsInfo?

    // MARK: - Generate JWT Token

    private func generateAuthToken(_ apnsInfo: ApnsInfo) throws -> ApnsInfo {
        // 去掉 PEM 头尾并解码
        let keyString = apnsInfo.pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(
                domain: "APNs",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base64 in private key"]
            )
        }
        logger.info("Private key length: \(keyData.count)")

        // 使用CryptoKit处理私钥 - 直接使用DER格式
        let privateKey: P256.Signing.PrivateKey

        do {
            // PEM格式的私钥通常是DER编码的，直接使用DER格式
            privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)
        } catch {
            logger.info("Error creating private key with DER: \(error)")
            throw NSError(
                domain: "APNs",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to import private key: \(error)"]
            )
        }

        // Header & Claims
        let header: [String: String] = [
            "alg": "ES256",
            "kid": apnsInfo.keyID,
        ]
        let claims: [String: Any] = [
            "iss": apnsInfo.teamID,
            "iat": Int(Date().timeIntervalSince1970),
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

        var apnsInfo = apnsInfo

        apnsInfo.token = "\(signingInput).\(signatureBase64)"
        apnsInfo.timestamp = Date().addingTimeInterval(30 * 60)

        return apnsInfo
    }

    // MARK: - Push

    func push(
        _ deviceToken: String,
        id: String = UUID().uuidString,
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil,
        markdown: Bool = false,
        group: String = String(localized: "默认"),
        custom: [String: Any] = [:]
    ) async throws -> APNsResponse {
        if deviceToken.isEmpty {
            throw "deviceToken is empty"
        }
        //
        if apnsInfo == nil || (apnsInfo?.timestamp ?? Date.distantPast) < Date() {
            // apnsInfo 为 nil 或者已经过期
            let info = try await CloudManager.shared.pushToken { record in
                guard let apnsInfo = ApnsInfo(record: record) else { throw "No Data" }
                let data = try self.generateAuthToken(apnsInfo)
                return data.toCKRecord(type: CloudManager.apnsInfoName)
            }
            self.apnsInfo = ApnsInfo(record: info)
        }

        guard let apnsInfo = apnsInfo else { throw "No Data" }

        let headers = APNsHeaders(
            apnsTopic: apnsInfo.topic,
            apnsID: UUID().uuidString,
            apnsCollapseID: id,
            apnsPriority: 10,
            apnsExpiration: Int(Date().addingTimeInterval(24 * 60 * 60).timeIntervalSince1970),
            apnsPushType: "alert",
            authorization: apnsInfo.token,
            contentType: "application/json"
        )

        let aps = PushPayload(aps: PushPayload.APS(
            alert: PushPayload.APS.Alert(
                title: title,
                subtitle: subtitle,
                body: body
            ),
            threadID: group,
            category: markdown ? Identifiers.markdown.rawValue : Identifiers
                .myNotificationCategory.rawValue,
            contentAvailable: 0,
            mutableContent: 1,
            interruptionLevel: .active,
            timestamp: Date()
        ))

        guard var apsBody = aps.toEncodableDictionary() else { throw "No Params" }

        for (key, value) in custom {
            if key != "aps" {
                apsBody[key] = value
            }
        }

        #if DEBUG
        var request =
            URLRequest(
                url: URL(string: "https://api.sandbox.push.apple.com/3/device/\(deviceToken)")!
            )

        #else
        var request =
            URLRequest(url: URL(string: "https://api.push.apple.com/3/device/\(deviceToken)")!)
        #endif

        request.httpMethod = "POST"
        request.timeoutInterval = 30
        for (key, value) in headers.toStringDictionary() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: apsBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        // 2. 解码 JSON 成 APNsResponse

        if data.isEmpty {
            var response1 = APNsResponse(statusCode: 200)

            // 1. 检查 HTTP 响应
            if let httpResponse = response as? HTTPURLResponse {
                response1.apnsID = httpResponse.value(forHTTPHeaderField: "apns-id")
                response1.apnsUniqueID = httpResponse.value(forHTTPHeaderField: "apns-unique-id")
                response1.statusCode = httpResponse.statusCode
            }

            return response1

        } else {
            let decoder = JSONDecoder()

            var apnsResponse = try decoder.decode(APNsResponse.self, from: data)

            // 1. 检查 HTTP 响应
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code:", httpResponse.statusCode)
                apnsResponse.apnsID = httpResponse.value(forHTTPHeaderField: "apns-id")
                apnsResponse.apnsUniqueID = httpResponse.value(forHTTPHeaderField: "apns-unique-id")
                if httpResponse.statusCode == 410,
                   let tsString = httpResponse.value(forHTTPHeaderField: "timestamp"),
                   let tsDouble = Double(tsString)
                {
                    apnsResponse.timestamp = Date(timeIntervalSince1970: tsDouble)
                }
            }
            
            

            logger.info("apnsResponse: \(String(describing: apnsResponse))")

            return apnsResponse
        }
    }

    func ceshi() async {
        do {
            let response = try await APNs.shared.push(
                Defaults[.deviceToken],
                title: "",
                body: "",
                markdown: true
            )
            logger.info("response: \(String(describing: response))")
        } catch {
            logger.error("\(error)")
        }
    }
}

// MARK: - Base64URL Encode

extension Data {
    fileprivate func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension APNs {
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
            var threadID: String?
            var category: String?
            var contentAvailable: Int?
            var mutableContent: Int?
            var targetContentID: String?
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
                case threadID = "thread-id"
                case contentAvailable = "content-available"
                case mutableContent = "mutable-content"
                case targetContentID = "target-content-id"
                case interruptionLevel = "interruption-level"
                case relevanceScore = "relevance-score"
                case filterCriteria = "filter-criteria"
                case staleDate = "stale-date"
                case contentState = "content-state"
                case timestamp
                case dismissalDate = "dimissal-date"
                case attributesType = "attributes-type"
            }

            enum Level: String, Codable {
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
        var apnsID: String?
        var apnsCollapseID: String?
        var apnsPriority: Int = 10
        var apnsExpiration: Int = .init(Date.now.timeIntervalSince1970)
        var apnsPushType: String = "alert"
        var authorization: String = "bearer "
        var contentType: String = "application/json"

        func toStringDictionary() -> [String: String] {
            var dict: [String: String] = [:]
            dict["apns-topic"] = apnsTopic
            if let id = apnsID { dict["apns-id"] = id }
            if let collapseID = apnsCollapseID { dict["apns-collapse-id"] = collapseID }
            dict["apns-priority"] = String(apnsPriority)
            dict["apns-expiration"] = String(apnsExpiration)
            dict["apns-push-type"] = apnsPushType
            dict["authorization"] = "bearer \(authorization)"
            dict["content-type"] = contentType
            return dict
        }
    }

    struct criticalSound: Codable {
        var critical: Int
        var name: String
        var volume: Double
    }
}

struct APNsResponse: Codable {
    var statusCode: Int?
    var reason: String?
    var apnsID: String?
    var timestamp: Date?
    var apnsUniqueID: String?
}
