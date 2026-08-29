//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - JSRuntime.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: Sandboxed JavaScript runtime (fetch/timers/crypto) used by
//  TTS and message scripts.

//  History:
//    Created by Neo on 2026/8/10 22:07.

import CryptoKit
import Foundation
@preconcurrency import JavaScriptCore
import os

public final class JSRuntime: @unchecked Sendable {
    public typealias ArgsType = [Any]

    private static let logger = Logger(subsystem: "app.wzs.logger", category: "JSRuntime")

    public typealias NativeMethod = @convention(block) ([Any]) -> Any?

    let context = JSContext()!
    public let jsQueue = DispatchQueue(label: "js.runtime")

    public private(set) var entry: JSValue!

    private static let queueKey = DispatchSpecificKey<Void>()

    private var timers: [Int: DispatchSourceTimer] = [:]
    private var timerSeq = 0

    private let namespace: String

    public init(
        scriptSource source: String = "",
        namespace: String = "default",
        exceptionHandler: ((String) -> Void)? = nil,
        methods: [String: Any] = [:]
    ) {
        self.namespace = namespace
        if logHandler == nil {
            logHandler = { level, message in
                Self.logger.log("[\(level, privacy: .public)] \(message, privacy: .public)")
            }
        }
        jsQueue.setSpecific(key: Self.queueKey, value: ())
        context.exceptionHandler = { _, exc in
            if let exc {
                let msg = exc.toString() ?? "?"
                exceptionHandler?(msg)
                Self.logger.error("JS exception: \(msg, privacy: .public)")
            }
            
        }
        injectNative()
        context.evaluateScript(Self.polyfill)

        for (key, value) in methods {
            if let asyncMethod = value as? AsyncNativeMethod {
                registerAsyncMethod(key: key, method: asyncMethod)
            } else {
                context.setObject(value, forKeyedSubscript: key as NSString)
            }
        }
        entry = jsQueue.sync {
            context.evaluateScript(source) ?? JSValue(undefinedIn: context)
        }
    }

    deinit {
        timers.values.forEach { $0.cancel() }
        timers.removeAll()
    }

    @discardableResult
    func runSync<T>(_ block: () -> T) -> T {
        if DispatchQueue.getSpecific(key: Self.queueKey) != nil { return block() }
        return jsQueue.sync(execute: block)
    }

    @discardableResult
    public func evaluate(_ script: String) -> JSValue? {
        jsQueue.sync { context.evaluateScript(script) }
    }

    public func perform(_ block: @escaping @Sendable (JSContext) -> Void) {
        jsQueue.async { block(self.context) }
    }

    public func sync<T>(_ block: (JSContext) -> T) -> T {
        jsQueue.sync { block(context) }
    }

    public func setObject(_ object: Any?, forKey key: String) {
        jsQueue.sync { context.setObject(object, forKeyedSubscript: key as NSString) }
    }

    // MARK: Validation
    public struct ValidationResult: Sendable {
        public let ok: Bool
        public let message: String?
    }

    @discardableResult
    public static func validate(
        _ script: String,
        args: [Any],
        timeout: TimeInterval = 10
    ) async -> ValidationResult {
        let probe = JSContext()!
        let jsStr = JSStringCreateWithCFString(script as CFString)
        defer { JSStringRelease(jsStr) }
        var exc: JSValueRef?
        guard JSCheckScriptSyntax(probe.jsGlobalContextRef, jsStr, nil, 0, &exc) else {
            let msg = exc.flatMap { JSValue(jsValueRef: $0, in: probe) }?.toString()
            return ValidationResult(ok: false, message: msg ?? String(localized: "语法错误"))
        }

        let runtime = JSRuntime(scriptSource: script, namespace: "__validation__")
        runtime.callTimeout = timeout
        runtime.logHandler = nil

        guard runtime.entry.isObject,
              isFunction(runtime.entry, ctx: runtime.context.jsGlobalContextRef)
        else {
            return ValidationResult(
                ok: false,
                message: String(localized: "脚本最后一个表达式必须是一个函数")
            )
        }

        do {
            _ = try await runtime.call(arguments: args)
            return ValidationResult(ok: true, message: nil)
        } catch CallError.rejected(let message) {
            return ValidationResult(ok: true, message: message)
        } catch CallError.timedOut {
            return ValidationResult(
                ok: false,
                message: String(localized: "脚本执行超时")
            )
        } catch {
            return ValidationResult(ok: false, message: "\(error)")
        }
    }

    public enum CallError: Error {
        case notAPromise
        case rejected(message: String)
        case timedOut
    }

    public var callTimeout: TimeInterval = 15

    public var logHandler: ((_ level: String, _ message: String) -> Void)?

    static func isFunction(_ value: JSValue, ctx: JSGlobalContextRef) -> Bool {
        guard value.isObject else { return false }
        return JSObjectIsFunction(ctx, value.jsValueRef)
    }

