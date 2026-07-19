//
//  PTTJitterBuffer.swift
//  NoLet
//
//  Minimal jitter buffer for a single receive session.
//
//  Design: packets arrive out of order (or with gaps) — this buffer stashes
//  them keyed by seq and yields them monotonically when the drain routine
//  asks for the next one. Missing packets are surfaced explicitly so the
//  decoder can call `OpusRealtimeDecoder.decodeMissingPacket(...)` for
//  packet-loss concealment (PLC).
//
//  The buffer is deliberately simple:
//   - Depth is capped by count; the oldest packets are dropped first.
//   - No time-domain policy (arrival-time deadlines) — the caller decides
//     when to give up waiting for a hole and ask for PLC.
//   - Not thread-safe. Callers on the receiver stay on a single actor / queue.

import Foundation

enum PTTJitterOutcome: Equatable {
    /// Next packet was ready and returned.
    case packet(Data)
    /// Next seq is not yet in the buffer; caller may either wait or call
    /// again with `treatAsLost = true` for PLC.
    case waitingForSeq(UInt32)
    /// Caller opted to replace the missing packet with a synthesised one
    /// (typically an OpusRealtimeDecoder.decodeMissingPacket result).
    case lost(UInt32)
    /// No more packets and stream has been terminated.
    case exhausted
}

/// Single-writer / single-reader jitter buffer keyed by session-local seq.
final class PTTJitterBuffer {

    /// Maximum number of packets held at once. At 20 ms per packet the default
    /// gives ~2 s of jitter tolerance — plenty for typical mobile networks.
    let maxDepth: Int

    /// Next seq the receiver expects to hand to the decoder.
    private(set) var nextSeq: UInt32 = 0

    /// Whether the sender has told us the stream is over.
    private var streamEnded = false

    private var packets: [UInt32: Data] = [:]

    init(maxDepth: Int = 100) {
        self.maxDepth = maxDepth
    }

    /// Records that this session begins at the given seq. Should be called
    /// once, before any packets arrive.
    func reset(startingSeq: UInt32 = 0) {
        packets.removeAll(keepingCapacity: true)
        nextSeq = startingSeq
        streamEnded = false
    }

    /// Signals END-of-stream so `drainNext(...)` can eventually report
    /// `.exhausted`.
    func markEndOfStream() {
        streamEnded = true
    }

    /// Inserts a packet. Duplicates and out-of-window packets are silently
    /// dropped. Returns whether the packet was accepted.
    @discardableResult
    func insert(seq: UInt32, payload: Data) -> Bool {
        // Reject packets older than what we've already handed downstream.
        if seq < nextSeq { return false }

        packets[seq] = payload

        // Cap depth from the head; keep newest data.
        while packets.count > maxDepth {
            let oldest = packets.keys.min() ?? nextSeq
            packets.removeValue(forKey: oldest)
            // If we drop the packet we've been waiting for, skip past it.
            if oldest == nextSeq {
                nextSeq &+= 1
            }
        }
        return true
    }

    /// Attempts to advance the read cursor.
    ///
    /// - Parameter treatAsLost: if the requested seq is missing and this is
    ///   true, the cursor advances past it and the caller is informed via
    ///   `.lost(seq)` so it can synthesise a PLC packet.
    func drainNext(treatAsLost: Bool = false) -> PTTJitterOutcome {
        if let payload = packets.removeValue(forKey: nextSeq) {
            nextSeq &+= 1
            return .packet(payload)
        }

        if treatAsLost {
            let lost = nextSeq
            nextSeq &+= 1
            return .lost(lost)
        }

        if streamEnded && packets.isEmpty {
            return .exhausted
        }
        return .waitingForSeq(nextSeq)
    }

    /// Advances the read cursor without clearing newer buffered packets.
    /// Used at replay → live handoff when the server's ring replay ends before
    /// the sender's current monotonic sequence number.
    func advance(to sequence: UInt32) {
        guard sequence > nextSeq else { return }
        packets = packets.filter { $0.key >= sequence }
        nextSeq = sequence
    }

    /// Lowest sequence currently buffered, if any.
    var minimumPendingSeq: UInt32? { packets.keys.min() }

    /// How many packets are buffered ahead of the read cursor.
    var pendingCount: Int { packets.count }
}
