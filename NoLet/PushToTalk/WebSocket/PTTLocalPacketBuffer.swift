//
//  PTTLocalPacketBuffer.swift
//  NoLet
//
//  A small ring buffer that holds Opus packets produced by the sender while
//  the WebSocket is not yet in the `.authenticated` state. Once the socket
//  becomes ready, the buffer is drained in seq order so the receiver hears
//  the start of the utterance instead of the middle.
//
//  The buffer is bounded by both duration (default 2 s) and count so the
//  memory footprint stays small even during a long WebSocket cold start.

import Foundation

/// One buffered packet awaiting flush.
struct PTTBufferedPacket: Sendable {
    let seq: UInt32
    let timestampMs: UInt32
    let payload: Data
    let enqueuedAt: TimeInterval
}

/// Not thread-safe on its own — callers are expected to serialise access on
/// a single actor / queue (the sender uses `@MainActor`).
final class PTTLocalPacketBuffer {
    let maxDuration: TimeInterval
    let maxCount: Int

    private var packets: [PTTBufferedPacket] = []

    init(maxDuration: TimeInterval = 2.0, maxCount: Int = 100) {
        self.maxDuration = maxDuration
        self.maxCount = maxCount
    }

    /// Appends `packet` and evicts anything older than `maxDuration` or
    /// beyond `maxCount`. Eviction always drops from the head, keeping the
    /// most recent audio available.
    func append(_ packet: PTTBufferedPacket) {
        packets.append(packet)
        let now = packet.enqueuedAt
        while let head = packets.first, now - head.enqueuedAt > maxDuration {
            packets.removeFirst()
        }
        while packets.count > maxCount {
            packets.removeFirst()
        }
    }

    /// Removes and returns everything currently buffered, in insertion order.
    func drain() -> [PTTBufferedPacket] {
        defer { packets.removeAll(keepingCapacity: true) }
        return packets
    }

    /// Empties the buffer without returning its contents. Used when a session
    /// is abandoned (e.g. the user cancelled before the socket ever opened).
    func clear() {
        packets.removeAll(keepingCapacity: true)
    }

    var count: Int { packets.count }
    var isEmpty: Bool { packets.isEmpty }
}