    @discardableResult
    public func call(arguments: ArgsType = []) async throws -> Any? {
        try await withCheckedThrowingContinuation { cont in
            runSync {
                let result: JSValue?
                if Self.isFunction(self.entry, ctx: self.context.jsGlobalContextRef) {
                    result = self.entry.call(withArguments: arguments)
                } else {
                    result = self.entry
                }
                guard let result else {
                    cont.resume(throwing: CallError.notAPromise); return
                }
                Self.resolveAny(
                    result,
                    ctx: self.context.jsGlobalContextRef,
                    timeout: self.callTimeout,
                    on: self.jsQueue
                ) {
                    cont.resume(with: $0.map { $0.value })
                }
            }
        }
    }

    static func resolveAny(
        _ result: JSValue,
        ctx _: JSGlobalContextRef,
        timeout: TimeInterval,
        on queue: DispatchQueue,
        resume: @escaping @Sendable (Result<AnyBox, Error>) -> Void
    ) {
        let once = OnceGuardAny(resume)

        let bridge: (JSValue) -> AnyBox = { AnyBox($0.toSendable()) }

        if result.isObject,
           let then = result.objectForKeyedSubscript("then"),
           isFunction(then, ctx: result.context.jsGlobalContextRef)
        {
            let onFulfilled: @convention(block) (JSValue)
                -> Void = { once.fire(.success(bridge($0))) }
            let onRejected: @convention(block) (JSValue) -> Void = {
                once.fire(.failure(CallError.rejected(message: $0.errorMessage)))
            }
            result.invokeMethod("then", withArguments: [onFulfilled, onRejected])
            queue.asyncAfter(deadline: .now() + timeout) {
                once.fire(.failure(CallError.timedOut))
            }
        } else {
            once.fire(.success(bridge(result)))
        }
    }

    struct AnyBox: @unchecked Sendable {
        let value: Any?
        init(_ value: Any?) { self.value = value }
    }

    final private class OnceGuardAny: @unchecked Sendable {
        private let lock = OSAllocatedUnfairLock()
        private var settled = false
        private let resume: @Sendable (Result<AnyBox, Error>) -> Void
        init(_ resume: @escaping @Sendable (Result<AnyBox, Error>) -> Void) { self.resume = resume }
        func fire(_ outcome: Result<AnyBox, Error>) {
            lock.lock()
            defer { lock.unlock() }
            guard !settled else { return }
            settled = true
            resume(outcome)
        }
    }

    static func copyBytes(_ value: JSValue) -> Data? {
        guard value.isObject else { return nil }
        let ctx = value.context.jsGlobalContextRef
        let obj = value.jsValueRef
        var exc: JSValueRef?
        guard let ptr = JSObjectGetTypedArrayBytesPtr(ctx, obj, &exc),
              exc == nil
        else { return nil }
        let len = JSObjectGetTypedArrayLength(ctx, obj, &exc)
        guard exc == nil else { return nil }
        if len == 0 { return Data() }
        return Data(bytes: ptr, count: len)
    }

    private func registerAsyncMethod(key: String, method: @escaping AsyncNativeMethod) {
        final class Work: @unchecked Sendable {
            let method: AsyncNativeMethod
            let cb: CallbackBox
            let args: [Any?]
            init(method: @escaping AsyncNativeMethod, cb: CallbackBox, args: [Any?]) {
                self.method = method; self.cb = cb; self.args = args
            }
            func run() {
                let m = method, cb = self.cb, args = self.args
                Task.detached {
                    do { cb.resolve(try await m(args)) }
                    catch { cb.reject(error.localizedDescription) }
                }
            }
        }
        final class CallbackBox: @unchecked Sendable {
            let resolve: JSValue
            let reject: JSValue
            let queue: DispatchQueue
            init(resolve: JSValue, reject: JSValue, queue: DispatchQueue) {
                self.resolve = resolve; self.reject = reject; self.queue = queue
            }
            func resolve(_ value: Any?) {
                nonisolated(unsafe) let v = value
                queue.async { self.resolve.call(withArguments: [v as Any]) }
            }
            func reject(_ message: String) {
                queue.async { self.reject.call(withArguments: [message as NSString]) }
            }
        }
        let native: @convention(block) (JSValue, JSValue, [JSValue]) -> Void = { resolve, reject, args in
            let extracted: [Any?] = args.map { $0.toSendable() }
            let cb = CallbackBox(resolve: resolve, reject: reject, queue: self.jsQueue)
            Work(method: method, cb: cb, args: extracted).run()
        }
        let internalName = "_\(key)Async"
        context.setObject(native, forKeyedSubscript: internalName as NSString)
        context.evaluateScript("""
        globalThis.\(key) = function () {
          return new Promise(function (resolve, reject) {
            \(internalName)(resolve, reject, Array.prototype.slice.call(arguments));
          });
        };
        """)
    }

