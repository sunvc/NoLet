//
//  PTTFrameCodec.swift
//  NoLet
//
//  Real-time PTT binary wire protocol codec.
//  Header layout matches the Go server (see controller/PushToTalk/frame.go):
//
//    Offset  Size  Field
//    0       2     magic         = 0x50 0x54 ("PT")
//    2       1     version       = 0x01
//    3       1     type
//    4       4     seq            (uint32, big-endian, session-local)
//    8       4     timestamp_ms   (uint32, big-endian, ms since session start)
//    12      N     payload        (JSON for control frames, raw Opus packet for AUDIO)

import Foundation

/// Every frame type recognised by both ends. Matches server byte values exactly.
nonisolated enum PTTFrameType: UInt8 {
    case hello          = 0x01
    case helloAck       = 0x02
    case start          = 0x10
    case startBroadcast = 0x11
    case audio          = 0x12
    case end            = 0x13
    case endBroadcast   = 0x14
    case leave          = 0x15
    case subscribe      = 0x20
    case replayBegin    = 0x21
    case replayEnd      = 0x22
    case presence       = 0x30
    case ping           = 0x40
    case pong           = 0x41
    case error          = 0x50
}

/// Parsed wire frame. `payload` may be empty for control frames.
nonisolated struct PTTFrame: Sendable {
    let type: PTTFrameType
    let seq: UInt32
    let timestampMs: UInt32
    let payload: Data
}

nonisolated enum PTTFrameCodecError: Error {
    case tooShort
    case badMagic
    case unknownVersion
    case unknownType(UInt8)
    case payloadTooLarge
}

nonisolated enum PTTFrameCodec {
    static let magic0: UInt8 = 0x50    // 'P'
    static let magic1: UInt8 = 0x54    // 'T'
    static let version: UInt8 = 0x01
    static let headerSize = 12

    /// Hard upper bound to guard against buggy peers. The negotiated per-session
    /// limit lives in `Defaults` / server config; this is just a safety net.
    static let maxPayloadBytes = 64 * 1024

    /// Serialises a frame to a big-endian byte buffer.
    static func encode(type: PTTFrameType,
                       seq: UInt32 = 0,
                       timestampMs: UInt32 = 0,
                       payload: Data = Data()) -> Data {
        var buf = Data(count: headerSize + payload.count)
        buf.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            let p = base.assumingMemoryBound(to: UInt8.self)
            p[0] = magic0
            p[1] = magic1
            p[2] = version
            p[3] = type.rawValue
            writeUInt32BE(seq, into: p.advanced(by: 4))
            writeUInt32BE(timestampMs, into: p.advanced(by: 8))
        }
        if !payload.isEmpty {
            buf.replaceSubrange(headerSize..<(headerSize + payload.count), with: payload)
        }
        return buf
    }

    /// Parses a wire frame. The returned payload is an independent copy so the
    /// caller can retain it across the read loop safely.
    static func decode(_ data: Data) throws -> PTTFrame {
        guard data.count >= headerSize else { throw PTTFrameCodecError.tooShort }

        let bytes = [UInt8](data.prefix(headerSize))
        guard bytes[0] == magic0, bytes[1] == magic1 else { throw PTTFrameCodecError.badMagic }
        guard bytes[2] == version else { throw PTTFrameCodecError.unknownVersion }
        guard let type = PTTFrameType(rawValue: bytes[3]) else {
            throw PTTFrameCodecError.unknownType(bytes[3])
        }

        let seq = readUInt32BE(bytes, at: 4)
        let ts = readUInt32BE(bytes, at: 8)
        let payloadCount = data.count - headerSize
        guard payloadCount <= maxPayloadBytes else { throw PTTFrameCodecError.payloadTooLarge }

        let payload = payloadCount > 0
            ? Data(data.suffix(payloadCount))
            : Data()

        return PTTFrame(type: type, seq: seq, timestampMs: ts, payload: payload)
    }

    // MARK: - Big-endian helpers

    @inline(__always)
    private static func writeUInt32BE(_ v: UInt32, into p: UnsafeMutablePointer<UInt8>) {
        p[0] = UInt8((v >> 24) & 0xff)
        p[1] = UInt8((v >> 16) & 0xff)
        p[2] = UInt8((v >> 8)  & 0xff)
        p[3] = UInt8( v        & 0xff)
    }

    @inline(__always)
    private static func readUInt32BE(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        return (UInt32(bytes[offset])     << 24) |
               (UInt32(bytes[offset + 1]) << 16) |
               (UInt32(bytes[offset + 2]) <<  8) |
                UInt32(bytes[offset + 3])
    }
}

// MARK: - JSON payload models

/// HELLO — the mandatory first frame from client.
nonisolated struct PTTHelloPayload: Codable, Sendable {
    let id: String
    let name: String
    let token: String
    let host: String
    let latitude: Double
    let longitude: Double
    let timestamp: Int64
    let channels: [String]
    let proto: Int   // 1 for the WebSocket protocol described in this codec
}

/// HELLO_ACK — mirrors the shape of the REST JoinResponse.
nonisolated struct PTTHelloAckPayload: Codable, Sendable {
    struct ChannelSnapshot: Codable, Sendable {
        let channel: String
        let users: [PTTUserResp]
    }

    let host: String
    let server_time: Int64
    let channels: [ChannelSnapshot]
}

/// Lightweight user shape returned by the server in HELLO_ACK / PRESENCE.
nonisolated struct PTTUserResp: Codable, Sendable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let timestamp: Int64
}

/// ERROR — server-side failure indicator.
nonisolated struct PTTErrorPayload: Codable, Sendable {
    let code: Int
    let message: String
}

/// PRESENCE — bidirectional membership + location broadcast. Server sends
/// `snapshot` immediately after HELLO_ACK, then `join` / `leave` / `update`
/// deltas as they happen. Client only ever sends `update` for its own location.
nonisolated struct PTTPresencePayload: Codable, Sendable {
    let kind: String                // "join" | "leave" | "update" | "snapshot"
    let channel: String
    let user: PTTUserResp?          // present for join/leave/update
    let users: [PTTUserResp]?       // present for snapshot
    let timestamp: Int64
}
