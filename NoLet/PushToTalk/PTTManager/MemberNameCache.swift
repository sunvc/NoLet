//
//  SWIFT: 6.0
//  NoLet - MemberNameCache.swift
//
//  按 userId 从 CloudKit `MemberModel` 拉取昵称并做进程内缓存;
//  查不到/进行中时同步返回 nil,由调用方回退到本地兜底文案。
//
//  History:
//    Created by Neo on 2026/7/26.

import CloudKit
import Defaults
import Foundation
import os

/// 线程安全的成员昵称缓存。缓存 key = userId(CKRecord.ID.recordName)。
/// - 命中: 立刻返回名字(可能是空串,代表云端确实没设置昵称)
/// - miss: 返回 nil,并在后台异步查 CloudKit;结果回填缓存后调用 `onUpdate` 通知刷新
nonisolated final class MemberNameCache: @unchecked Sendable {
    static let shared = MemberNameCache()

    /// 缓存项。`nil` 表示查询进行中 or 上次查询失败(用作短期防抖)
    private struct Entry {
        var name: String
        var expiresAt: Date
    }

    private let store = OSAllocatedUnfairLock<[String: Entry]>(initialState: [:])
    private let inflight = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    /// 命中或缺省成功时触发,调用方(PTTManager)据此刷新 UI
    var onUpdate: (@Sendable (_ id: String, _ name: String) -> Void)?

    /// 单条记录 TTL,超时后 miss 会重新拉一次
    private let ttl: TimeInterval = 60 * 30

    private init() {}

    /// 同步查缓存,不发起网络。
    /// - Returns: 命中且未过期返回名字(可能是空串);其它返回 nil
    func cached(id: String) -> String? {
        store.withLock { dict in
            guard let entry = dict[id] else { return nil }
            if entry.expiresAt < .init(timeIntervalSinceNow: 0) {
                dict.removeValue(forKey: id)
                return nil
            }
            return entry.name
        }
    }

    /// 触发拉取(若未在飞行中且缓存 miss)。
    func prefetch(id: String) {
        // 已有有效缓存直接跳过
        if cached(id: id) != nil { return }

        // 幂等
        let inserted = inflight.withLock { set -> Bool in
            if set.contains(id) { return false }
            set.insert(id)
            return true
        }
        guard inserted else { return }

        Task.detached(priority: .utility) { [weak self] in
            defer {
                _ = self?.inflight.withLock { $0.remove(id) }
            }
            do {
                let member = try await MemberModel.fetch(
                    id: id,
                    from: NCONFIG.container.publicCloudDatabase
                )
                let name = member?.name ?? ""
                guard let self else { return }
                let ttl = self.ttl
                self.store.withLock { dict in
                    dict[id] = Entry(
                        name: name,
                        expiresAt: Date().addingTimeInterval(ttl)
                    )
                }
                self.onUpdate?(id, name)
            } catch {
                logger.error("MemberNameCache fetch \(id) failed: \(error.localizedDescription)")
            }
        }
    }

    /// 手动写入(比如把当前用户 name 塞进缓存,避免自查云)
    func setLocal(id: String, name: String) {
        store.withLock { dict in
            dict[id] = Entry(
                name: name,
                expiresAt: Date().addingTimeInterval(ttl)
            )
        }
    }

    func invalidate(id: String) {
        _ = store.withLock { $0.removeValue(forKey: id) }
    }
}