    private func injectNative() {
        let http: @convention(block) (String, String, JSValue)
            -> Void = { [weak self] url, optsJSON, cb in
                guard let self else { return }
                self.performHTTP(url: url, optsJSON: optsJSON) { result in
                    self.jsQueue.async {
                        cb.call(withArguments: [result.err as Any, result.value as Any])
                    }
                }
            }
        context.setObject(http, forKeyedSubscript: "_httpNative" as NSString)

        let timerAdd: @convention(block) (JSValue, Double, Bool)
            -> Int = { [weak self] cb, ms, repeats in
                guard let self else { return -1 }
                return self.addTimer(cb: cb, ms: max(0, Int(ms)), repeats: repeats)
            }
        context.setObject(timerAdd, forKeyedSubscript: "_timerAdd" as NSString)

        let timerClear: @convention(block) (Int) -> Void = { [weak self] id in
            self?.cancelTimer(id)
        }
        context.setObject(timerClear, forKeyedSubscript: "_timerClear" as NSString)

        let randomBytes: @convention(block) (Int) -> String = { n in
            var b = [UInt8](repeating: 0, count: max(0, n))
            arc4random_buf(&b, b.count)
            return Data(b).base64EncodedString()
        }
        context.setObject(randomBytes, forKeyedSubscript: "_randomBytesB64" as NSString)

        let nowMs: @convention(block) () -> Double = {
            ProcessInfo.processInfo.systemUptime * 1000.0
        }
        context.setObject(nowMs, forKeyedSubscript: "_nowMs" as NSString)

        let hmac: @convention(block) (String, String) -> String = { keyB64, message in
            guard let key = Data(base64Encoded: keyB64) else { return "" }
            let mac = HMAC<SHA256>.authenticationCode(
                for: Data(message.utf8), using: SymmetricKey(data: key)
            )
            return Data(mac).base64EncodedString()
        }
        context.setObject(hmac, forKeyedSubscript: "_hmacSha256Base64" as NSString)

        let log: @convention(block) (String, String) -> Void = { [weak self] level, message in
            self?.logHandler?(level, message)
        }
        context.setObject(log, forKeyedSubscript: "_logNative" as NSString)

        let store: @convention(block) (String, String, JSValue)
            -> JSValue? = { [weak self] op, key, value in
                self?.storage(op: op, key: key, value: value)
            }
        context.setObject(store, forKeyedSubscript: "_storageNative" as NSString)
    }

    private func storage(op: String, key: String, value: JSValue) -> JSValue? {
        let defaults = NCONFIG.defaultStore()
        let storeKey = "jsrt.\(namespace).\(key)"

        switch op {
        case "remove":
            defaults.removeObject(forKey: storeKey)
            return nil
        case "set":
            if value.isUndefined || value.isNull {
                defaults.removeObject(forKey: storeKey)
                return nil
            }
            if let data = value.bytes {
                defaults.set(data, forKey: storeKey)
            } else if value.isString, let s = value.toString() {
                defaults.set(s, forKey: storeKey)
            } else if value.isBoolean {
                defaults.set(value.toBool(), forKey: storeKey)
            } else if value.isNumber, let n = value.toNumber() {
                defaults.set(n, forKey: storeKey)
            } else if value.isObject,
                      let json = context.objectForKeyedSubscript("JSON")?
                          .objectForKeyedSubscript("stringify")?
                          .call(withArguments: [value]),
                      json.isString, let str = json.toString()
            {
                defaults.set(str, forKey: storeKey)
            }
            return nil
        case "get":
            guard let raw = defaults.object(forKey: storeKey) else {
                return JSValue(nullIn: context)
            }
            if let data = raw as? Data,
               let uint8 = context.evaluateScript("Uint8Array")
            {
                return uint8.construct(withArguments: [data as NSData])
            }
            if let str = raw as? String,
               let json = context.objectForKeyedSubscript("JSON")?
                   .objectForKeyedSubscript("parse")?
                   .call(withArguments: [str]),
               !json.isUndefined
            {
                return json
            }
            return JSValue(object: raw, in: context)
        default:
            return nil
        }
    }

    private func addTimer(cb: JSValue, ms: Int, repeats: Bool) -> Int {
        timerSeq += 1
        let id = timerSeq
        let t = DispatchSource.makeTimerSource(queue: jsQueue)
        let interval: DispatchTimeInterval = .milliseconds(ms)
        t.schedule(deadline: .now() + interval, repeating: repeats ? interval : .never)
        t.setEventHandler { [weak self] in
            cb.call(withArguments: [])
            if !repeats { self?.cancelTimer(id) }
        }
        timers[id] = t
        t.resume()
        return id
    }

    private func cancelTimer(_ id: Int) {
        timers.removeValue(forKey: id)?.cancel()
    }

    // MARK: HTTP

