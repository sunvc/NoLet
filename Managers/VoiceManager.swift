//
//  VoiceManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/5/28.
//

@_exported import Defaults
import Foundation
import CommonCrypto
import NaturalLanguage

/// Microsoft TTS client implementation
class VoiceManager {
    private let httpClient: URLSession
    private let ssmlProcessor: SSMLProcessor
    
    private let ssmlTemplate = """
    <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts="http://www.w3.org/2001/mstts" xml:lang='%@'>
        <voice name='%@'>
            <mstts:express-as style="%@" styledegree="1.0" role="default">
                <prosody rate='%@%%' pitch='%@%%' volume="medium">
                    %@
                </prosody>
            </mstts:express-as>
        </voice>
    </speak>
    """
    
    /// Initialize with configuration
    init() throws {
        
        self.httpClient = URLSession.shared
        self.ssmlProcessor = try SSMLProcessor(config: Defaults[.ttsConfig].ssml)
    }
    
    /// Get endpoint information
    private func getEndpoint() async throws -> [String: String] {
        if let endpoint = Defaults[.endpoint], let expiry = Defaults[.endpointExpiry], Date() < expiry {
            return endpoint
        }
        
        let endpoint = try await EndpointUtils.getEndpoint()
        
        guard let jwt = endpoint["t"] else {
            throw NSError(domain: "VoiceManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid endpoint response"
            ])
        }
        
