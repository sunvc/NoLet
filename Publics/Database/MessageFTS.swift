//
//  MessageFTS.swift
//  NoLet

import Foundation
import SQLite3


final class MessageFTS: @unchecked Sendable {
    static let shared = MessageFTS()

    private let queue = DispatchQueue(label: "nolet.messagefts")
    private var db: OpaquePointer?

    private init() {}


    func setup(storeURL: URL) {
        queue.async { [self] in
            guard open(storeURL) else { return }
            exec(Self.createTableSQL + Self.triggerSQL + Self.indexSQL)
            if !tableExists("ZMESSAGE_FTS") { return }

            var count = 0
            if let stmt = prepare("SELECT COUNT(*) FROM ZMESSAGE_FTS", []) {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    count = Int(sqlite3_column_int64(stmt, 0))
                }
                sqlite3_finalize(stmt)
            }
            if count == 0 {
                exec(Self.rebuildSQL)
                logger.info("🔍 FTS5 index built")
            }
        }
    }

    // MARK: - Query
    private static let commonThreshold = 5_000


    private func isCommon(_ pattern: String) async -> Bool {
        let sql = "SELECT COUNT(*) FROM (SELECT 1 FROM ZMESSAGE_FTS WHERE ZMESSAGE_FTS MATCH ?1 LIMIT \(Self.commonThreshold))"
        return await withCheckedContinuation { cont in
            queue.async {
                var n = 0
                guard let stmt = self.prepare(sql, [pattern]) else {
                    cont.resume(returning: false)
                    return
                }
                defer { sqlite3_finalize(stmt) }
                if sqlite3_step(stmt) == SQLITE_ROW {
                    n = Int(sqlite3_column_int64(stmt, 0))
                }
                cont.resume(returning: n >= Self.commonThreshold)
            }
        }
    }
    
    
    func search(
        pattern: String,
        group: String?,
        limit: Int,
        before date: Date?,
        beforeID: String?
    ) async -> [String] {
        let common = await isCommon(pattern)
        var sql: String
        var binds: [Any] = [pattern]
        if common {
            sql = """
            SELECT t.ZID FROM ZMESSAGEENTITY t WHERE EXISTS
              (SELECT 1 FROM ZMESSAGE_FTS f WHERE f.rowid = t.Z_PK AND f.ZMESSAGE_FTS MATCH ?1)
            """
        } else {
            sql = """
            SELECT t.ZID FROM ZMESSAGEENTITY t
            WHERE t.Z_PK IN (SELECT rowid FROM ZMESSAGE_FTS WHERE ZMESSAGE_FTS MATCH ?1)
            """
        }
        if let group {
            sql += " AND t.ZGROUP = ?\(binds.count + 1)"
            binds.append(group)
        }
        if let date, let id = beforeID {
            // Core Data stores Date as timeIntervalSinceReferenceDate (REAL).
            let ts = date.timeIntervalSinceReferenceDate
            let base = binds.count
            sql += " AND ((t.ZCREATEDATE < ?\(base + 1)) OR (t.ZCREATEDATE = ?\(base + 2) AND t.ZID < ?\(base + 3)))"
            binds.append(ts); binds.append(ts); binds.append(id)
        }
        sql += " ORDER BY t.ZCREATEDATE DESC, t.ZID DESC LIMIT ?\(binds.count + 1)"
        binds.append(limit)

        nonisolated(unsafe) let args = binds
        return await withCheckedContinuation { cont in
            queue.async { [sql] in
                var ids: [String] = []
                guard let stmt = self.prepare(sql, args) else {
                    cont.resume(returning: [])
                    return
                }
                defer { sqlite3_finalize(stmt) }
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let c = sqlite3_column_text(stmt, 0) {
                        ids.append(String(cString: c))
                    }
                }
                cont.resume(returning: ids)
            }
        }
    }

    func count(pattern: String, group: String?) async -> Int {
        var sql = """
        SELECT COUNT(*) FROM (
          SELECT 1 FROM ZMESSAGEENTITY t
          WHERE t.Z_PK IN (SELECT rowid FROM ZMESSAGE_FTS WHERE ZMESSAGE_FTS MATCH ?1)
        """
        var binds: [Any] = [pattern]
        if let group {
            sql += " AND t.ZGROUP = ?\(binds.count + 1)"
            binds.append(group)
        }
        sql += " LIMIT \(Self.commonThreshold + 1))"
        nonisolated(unsafe) let args = binds
        return await withCheckedContinuation { cont in
            queue.async { [sql] in
                var total = 0
                guard let stmt = self.prepare(sql, args) else {
                    cont.resume(returning: 0)
                    return
                }
                defer { sqlite3_finalize(stmt) }
                if sqlite3_step(stmt) == SQLITE_ROW {
                    total = Int(sqlite3_column_int64(stmt, 0))
                }
                cont.resume(returning: total)
            }
        }
    }

    // MARK: - Index maintenance

    /// Remove the FTS rows matching the same set that is about to be bulk-deleted.
    /// Call BEFORE the Core Data delete so the base-table SELECT can read the old
    /// column values (external-content 'delete' requires them). One set-based
    /// statement — cheaper than both a per-row trigger and a full rebuild.
    ///
    /// Core Data stores Date as `timeIntervalSinceReferenceDate` (REAL); pass that.
    func deleteBulk(group: String? = nil, onlyRead: Bool = false, before interval: Double? = nil) {
        var whereSQL: [String] = []
        var binds: [Any] = []
        if let group {
            whereSQL.append("ZGROUP = ?\(binds.count + 1)")
            binds.append(group)
        }
        if onlyRead {
            whereSQL.append("ZREAD = 1")
        }
        if let interval {
            whereSQL.append("ZCREATEDATE < ?\(binds.count + 1)")
            binds.append(interval)
        }
        let clause = whereSQL.isEmpty ? "" : " WHERE " + whereSQL.joined(separator: " AND ")
        queue.sync {
            guard db != nil else { return }
            run("""
            INSERT INTO ZMESSAGE_FTS(ZMESSAGE_FTS, rowid, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL)
            SELECT 'delete', Z_PK, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL
            FROM ZMESSAGEENTITY\(clause)
            """, binds)
        }
    }

    /// Remove one message from the FTS index by its `id` (ZID). Call BEFORE the
    /// Core Data row is deleted so the SELECT can read the old column values (the
    /// external-content 'delete' command needs them). One indexed lookup, no trigger.
    func deleteMessage(id: String) {
        queue.sync {
            guard db != nil else { return }
            run("""
            INSERT INTO ZMESSAGE_FTS(ZMESSAGE_FTS, rowid, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL)
            SELECT 'delete', Z_PK, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL
            FROM ZMESSAGEENTITY WHERE ZID = ?
            """, [id])
        }
    }

    /// Rebuild the entire FTS index from the base table in one bulk scan. Kept for
    /// manual recovery; normal deletes use `deleteBulk`/`deleteMessage` instead.
    func rebuild() {
        queue.async { [self] in
            guard db != nil else { return }
            exec(Self.rebuildSQL)
        }
    }    /// Async variant: resolves only after the rebuild has finished, so a background
    /// task wrapping a bulk delete stays alive for the whole rebuild.
    func rebuildAwait() async {
        await withCheckedContinuation { cont in
            queue.async { [self] in
                if db != nil { exec(Self.rebuildSQL) }
                cont.resume()
            }
        }
    }
    // MARK: - FTS pattern

    /// True when every keyword is long enough for the trigram tokenizer (>=3 chars).
    static func canFTS(_ keywords: [String]) -> Bool {
        !keywords.isEmpty && keywords.allSatisfy { $0.count >= 3 }
    }

    /// Build an FTS5 MATCH expression: each keyword is a quoted phrase (substring
    /// match), space-joined so all keywords must appear (AND), matching the old
    /// OR-within-keyword / AND-between-keywords semantics.
    static func pattern(for keywords: [String]) -> String {
        keywords
            .map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
            .joined(separator: " ")
    }

    // MARK: - Short-keyword fallback (LIKE)

    /// Trigram can't index terms shorter than 3 characters, so 1-2 char keywords
    /// (CJK bigrams like "推送", short ASCII like "ok") can't use FTS. Run them as
    /// raw SQL LIKE on the FTS connection instead of a Core Data `CONTAINS[cd]`
    /// scan: the query walks `byCDID`/`byGCDID` newest-first and stops at LIMIT, so
    /// a common term returns in single-digit ms, and the count is capped like FTS.
    /// On 1M rows the Core Data path took 2-5s; this is ~200ms worst case.
    func searchLike(
        keywords: [String],
        group: String?,
        limit: Int,
        before date: Date?,
        beforeID: String?
    ) async -> [String] {
        var sql = "SELECT ZID FROM ZMESSAGEENTITY WHERE "
        sql += keywords.enumerated()
            .map { (i, _) in Self.likeORClause(bindIndex: i + 1) }
            .joined(separator: " AND ")
        var binds: [Any] = keywords.map { Self.likePattern($0) }
        if let group {
            sql += " AND ZGROUP = ?\(binds.count + 1)"
            binds.append(group)
        }
        if let date, let id = beforeID {
            let ts = date.timeIntervalSinceReferenceDate
            let base = binds.count
            sql += " AND ((ZCREATEDATE < ?\(base + 1)) OR (ZCREATEDATE = ?\(base + 2) AND ZID < ?\(base + 3)))"
            binds.append(ts); binds.append(ts); binds.append(id)
        }
        sql += " ORDER BY ZCREATEDATE DESC, ZID DESC LIMIT ?\(binds.count + 1)"
        binds.append(limit)

        nonisolated(unsafe) let args = binds
        return await withCheckedContinuation { cont in
            queue.async { [sql] in
                var ids: [String] = []
                guard let stmt = self.prepare(sql, args) else {
                    cont.resume(returning: [])
                    return
                }
                defer { sqlite3_finalize(stmt) }
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let c = sqlite3_column_text(stmt, 0) {
                        ids.append(String(cString: c))
                    }
                }
                cont.resume(returning: ids)
            }
        }
    }

    /// Capped LIKE count (mirrors `count(pattern:group:)`).
    func countLike(keywords: [String], group: String?) async -> Int {
        var sql = "SELECT COUNT(*) FROM (SELECT 1 FROM ZMESSAGEENTITY WHERE "
        sql += keywords.enumerated()
            .map { (i, _) in Self.likeORClause(bindIndex: i + 1) }
            .joined(separator: " AND ")
        var binds: [Any] = keywords.map { Self.likePattern($0) }
        if let group {
            sql += " AND ZGROUP = ?\(binds.count + 1)"
            binds.append(group)
        }
        sql += " LIMIT \(Self.commonThreshold + 1))"
        nonisolated(unsafe) let args = binds
        return await withCheckedContinuation { cont in
            queue.async { [sql] in
                var total = 0
                guard let stmt = self.prepare(sql, args) else {
                    cont.resume(returning: 0)
                    return
                }
                defer { sqlite3_finalize(stmt) }
                if sqlite3_step(stmt) == SQLITE_ROW {
                    total = Int(sqlite3_column_int64(stmt, 0))
                }
                cont.resume(returning: total)
            }
        }
    }

    private static func likeORClause(bindIndex: Int) -> String {
        "(ZTITLE LIKE ?\(bindIndex) ESCAPE '\\' OR ZSUBTITLE LIKE ?\(bindIndex) ESCAPE '\\' OR " +
        "ZBODY LIKE ?\(bindIndex) ESCAPE '\\' OR ZGROUP LIKE ?\(bindIndex) ESCAPE '\\' OR ZURL LIKE ?\(bindIndex) ESCAPE '\\')"
    }

    private static func likePattern(_ keyword: String) -> String {
        let escaped = keyword
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
        return "%\(escaped)%"
    }

    // MARK: - SQLite plumbing

    private func open(_ url: URL) -> Bool {
        if db != nil { return true }
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK, let db else {
            logger.error("FTS open failed: \(self.errorMessage())")
            return false
        }
        sqlite3_busy_timeout(db, 5000)
        return true
    }

    private func tableExists(_ name: String) -> Bool {
        guard let stmt = prepare(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
            [name]
        ) else { return false }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW
    }

    private func prepare(_ sql: String, _ binds: [Any]) -> OpaquePointer? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logger.error("FTS prepare failed: \(self.errorMessage()) — \(sql)")
            return nil
        }
        for (i, value) in binds.enumerated() {
            let idx = Int32(i + 1)
            switch value {
            case let s as String:
                sqlite3_bind_text(stmt, idx, s, -1, Self.transient)
            case let n as Int:
                sqlite3_bind_int64(stmt, idx, sqlite3_int64(n))
            case let d as Double:
                sqlite3_bind_double(stmt, idx, d)
            default:
                logger.error("FTS unsupported bind: \(value as! NSObject)")
            }
        }
        return stmt
    }

    private func exec(_ sql: String) {
        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            let msg = err.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(err)
            logger.error("FTS exec failed: \(msg)")
        }
    }

    /// Execute a single (possibly bound) statement via prepare/step. Used for the
    /// maintenance SELECT/INSERTs; `exec` remains for multi-statement DDL.
    private func run(_ sql: String, _ binds: [Any] = []) {
        guard let stmt = prepare(sql, binds) else { return }
        defer { sqlite3_finalize(stmt) }
        let rc = sqlite3_step(stmt)
        if rc != SQLITE_DONE && rc != SQLITE_ROW {
            let msg = errorMessage()
            logger.error("FTS run failed: \(msg) — \(sql)")
        }
    }

    private func errorMessage() -> String {
        guard let db, let c = sqlite3_errmsg(db) else { return "unknown" }
        return String(cString: c)
    }

    private static let transient = unsafeBitCast(
        OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self
    )

    // MARK: - Schema

    private static let createTableSQL = """
    CREATE VIRTUAL TABLE IF NOT EXISTS ZMESSAGE_FTS USING fts5(
        ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL,
        content='ZMESSAGEENTITY', content_rowid='Z_PK',
        tokenize='trigram'
    );
    """

    // INSERT/UPDATE are kept per-row (the app only ever upserts one row by id, so
    // they fire once). The DELETE trigger is intentionally absent: a per-row trigger
    // on a bulk delete (e.g. clearing all read messages) cost ~8x the plain DELETE.
    // Single-row deletes call deleteMessage(id:); bulk deletes call rebuild().
    private static let triggerSQL = """
    DROP TRIGGER IF EXISTS ZFTS_ad;
    CREATE TRIGGER IF NOT EXISTS ZFTS_ai AFTER INSERT ON ZMESSAGEENTITY BEGIN
      INSERT INTO ZMESSAGE_FTS(rowid, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL)
      VALUES (new.Z_PK, new.ZTITLE, new.ZSUBTITLE, new.ZBODY, new.ZGROUP, new.ZURL);
    END;
    CREATE TRIGGER IF NOT EXISTS ZFTS_au AFTER UPDATE ON ZMESSAGEENTITY BEGIN
      INSERT INTO ZMESSAGE_FTS(rowid, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL)
      VALUES('delete', old.Z_PK, old.ZTITLE, old.ZSUBTITLE, old.ZBODY, old.ZGROUP, old.ZURL);
      INSERT INTO ZMESSAGE_FTS(rowid, ZTITLE, ZSUBTITLE, ZBODY, ZGROUP, ZURL)
      VALUES (new.Z_PK, new.ZTITLE, new.ZSUBTITLE, new.ZBODY, new.ZGROUP, new.ZURL);
    END;
    """

    private static let rebuildSQL = """
    INSERT INTO ZMESSAGE_FTS(ZMESSAGE_FTS) VALUES('rebuild');
    """

    // Regular indexes on the Core Data table. Created here (not via the .xcdatamodel)
    // because Core Data's entity version hash ignores fetch indexes, so adding one
    // there doesn't trigger a migration and the index silently never exists.
    // byReadGroup makes the unread-per-group GROUP BY an index-only lookup instead
    // of a 1M-row table scan (~52s -> ~0.1ms on the stress dataset).
    private static let indexSQL = """
    CREATE INDEX IF NOT EXISTS byID ON ZMESSAGEENTITY(ZID);
    CREATE INDEX IF NOT EXISTS byCDID ON ZMESSAGEENTITY(ZCREATEDATE,ZID);
    CREATE INDEX IF NOT EXISTS byGCDID ON ZMESSAGEENTITY(ZGROUP,ZCREATEDATE,ZID);
    CREATE INDEX IF NOT EXISTS byReadGroup ON ZMESSAGEENTITY(ZREAD,ZGROUP);
    """
}