    private struct NativeResult: @unchecked Sendable { let err: String?; let value: [String: Any]? }

    private func performHTTP(
        url urlStr: String,
        optsJSON: String,
        completion: @escaping @Sendable (NativeResult) -> Void
    ) 
    {
        guard let url = URL(string: urlStr) else {
            completion(NativeResult(err: "invalid url: \(urlStr)", value: nil)); return
        }

        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            completion(NativeResult(err: "only http/https urls are allowed", value: nil)); return
        }
        struct Opts: Decodable {
            var method: String?
            var headers: [String: String]?
            var bodyB64: String?
        }
        guard let data = optsJSON.data(using: .utf8),
              let opts = try? JSONDecoder().decode(Opts.self, from: data)
        else {
            completion(NativeResult(err: "invalid opts", value: nil)); return
        }

        var req = URLRequest(url: url)
        req.httpMethod = opts.method ?? "GET"
        let forbidden: Set<String> = [
            "host", "content-length", "connection", "transfer-encoding",
            "expect", "proxy-connection", "keep-alive", "te", "trailer", "upgrade",
        ]
        if let badHeader = opts.headers?.first(where: { forbidden.contains($0.key.lowercased()) }) {
            completion(NativeResult(
                err: "header '\(badHeader.key)' is not allowed",
                value: nil
            )); return
        }
        opts.headers?.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let b64 = opts.bodyB64, let body = Data(base64Encoded: b64) {
            req.httpBody = body
        }
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                completion(NativeResult(err: error.localizedDescription, value: nil)); return
            }
            let http = response as? HTTPURLResponse
            var headers: [String: String] = [:]
            http?.allHeaderFields.forEach { headers["\($0.key)"] = "\($0.value)" }
            completion(NativeResult(err: nil, value: [
                "status": http?.statusCode ?? 0,
                "headers": headers,
                "bodyB64": (data ?? Data()).base64EncodedString(),
            ]))
        }.resume()
    }

    // MARK: Polyfill

    static let polyfill = #"""
    (function (global, native) {
      "use strict";

      // ---------- base64 (binary-string variant) ----------
      var B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      function btoa(input) {
        var out = "", i = 0;
        while (i < input.length) {
          var c1 = input.charCodeAt(i++) & 0xff;
          var c2 = i < input.length ? input.charCodeAt(i++) & 0xff : -1;
          var c3 = i < input.length ? input.charCodeAt(i++) & 0xff : -1;
          out += B64[c1 >> 2];
          out += B64[((c1 & 3) << 4) | (c2 < 0 ? 0 : c2 >> 4)];
          out += c2 < 0 ? "=" : B64[((c2 & 15) << 2) | (c3 < 0 ? 0 : c3 >> 6)];
          out += c3 < 0 ? "=" : B64[c3 & 63];
        }
        return out;
      }
      function atob(input) {
        input = String(input).replace(/[^A-Za-z0-9+/=]/g, "");
        var out = "", i = 0;
        while (i < input.length) {
          var e1 = B64.indexOf(input.charAt(i++));
          var e2 = B64.indexOf(input.charAt(i++));
          var e3 = B64.indexOf(input.charAt(i++));
          var e4 = B64.indexOf(input.charAt(i++));
          var c1 = (e1 << 2) | (e2 >> 4);
          var c2 = ((e2 & 15) << 4) | (e3 >> 2);
          var c3 = ((e3 & 3) << 6) | e4;
          out += String.fromCharCode(c1);
          if (e3 >= 0) out += String.fromCharCode(c2);
          if (e4 >= 0) out += String.fromCharCode(c3);
        }
        return out;
      }
      function bytesToB64(u8) {
        var s = ""; for (var i=0;i<u8.length;i++) s += String.fromCharCode(u8[i]); return btoa(s);
      }
      function b64ToBytes(b64) {
        var s = atob(b64), u8 = new Uint8Array(s.length);
        for (var i=0;i<s.length;i++) u8[i] = s.charCodeAt(i) & 0xff; return u8;
      }
      global.btoa = btoa; global.atob = atob;

      // ---------- timers ----------
      global.setTimeout = function (fn, ms) {
        return native.timerAdd(fn, (ms === undefined ? 0 : ms) | 0, false);
      };
      global.setInterval = function (fn, ms) {
        return native.timerAdd(fn, (ms === undefined ? 0 : ms) | 0, true);
      };
      global.clearTimeout = global.clearInterval = function (id) { native.timerClear(id); };

      global.queueMicrotask = function (fn) { Promise.resolve().then(fn); };

      // ---------- performance ----------
      var start = native.nowMs();
      global.performance = { now: function () { return native.nowMs() - start; } };

      // ---------- UTF-8 ----------
      global.TextEncoder = function () {};
      global.TextEncoder.prototype.encode = function (str) {
        // Manual UTF-8 encoder.
        var u8 = [];
        for (var i = 0; i < str.length; i++) {
          var c = str.charCodeAt(i);
          if (c < 0x80) u8.push(c);
          else if (c < 0x800) u8.push(0xC0 | (c >> 6), 0x80 | (c & 0x3F));
          else if (c >= 0xD800 && c <= 0xDBFF) { // surrogate pair
            var c2 = str.charCodeAt(++i);
            var cp = 0x10000 + (((c & 0x3FF) << 10) | (c2 & 0x3FF));
            u8.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F),
                    0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
          } else u8.push(0xE0 | (c >> 12), 0x80 | ((c >> 6) & 0x3F), 0x80 | (c & 0x3F));
        }
        return new Uint8Array(u8);
      };
      global.TextEncoder.prototype.encoding = "utf-8";

      global.TextDecoder = function (label) {
        var enc = (label || "utf-8").toLowerCase();
        // Only UTF-8 is implemented; the spec requires a RangeError for the rest
        // instead of silently mis-decoding, so script bugs surface immediately.
        if (["utf-8","utf8","unicode-1-1-utf-8","unicode11utf8","unicode20utf8","x-unicode20utf8"].indexOf(enc) < 0) {
          throw new RangeError("Unsupported encoding: " + label);
        }
        this.encoding = "utf-8";
      };
      global.TextDecoder.prototype.decode = function (view) {
        var u8 = view instanceof Uint8Array ? view : new Uint8Array(view);
        var out = "", i = 0;
        while (i < u8.length) {
          var b1 = u8[i++];
          if (b1 < 0x80) { out += String.fromCharCode(b1); continue; }
          var b2 = u8[i++] & 0x3F;
          if (b1 < 0xE0) { out += String.fromCharCode(((b1 & 0x1F) << 6) | b2); continue; }
          var b3 = u8[i++] & 0x3F;
          if (b1 < 0xF0) { out += String.fromCharCode(((b1 & 0x0F) << 12) | (b2 << 6) | b3); continue; }
          var b4 = u8[i++] & 0x3F;
          var cp = ((b1 & 0x07) << 18) | (b2 << 12) | (b3 << 6) | b4;
          cp -= 0x10000;
          out += String.fromCharCode(0xD800 | (cp >> 10), 0xDC00 | (cp & 0x3FF));
        }
        return out;
      };
      var enc = new global.TextEncoder();
      var dec = new global.TextDecoder();
      function utf8ToB64(s) { return bytesToB64(enc.encode(s)); }

      // ---------- URLSearchParams ----------
      global.URLSearchParams = function (init) {
        this._p = [];
        if (typeof init === "string") {
          init = init.replace(/^\?/, "");
          if (init) init.split("&").forEach(function (kv) {
            var t = kv.split("=");
            this._p.push([decodeURIComponent(t[0] || ""), decodeURIComponent(t[1] || "")]);
          }, this);
        } else if (Array.isArray(init)) {
          init.forEach(function (kv) { this._p.push([kv[0], kv[1]]); }, this);
        } else if (init && typeof init === "object") {
          Object.keys(init).forEach(function (k) { this._p.push([k, init[k]]); }, this);
        }
      };
      var USP = global.URLSearchParams.prototype;
      USP.append = function (k, v) { this._p.push([String(k), String(v)]); };
      USP.get = function (k) { k = String(k); for (var i=0;i<this._p.length;i++) if (this._p[i][0]===k) return this._p[i][1]; return null; };
      USP.has = function (k) { k = String(k); return this._p.some(function (p) { return p[0] === k; }); };
      USP.set = function (k, v) { k = String(k); var found=false; this._p = this._p.filter(function(p){ if(p[0]===k){ if(found) return false; found=true; p[1]=String(v);} return true; }); if(!found) this._p.push([k,String(v)]); };
      USP.delete = function (k) { k = String(k); this._p = this._p.filter(function (p) { return p[0] !== k; }); };
      USP.forEach = function (fn) { this._p.forEach(function (p) { fn(p[1], p[0], this); }, this); };
      USP.toString = function () {
        return this._p.map(function (p) { return encodeURIComponent(p[0]) + "=" + encodeURIComponent(p[1]); }).join("&");
      };

      // ---------- URL (absolute + basic same-origin relative) ----------
      function resolvePath(basePath, rel) {
        var stack;
        if (rel[0] === "/") { stack = []; }
        else { stack = basePath.split("/"); stack.pop(); }
        rel.split("/").forEach(function (seg) {
          if (seg === "..") { if (stack.length > 1) stack.pop(); }
          else if (seg !== "." && seg !== "") { stack.push(seg); }
        });
        // Drop only the leading "" from splitting an absolute path.
        if (stack[0] === "") stack.shift();
        // Preserve a trailing slash (directory semantics): a base of "/x/y/"
        // must resolve "z" to "/x/y/z", while "/x/y" resolves it to "/x/z".
        var result = "/" + stack.join("/");
        if (rel.charAt(rel.length - 1) === "/") result += "/";
        return result;
      }
      global.URL = function (url, base) {
        var m;
        if (base && !/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(url)) {
          var b = new global.URL(base);
          if (url.substr(0,2) === "//") { url = b.protocol + url; }
          else if (url[0] === "/") { url = b.protocol + "//" + b.host + url; }
          else if (url[0] === "?" || url[0] === "#") { url = b.protocol + "//" + b.host + b.pathname + url; }
          else {
            url = b.protocol + "//" + b.host + resolvePath(b.pathname, url);
          }
        }
        m = url.match(/^([a-zA-Z][a-zA-Z0-9+.-]*:)?\/\/([^/?#]*)([^?#]*)(\?[^#]*)?(#.*)?/);
        if (!m) throw new TypeError("Invalid URL: " + url);
        this.protocol = m[1] || "https:";
        this.host = m[2] || ""; this.hostname = this.host.split("@").pop().split(":")[0];
        this.port = (this.host.split(":")[1] || "");
        this.pathname = resolvePath("/", m[3] || "/");
        this.search = m[4] || "";
        this.hash = m[5] || "";
        this.username = ""; this.password = "";
        this.origin = this.protocol + "//" + this.host;
        this.searchParams = new global.URLSearchParams(this.search.slice(1));
      };
      global.URL.prototype.toString = function () {
        return this.protocol + "//" + this.host + this.pathname +
          (this.searchParams.toString() ? "?" + this.searchParams.toString() : "") + this.hash;
      };

      // ---------- crypto ----------
      global.crypto = {
        getRandomValues: function (arr) {
          var bytes = b64ToBytes(native.randomBytes(arr.byteLength));
          new Uint8Array(arr.buffer, arr.byteOffset, arr.byteLength).set(bytes);
          return arr;
        },
        randomUUID: function () {
          var b = b64ToBytes(native.randomBytes(16));
          b[6] = (b[6] & 0x0f) | 0x40;
          b[8] = (b[8] & 0x3f) | 0x80;
          var h = function (x) { return ("00" + x.toString(16)).slice(-2); };
          return h(b[0])+h(b[1])+h(b[2])+h(b[3])+"-"+h(b[4])+h(b[5])+"-"+h(b[6])+h(b[7])+
                 "-"+h(b[8])+h(b[9])+"-"+h(b[10])+h(b[11])+h(b[12])+h(b[13])+h(b[14])+h(b[15]);
        },
        // HMAC-SHA256 signature helper (key/message base64) -> base64.
        _hmacSha256Base64: typeof _hmacSha256Base64 !== "undefined" ? _hmacSha256Base64 : function () { return ""; }
      };

      global.structuredClone = function (v) { return JSON.parse(JSON.stringify(v)); };

      // ---------- fetch / Headers / Response / AbortController ----------
      function Headers(init) {
        this._m = {};
        var self = this;
        if (init instanceof global.Headers) { init.forEach(function (v,k){ self.append(k,v); }); }
        else if (Array.isArray(init)) { init.forEach(function (kv) { self.append(kv[0], kv[1]); }); }
        else if (init && typeof init === "object") { Object.keys(init).forEach(function (k){ self.append(k, init[k]); }); }
      }
      Headers.prototype.append = function (k, v) {
        k = String(k).toLowerCase();
        this._m[k] = this._m[k] ? this._m[k] + ", " + v : String(v);
      };
      Headers.prototype.set = function (k, v) { this._m[String(k).toLowerCase()] = String(v); };
      Headers.prototype.get = function (k) { var v = this._m[String(k).toLowerCase()]; return v === undefined ? null : v; };
      Headers.prototype.has = function (k) { return String(k).toLowerCase() in this._m; };
      Headers.prototype.forEach = function (fn) {
        Object.keys(this._m).forEach(function (k) { fn(this._m[k], k, this); }, this);
      };
      global.Headers = Headers;

      function Response(val) {
        this.status = val.status | 0;
        this.ok = this.status >= 200 && this.status < 300;
        this.statusText = "";
        this.headers = new Headers(val.headers || {});
        this.url = val.url || "";
        this._b64 = val.bodyB64 || "";
        this._used = false;
      }
      function consume(r) {
        if (r._used) return Promise.reject(new TypeError("body already used"));
        r._used = true; return Promise.resolve(b64ToBytes(r._b64));
      }
      Response.prototype.arrayBuffer = function () { var self = this; return consume(self).then(function (u) {
        // return a fresh, detached ArrayBuffer
        var copy = new Uint8Array(u.byteLength); copy.set(u); return copy.buffer;
      }); };
      Response.prototype.text = function () { var self = this; return consume(self).then(function (u) { return dec.decode(u); }); };
      Response.prototype.json = function () { var self = this; return self.text().then(function (t) { return JSON.parse(t); }); };
      global.Response = Response;

      global.AbortController = function () {
        this.signal = {
          aborted: false,
          _listeners: { abort: [] },
          addEventListener: function (t, fn) { (this._listeners[t] = this._listeners[t] || []).push(fn); },
          removeEventListener: function (t, fn) {
            this._listeners[t] = (this._listeners[t] || []).filter(function (f) { return f !== fn; });
          }
        };
      };
      global.AbortController.prototype.abort = function () {
        if (this.signal.aborted) return;
        this.signal.aborted = true;
        (this.signal._listeners.abort || []).forEach(function (fn) { fn({ type: "abort" }); });
      };

      global.fetch = function (input, init) {
        init = init || {};
        var url = typeof input === "string" ? input : (input && input.url) || String(input);
        var method = (init.method || "GET").toUpperCase();
        var headers = new Headers(init.headers || (input && input.headers));
        var body = init.body;
        var signal = init.signal || null;

        var bodyB64 = null;
        if (body != null) {
          if (typeof body === "string") bodyB64 = utf8ToB64(body);
          else if (body instanceof Uint8Array) bodyB64 = bytesToB64(body);
          else if (body instanceof ArrayBuffer) bodyB64 = bytesToB64(new Uint8Array(body));
          else bodyB64 = utf8ToB64(String(body));
          if (!headers.has("content-type")) headers.set("content-type", "text/plain;charset=UTF-8");
        }

        var headerObj = {};
        
        headers.forEach(function (v, k) { headerObj[k] = v; });

        return new Promise(function (resolve, reject) {
          if (signal && signal.aborted) { reject(new DOMException("aborted", "AbortError")); return; }
          var settled = false;
          function onAbort() { if (settled) return; settled = true; reject(new DOMException("aborted", "AbortError")); }
          if (signal) signal.addEventListener("abort", onAbort);

          native.http(url, JSON.stringify({ method: method, headers: headerObj, bodyB64: bodyB64 }),
            function (err, val) {
              if (settled) return; settled = true;
              if (signal) signal.removeEventListener("abort", onAbort);
              if (err) { reject(new TypeError(err)); return; }
              val.url = url;
              resolve(new Response(val));
            });
        });
      };

      // Minimal DOMException for AbortError.
      if (typeof global.DOMException !== "function") {
        global.DOMException = function (msg, name) { this.message = msg; this.name = name; };
        global.DOMException.prototype = Object.create(Error.prototype);
      }

      // ---------- console ----------
      function fmt(arg) {
        if (arg === null) return "null";
        if (arg === undefined) return "undefined";
        if (typeof arg === "string") return arg;
        if (arg instanceof Error) {
          // JSC's stack omits the "name: message" header that V8 includes;
          // prepend it so the message is never lost.
          var head = arg.name + ": " + arg.message;
          if (arg.stack && arg.stack.indexOf(arg.message) < 0) return head + "\n" + arg.stack;
          return arg.stack || head;
        }
        try { return JSON.stringify(arg); } catch (_) { return String(arg); }
      }
      global.console = {
        _log: function (level, args) {
          native.log(level, Array.prototype.map.call(args, fmt).join(" "));
        }
      };
      ["log","info","debug","warn","error"].forEach(function (level) {
        global.console[level] = function () { global.console._log(level, arguments); };
      });

      // ---------- persistent KV storage ----------
      // Script-isolated (the native side namespaces by source hash); values
      // survive across app launches. Numbers, strings, booleans, plain
      // objects/arrays (JSON) and ArrayBuffer/Uint8Array are supported.
      global.storage = {
        get: function (key) {
          var v = native.storage("get", String(key), null);
          return v === null ? null : v;
        },
        set: function (key, value) {
          native.storage("set", String(key), value === undefined ? null : value);
        },
        remove: function (key) { native.storage("remove", String(key), null); }
      };
    })(typeof globalThis !== "undefined" ? globalThis : this, {
      http: _httpNative,
      timerAdd: _timerAdd,
      timerClear: _timerClear,
      randomBytes: _randomBytesB64,
      nowMs: _nowMs,
      log: _logNative,
      storage: _storageNative
    });
    """#
}

final class ScriptManager: @unchecked Sendable {
    static let shared = ScriptManager()

    private init() {}

    func delete(_ data: ScriptData) {
        try? FileManager.default.removeItem(at: data.file)
        Defaults[.scripts].remove(data)
    }

    func filePath(_ name: String) -> URL? {
        let fileName = name.hasPrefix(".js") ? name : name + ".js"

        if let name = NCONFIG.Path(.scripts, fileName),
           FileManager.default.fileExists(atPath: name.path())
        {
            return name
        }

        return nil
    }

    func defaultPath(_ name: String? = nil, mode: ScriptData.Mode) -> URL? {
        if let name = name?.deletingPathExtension,
           let data = Defaults[.scripts].first(where: { $0.name == name && $0.mode == mode })
        {
            return data.file
        }

        if mode == .tts {
            return Defaults[.scripts].first(where: { $0.mode == mode })?.file
        }

        return nil
    }

    private var speakRun: JSRuntime?

    @discardableResult
    func processorHandler(_ name: String, args: [Any]) async -> Any? {
        guard let path = self.defaultPath(name, mode: .processor),
              let source = try? String(contentsOf: path, encoding: .utf8)
        else {
            return nil
        }
        let msgRun = JSRuntime(scriptSource: source, namespace: "MsgManager")

        return try? await msgRun.call(arguments: args)
    }

    func speak(
        _ name: String? = nil,
        params: [AnyHashable: Any]
    ) async -> (String, Data?) {
        guard let path = self.defaultPath(name, mode: .tts),
              let source = try? String(contentsOf: path, encoding: .utf8)
        else {
            return ("no script!", nil)
        }

        if self.speakRun == nil {
            self.speakRun = JSRuntime(scriptSource: source, namespace: "TTSManager")
        }

        do {
            if let data = try await self.speakRun?.call(arguments: [params]) as? Data {
                return ("", data)
            }
            return ("run error!", nil)
        } catch {
            return (error.localizedDescription, nil)
        }
    }

    @discardableResult
    func actionHandler(
        _ name: String,
        params: [AnyHashable: Any]
    ) async -> Result<Any?, Error> {
        guard let path = self.defaultPath(name, mode: .action),
              let source = try? String(contentsOf: path, encoding: .utf8)
        else {
            return .failure(NoletError("no script"))
        }

        let manager = JSRuntime(scriptSource: source, namespace: "TTSManager")
        do {
            return try .success(await manager.call(arguments: [params]))
        } catch {
            return .failure(error)
        }
    }
}

struct ScriptData: Identifiable, Codable, Hashable, Defaults.Serializable {
    var id: String
    var createDate: Date = .now
    var name: String
    var file: URL
    var mode: Mode

    enum Mode: String, Codable, CaseIterable {
        case tts
        case processor
        case action
        case plugin

        var args: [Any] {
            switch self {
            case .tts: [["call": "Hello World!"]]
            case .processor: [["title": "Test", "subtitle": "Test", "body": "Test"]]
            case .action: [["actionmode": "custom"]]
            case .plugin: [[:]]
            }
        }
        
        var title: String{
            switch self {
            case .tts:
                return String(localized: "语音")
            case .processor:
                return String(localized: "处理器")
            case .action:
                return String(localized: "动作")
            case .plugin:
                return String(localized: "插件")
            }
        }
        
        var symbol: String{
            switch self {
            case .tts: "message.and.waveform"
            case .processor: "memorychip"
            case .action: "pointer.arrow.click"
            case .plugin: "rectangle.3.group"
            }
        }
    }

    init(id: String, createDate: Date = .now, name: String, file: URL, mode: Mode) {
        self.id = id
        self.createDate = createDate
        self.name = name
        self.file = file
        self.mode = mode
    }

    init(name: String, content: String, mode: ScriptData.Mode) throws {
        if Defaults[.scripts].first(where: { $0.name == name }) != nil {
            throw ScriptDataError.name
        }
        self.id = content.sha256()
        guard let file = NCONFIG.Path(.scripts, name) else {
            throw ScriptDataError.path
        }

        do {
            try content.data(using: .utf8)?.write(to: file)
        } catch {
            throw ScriptDataError.save
        }

        self.name = name
        self.file = file
        self.mode = mode
    }

    enum ScriptDataError: Error {
        case name
        case path
        case save
        case syntax
    }
}


extension Defaults.Keys {
    static let scripts = Key<Set<ScriptData>>("ScriptDatas", [])
}

// MARK: - JSValue helpers
extension JSValue {
    func toSendable() -> Any? {
        if isUndefined || isNull { return nil }
        if let data = bytes { return data }
        if isString { return toString() }
        if isBoolean { return toBool() }
        if isNumber { return toNumber() }
        if isArray { return toArray() }
        if isObject { return toDictionary() }
        return nil
    }

    /// TypedArray（Uint8Array 等）的字节；非 TypedArray 返回 nil。
    var bytes: Data? { JSRuntime.copyBytes(self) }

    /// JS Error → 可读消息（优先 .message，其次 toString）。
    var errorMessage: String {
        objectForKeyedSubscript("message")?.toString() ?? toString() ?? "unknown"
    }
}

/// 异步原生方法：接收 JS 实参（已在 jsQueue 上提取成 Sendable Swift 值），
/// 返回任意可桥接值（Data/String/Number/数组/字典）。JSRuntime 会把它包装成
/// JS Promise，JS 端直接 `await`。抛错会 reject Promise。
public typealias AsyncNativeMethod = @Sendable ([Any?]) async throws -> Any?