        let exp = EndpointUtils.getExp(from: jwt)
        let expDate = Date(timeIntervalSince1970: TimeInterval(exp))
        Defaults[.endpoint] = endpoint
        Defaults[.endpointExpiry] = expDate.addingTimeInterval(-60) // Expire 1 minute before JWT expiry
        return endpoint
    }
    
    /// List available voices
    func listVoices(locale: String? = nil) async throws -> [MicrosoftVoice] {
        // Check cache
        let voicesCache = Defaults[.voiceList]
        
        if let expiry = Defaults[.voicesCacheExpiry], Date() < expiry, !voicesCache.isEmpty {
            if let locale = locale {
                return voicesCache.filter { $0.locale.hasPrefix(locale) }
            }
            return voicesCache
        }
        
        // Get endpoint
        let endpoint = try await getEndpoint()
        guard let region = endpoint["r"]  else {
            throw NSError(domain: "VoiceManager", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Invalid region in endpoint"
            ])
        }
        
        // Create request
        let url = URL(string: EndpointUtils.getVoicesEndpoint(region: region))!
        var request = URLRequest(url: url)
        request.setValue(endpoint["t"], forHTTPHeaderField: "Authorization")
        
        // Send request
        let (data, response) = try await httpClient.data(for: request)
        
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "VoiceManager", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get voices"
            ])
        }
        
        // Decode response
        let msVoices = try JSONDecoder().decode([MicrosoftVoice].self, from: data)

        
        // Update cache
        Defaults[.voiceList] = msVoices
        
        Defaults[.voicesCacheExpiry] = Date().addingTimeInterval(24 * 60 * 60) // Cache for 24 hours
        
        if let locale = locale {
            return msVoices.filter { $0.locale.hasPrefix(locale) }
        }
        
        return msVoices
    }
    
    /// Synthesize speech from text
    func synthesizeSpeech(request: TTSRequest) async throws -> TTSResponse {
        let response = try await createTTSRequest(request: request)
        let (data, _) = try await httpClient.data(for: response)
        
        return TTSResponse(
            audioContent: data,
            contentType: "audio/mpeg",
            cacheHit: false
        )
    }    
    
    /// Create TTS request
    private func createTTSRequest(request: TTSRequest) async throws -> URLRequest {
        // Validate input
        guard !request.text.isEmpty else {
            throw NSError(domain: "VoiceManager", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Text cannot be empty"
            ])
        }
        
        guard request.text.count <= Defaults[.ttsConfig].maxTextLength else {
            throw NSError(domain: "VoiceManager", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Text length exceeds limit"
            ])
        }
        
        // Use default values if not specified
        let voice = request.voice.isEmpty ? Defaults[.ttsConfig].defaultVoice : request.voice
        let style = request.style.isEmpty ? "general" : request.style
        let rate = request.rate.isEmpty ? "\(Defaults[.ttsConfig].defaultRate)" : request.rate
        let pitch = request.pitch.isEmpty ? "\(Defaults[.ttsConfig].defaultPitch)" : request.pitch
        
        // Get locale
        let locale = TextUtils.getLocaleFromVoice(voice)
        
        // Escape text
        let escapedText = ssmlProcessor.escapeSSML(request.text)
        
        // Prepare SSML
        let ssml = String(format: ssmlTemplate, locale, voice, style, rate, pitch, escapedText)
        
        // Get endpoint
        let endpoint = try await getEndpoint()
        guard let region = endpoint["r"] else {
            throw NSError(domain: "VoiceManager", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Invalid region in endpoint"
            ])
        }
        
        // Create request
        let url = URL(string: EndpointUtils.getEndpoint(region: region))!
        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue(endpoint["t"], forHTTPHeaderField: "Authorization")
        httpRequest.setValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue( "\(Defaults[.ttsConfig].defaultFormat.rawValue)",
                              forHTTPHeaderField: "X-Microsoft-OutputFormat")
        httpRequest.setValue("okhttp/5.1.0", forHTTPHeaderField: "User-Agent")
        httpRequest.httpBody = ssml.data(using: .utf8)
        httpRequest.timeoutInterval = TimeInterval(Defaults[.ttsConfig].requestTimeout)
        
        return httpRequest
    }
    
    /// Synthesize long text by splitting into segments
    func createVoice(
        text: String,
        voice: String? = nil,
        rate: String? = nil,
        pitch: String? = nil,
        style: String? = nil,
        noCache:Bool = false,
        maxConcurrency: Int = 10
    ) async throws -> URL {
        let text = TextUtils.processMarkdownText(text)
        
        if let fileUrl = try? FileUtils.getCache(text){
            if noCache{
                try? FileManager.default.removeItem(at: fileUrl)
            }else{
                return fileUrl
            }
        }
        
        guard  text.count < Defaults[.ttsConfig].maxTextLength else {
            throw NSError(domain: "VoiceManager", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Text maximum limit"
            ])
        }
        
        if text.count < Defaults[.ttsConfig].segmentThreshold{
            let request = TTSRequest(
                text: text,
                voice: voice ?? Defaults[.ttsConfig].defaultVoice,
                rate: rate ?? "\(Defaults[.ttsConfig].defaultRate)",
                pitch: pitch ?? "\(Defaults[.ttsConfig].defaultPitch)",
                style: style ?? "general"
            )
            
            let data = try await self.synthesizeSpeech(request: request).audioContent
            
            let filePath = try FileUtils.setCache(data, text: text)
            
            return filePath
        }
        
        
        let maxConcurrency = maxConcurrency == 10 ? Defaults[.ttsConfig].maxConcurrent : maxConcurrency
      
        let sentences = TextUtils.splitIntoSentences(text)
        let segments = TextUtils.mergeStringsWithLimit(
            sentences,
            minLen: Defaults[.ttsConfig].minSentenceLength,
            maxLen: Defaults[.ttsConfig].maxSentenceLength
        )
        
        let segmentCount = segments.count
        var results = Array<Data?>(repeating: nil, count: segmentCount)
        
        let semaphore = AsyncSemaphore(maxConcurrency)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, segment) in segments.enumerated() {
                group.addTask {
                    await semaphore.wait()
                    defer { Task { await semaphore.signal() } }

                    let request = TTSRequest(
                        text: segment,
                        voice: voice ?? Defaults[.ttsConfig].defaultVoice,
                        rate: rate ?? "\(Defaults[.ttsConfig].defaultRate)",
                        pitch: pitch ?? "\(Defaults[.ttsConfig].defaultPitch)",
                        style: style ?? "general"
                    )
                    
                    let response = try await self.synthesizeSpeech(request: request)
                    results[index] = response.audioContent
                }
            }
            try await group.waitForAll()
        }

        for audio in results.compactMap({ $0 }) {
            try FileUtils.appendToFile(audio, text: text)
        }

        return try FileUtils.getCache(text)
    }
    
    
    // MARK: - UTILS

    /// Endpoint utilities
    class EndpointUtils {
        private static let endpointURL = "https://dev.microsofttranslator.com/apps/endpoint?api-version=1.0"
        private static let userAgent = "okhttp/4.5.0"
        private static let clientVersion = "4.0.530a 5fe1dc6c"
        private static let homeGeographicRegion = "zh-Hans-CN"
        private static let voiceDecodeKey = "oik6PdDdMnOXemTbwvMn9de/h9lFnfBaCWbGMMZqqoSaQaqUOqjVGm5NqsmjcBI1x+sS9ugjB55HEJWRiFXYFw=="
        
        /// Get the endpoint URL for a region
        static func getEndpoint(region: String) -> String {
            return "https://\(region).tts.speech.microsoft.com/cognitiveservices/v1"
        }
        
        /// Get the voices endpoint URL for a region
        static func getVoicesEndpoint(region: String) -> String {
            return "https://\(region).tts.speech.microsoft.com/cognitiveservices/voices/list"
        }
        
        /// Get endpoint information
        static func getEndpoint() async throws -> [String: String] {
            guard let signature = sign(endpointURL,voiceDecodeKey: voiceDecodeKey) else { return [:]}
            let userId = generateUserId()
            let traceId = UUID().uuidString
            
            let headers = [
                "Accept-Language": "zh-Hans",
                "X-ClientVersion": clientVersion,
                "X-UserId": userId,
                "X-HomeGeographicRegion": homeGeographicRegion,
                "X-ClientTraceId": traceId,
                "X-MT-Signature": signature,
                "User-Agent": userAgent,
                "Content-Type": "application/json; charset=utf-8",
                "Content-Length": "0",
                "Accept-Encoding": "gzip"
            ]
            
            var request = URLRequest(url: URL(string: endpointURL)!)
            request.httpMethod = "POST"
            
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)

            
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "EndpointUtils", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to get endpoint"
                ])
            }
            
            guard let result = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
                throw NSError(domain: "EndpointUtils", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response format"
                ])
            }
            
            return result
        }
        
        /// Generate signature
        private static  func sign(_ urlStr: String, voiceDecodeKey: String) -> String? {
            // Step 1: Encode URL
            // let encodedUrl = "dev.microsofttranslator.com%2Fapps%2Fendpoint%3Fapi-version%3D1.0"
            
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~") // 这些是 URI 中安全的字符

            let text = urlStr.replacingOccurrences(of: "^(https?:\\/\\/)?", with: "", options: .regularExpression)

            guard let encodedUrl = text.addingPercentEncoding(withAllowedCharacters: allowed) else {
                return nil
            }
            
            // Step 2: UUID without dashes
            let uuidStr = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            
            // Step 3: Format UTC time
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            var formattedDate = formatter.string(from: Date()).lowercased()
            formattedDate += "gmt"
            
            // Step 4: Construct base string to sign
            var baseString = "MSTranslatorAndroidApp\(encodedUrl)\(formattedDate)\(uuidStr)"
            baseString = baseString.lowercased()
            
            // Step 5: Decode voiceDecodeKey (Base64)
            guard let keyData = Data(base64Encoded: voiceDecodeKey) else {
                return nil
            }
            
            // Step 6: HMAC-SHA256
            let baseData = Data(baseString.utf8)
            var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            baseData.withUnsafeBytes { baseBuffer in
                keyData.withUnsafeBytes { keyBuffer in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                           keyBuffer.baseAddress, keyBuffer.count,
                           baseBuffer.baseAddress, baseBuffer.count,
                           &hmac)
                }
            }
            let hmacData = Data(hmac)
            let signBase64 = hmacData.base64EncodedString()
            
            // Step 7: Return final string
            return "MSTranslatorAndroidApp::\(signBase64)::\(formattedDate)::\(uuidStr)"
        }
        
        
        /// Generate user ID
        private static func generateUserId() -> String {
            let chars = Array("abcdef0123456789")
            return String((0..<16).map { _ in chars.randomElement()! })
        }
        
        /// Get JWT expiration time
        static func getExp(from jwt: String) -> Int64 {
            // 分割 JWT 为 header.payload.signature 三部分
            let parts = jwt.components(separatedBy: ".")
            guard parts.count == 3 else {
                return 0
            }
            
            // 解码 Base64URL（注意要补齐 Base64 padding）
            var base64 = parts[1]
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            
            // 补齐 padding
            let paddingLength = 4 - base64.count % 4
            if paddingLength < 4 {
                base64 += String(repeating: "=", count: paddingLength)
            }
            
            guard let payloadData = Data(base64Encoded: base64) else {
                return 0
            }
            
            // 解析 JSON
            guard let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
                return 0
            }
            
            // 获取 exp 字段
            if let exp = json["exp"] as? Double {
                return Int64(exp)
            } else {
                return 0
            }
        }
    }

    /// Text processing utilities
    class TextUtils {
        /// Split text into sentences
        static func splitIntoSentences(_ text: String) -> [String] {
            let tokenizer = NLTokenizer(unit: .sentence)
            tokenizer.string = text
            
            var sentences: [String] = []
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                return true
            }
            
            return sentences
        }
        
        /// Get the locale from a voice name
        static func getLocaleFromVoice(_ voice: String) -> String {
            let components = voice.split(separator: "-")
            if components.count >= 2 {
                return "\(components[0])-\(components[1])"
            }
            return "en-US"
        }
        
        /// Split and filter empty lines
        static func splitAndFilterEmptyLines(_ text: String) -> [String] {
            return text.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        /// Merge strings with length limits
        static func mergeStringsWithLimit(_ strings: [String], minLen: Int, maxLen: Int) -> [String] {
            var result: [String] = []
            var i = 0
            
            while i < strings.count {
                var currentBuilder = ""
                currentBuilder.append(strings[i])
                i += 1
                
                while i < strings.count {
                    let currentLen = currentBuilder.count
                    if currentLen >= minLen {
                        break
                    }
                    
                    let nextLen = strings[i].count
                    if currentLen + nextLen > Int(Double(minLen) * 1.2) {
                        break
                    }
                    
                    currentBuilder.append("\n")
                    currentBuilder.append(strings[i])
                    i += 1
                }
                
                result.append(currentBuilder)
            }
            
            return result
        }
        
        static func processMarkdownText(_ input: String) -> String {
            // 第一步：去除所有空格
            let text = input.replacingOccurrences(of: " ", with: "")
            
            // 第二步：处理每个换行符前的字符
            return PBMarkdown.plain(text).components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .joined(separator: ",")
        }

    }

    /// File utilities
    class FileUtils {
        /// Create a temporary file
        static func createTempFile(fileExtension: String) -> String {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + "." + fileExtension
            return tempDir.appendingPathComponent(fileName).path
        }
        
        
        static func FileName(text:String) throws -> URL{
            let fileName = text.sha256()
            
            guard let group = NCONFIG.getDir(.voice) else {
                throw NSError(domain: "writeToFile", code: 1, userInfo: [
                    "msg":"No Group"
                ])
            }
            return  group.appendingPathComponent("\(fileName).mp3", conformingTo: .audio)
        }
        
        /// Write data to file
        static func setCache(_ data: Data, text:String) throws -> URL {
            let filepath  = try Self.FileName(text: text)
            
            try data.write(to: filepath)
            
            return filepath
        }
        
        static func appendToFile(_ data: Data, text: String) throws {
            let filepath  = try Self.FileName(text: text)
            
            if FileManager.default.fileExists(atPath: filepath.path()) {
                let handle = try FileHandle(forWritingTo: filepath)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } else {
                // 文件不存在，直接写入
                try data.write(to: filepath)
            }
        }
        
        /// Get the file URL for a cached audio file based on hashed text
        static func getCache(_ text: String) throws -> URL {
            let filepath  = try Self.FileName(text: text)
            
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: filepath.path) else {
                throw NSError(domain: "getCache", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "File does not exist"
                ])
            }
            
            return filepath
        }
    }

    /// SSML processor
    class SSMLProcessor {
        private let config: SSMLConfig
        private var patternCache: [String: NSRegularExpression]
        
        init(config: SSMLConfig) throws {
            self.config = config
            self.patternCache = [:]
            
            // Pre-compile regular expressions
            for tagPattern in config.preserveTags {
                do {
                    let regex = try NSRegularExpression(pattern: tagPattern.pattern)
                    patternCache[tagPattern.name] = regex
                } catch {
                    throw NSError(domain: "SSMLProcessor", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to compile regex '\(tagPattern.name)': \(error.localizedDescription)"
                    ])
                }
            }
        }
        
        /// Escape SSML content while preserving configured tags
        func escapeSSML(_ ssml: String) -> String {
            var processedSSML = ssml
            
            // Replace all SSML tags with placeholders
            for (name, regex) in patternCache {
                processedSSML = regex.stringByReplacingMatches(
                    in: processedSSML,
                    range: NSRange(processedSSML.startIndex..., in: processedSSML),
                    withTemplate: "{{\(name)}}"
                )
            }
            
            // Escape special characters
            processedSSML = processedSSML
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "'", with: "&apos;")
                .replacingOccurrences(of: "\"", with: "&quot;")
            
            // Restore SSML tags
            for tagPattern in config.preserveTags {
                processedSSML = processedSSML.replacingOccurrences(
                    of: "{{\(tagPattern.name)}}",
                    with: tagPattern.pattern
                )
            }
            
            return processedSSML
        }
    }


    actor AsyncSemaphore {
        private var value: Int
        private var waitQueue: [CheckedContinuation<Void, Never>] = []

        init(_ value: Int) {
            self.value = value
        }

        func wait() async {
            if value > 0 {
                value -= 1
            } else {
                await withCheckedContinuation { continuation in
                    waitQueue.append(continuation)
                }
            }
        }

        func signal() {
            if let continuation = waitQueue.first {
                waitQueue.removeFirst()
                continuation.resume()
            } else {
                value += 1
            }
        }
    }

    /// Microsoft TTS voice model
    struct MicrosoftVoice: Identifiable,Codable {
        var id:String = UUID().uuidString
        let name: String
        let displayName: String
        let localName: String
        let shortName: String
        let gender: String
        let locale: String
        let localeName: String
        let styleList: [String]?
        let sampleRateHertz: String
        let voiceType: String
        let status: String

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case displayName = "DisplayName"
            case localName = "LocalName"
            case shortName = "ShortName"
            case gender = "Gender"
            case locale = "Locale"
            case localeName = "LocaleName"
            case styleList = "StyleList"
            case sampleRateHertz = "SampleRateHertz"
            case voiceType = "VoiceType"
            case status = "Status"
        }
    }

    /// TTS request model
    struct TTSRequest: Codable {
        let text: String
        let voice: String
        let rate: String
        let pitch: String
        let style: String
    }

    /// TTS response model
    struct TTSResponse: Codable {
        let audioContent: Data
        let contentType: String
        let cacheHit: Bool
    }

    /// SSML request model
    struct SSMLRequest: Codable {
        let ssml: String
        let voice: String
        let rate: String
        let pitch: String
        let format: String
    }

    /// Audio format enum
    enum AudioFormat: String, CaseIterable, Codable {
        case raw16khz16bitMonoPCM = "raw-16khz-16bit-mono-pcm"
        case raw8khz8bitMonoMulaw = "raw-8khz-8bit-mono-mulaw"
        case riff8khz8bitMonoAlaw = "riff-8khz-8bit-mono-alaw"
        case riff8khz8bitMonoMulaw = "riff-8khz-8bit-mono-mulaw"
        case riff16khz16bitMonoPCM = "riff-16khz-16bit-mono-pcm"
        case audio16khz128kbitrateMonoMP3 = "audio-16khz-128kbitrate-mono-mp3"
        case audio16khz64kbitrateMonoMP3 = "audio-16khz-64kbitrate-mono-mp3"
        case audio16khz32kbitrateMonoMP3 = "audio-16khz-32kbitrate-mono-mp3"
        case raw24khz16bitMonoPCM = "raw-24khz-16bit-mono-pcm"
        case riff24khz16bitMonoPCM = "riff-24khz-16bit-mono-pcm"
        case audio24khz160kbitrateMonoMP3 = "audio-24khz-160kbitrate-mono-mp3"
        case audio24khz96kbitrateMonoMP3 = "audio-24khz-96kbitrate-mono-mp3"
        case audio24khz48kbitrateMonoMP3 = "audio-24khz-48kbitrate-mono-mp3"
        case ogg24khz16bitMonoOpus = "ogg-24khz-16bit-mono-opus"
        case webm24khz16bitMonoOpus = "webm-24khz-16bit-mono-opus"
        
        var mimeType: String {
            switch self {
            case .raw16khz16bitMonoPCM, .raw24khz16bitMonoPCM:
                return "audio/pcm"
            case .raw8khz8bitMonoMulaw:
                return "audio/basic"
            case .riff8khz8bitMonoAlaw:
                return "audio/alaw"
            case .riff8khz8bitMonoMulaw:
                return "audio/mulaw"
            case .riff16khz16bitMonoPCM, .riff24khz16bitMonoPCM:
                return "audio/wav"
            case .audio16khz128kbitrateMonoMP3,
                 .audio16khz64kbitrateMonoMP3,
                 .audio16khz32kbitrateMonoMP3,
                 .audio24khz160kbitrateMonoMP3,
                 .audio24khz96kbitrateMonoMP3,
                 .audio24khz48kbitrateMonoMP3:
                return "audio/mp3"
            case .ogg24khz16bitMonoOpus:
                return "audio/ogg"
            case .webm24khz16bitMonoOpus:
                return "audio/webm"
            }
        }
    }

    /// Microsoft TTS configuration
    struct TTSConfig:Codable {
        static let `default` = TTSConfig(
            region: "eastasia",
            defaultVoice: "zh-CN-XiaochenMultilingualNeural",
            defaultRate: 0,
            defaultPitch: 0,
            defaultFormat: .audio24khz48kbitrateMonoMP3,
            maxTextLength: 65535,
            requestTimeout: 36,
            maxConcurrent: 20,
            segmentThreshold: 300,
            minSentenceLength: 200,
            maxSentenceLength: 300,
            voiceMapping: [:],
            ssml: SSMLConfig.default
        )
        
        var region: String
        var defaultVoice: String
        var defaultRate: Int
        var defaultPitch: Int
        var defaultFormat: AudioFormat
        var maxTextLength: Int
        var requestTimeout: Int
        var maxConcurrent: Int
        var segmentThreshold: Int
        var minSentenceLength: Int
        var maxSentenceLength: Int
        var voiceMapping: [String: String]
        var ssml: SSMLConfig
    }

    /// SSML tag pattern configuration
    struct TagPattern:Codable {
        let name: String
        let pattern: String
    }

    /// SSML configuration
    struct SSMLConfig:Codable {
        static let `default` = SSMLConfig(preserveTags: [
            TagPattern(name: "break", pattern: "<break[^>]*>"),
            TagPattern(name: "speak", pattern: "<speak[^>]*>"),
            TagPattern(name: "prosody", pattern: "<prosody[^>]*>"),
            TagPattern(name: "emphasis", pattern: "<emphasis[^>]*>"),
            TagPattern(name: "voice", pattern: "<voice[^>]*>"),
            TagPattern(name: "say-as", pattern: "<say-as[^>]*>"),
            TagPattern(name: "phoneme", pattern: "<phoneme[^>]*>"),
            TagPattern(name: "audio", pattern: "<audio[^>]*>"),
            TagPattern(name: "p", pattern: "<p[^>]*>"),
            TagPattern(name: "s", pattern: "<s[^>]*>"),
            TagPattern(name: "sub", pattern: "<sub[^>]*>"),
            TagPattern(name: "mstts", pattern: "<mstts:[^>]*>")
        ])
        
        let preserveTags: [TagPattern]
    }

}


// MARK: - MODELS
extension Defaults.Keys {
    static let ttsConfig = Key<VoiceManager.TTSConfig>(.SpeakTTSConfig, VoiceManager.TTSConfig.default)
    static let voiceList = Key<[VoiceManager.MicrosoftVoice]>(.SpeakVoiceList, [])
    static let endpoint = Key<[String: String]?>(.SpeakEndpoint, nil)
    static let endpointExpiry = Key<Date?>(.SpeakEndpointExpiry, nil)
    static let voicesCacheExpiry = Key<Date?>(.SpeakVoicesCacheExpiry, nil)
}
extension VoiceManager.TTSConfig: Defaults.Serializable{ }
extension VoiceManager.SSMLConfig: Defaults.Serializable{}
extension VoiceManager.MicrosoftVoice: Defaults.Serializable{}
