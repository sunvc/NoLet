// NoLetLanReceiver.swift
// NoLet 局域网快传接收端（macOS）：监听 UDP 39876，接收鸿蒙手机广播的加密文本分片，
// 收齐后用 6 位接收码做 AES-256-GCM 解密（密钥 = SHA256(code)），写入系统剪贴板并弹通知。
//
// 编译：
//   swiftc -O NoLetLanReceiver.swift -o NoLetLanReceiver \
//     -framework AppKit -framework Network -framework CryptoKit
// 运行：
//   ./NoLetLanReceiver 123456              # 直接传接收码
//   ./NoLetLanReceiver                     # 读 ~/.nolet-lan-code
//
// 无配对、无连接：手机进 App 时广播，电脑一直在监听即可。同一 Wi-Fi/局域网下使用。

import Foundation
import Network
import CryptoKit
import AppKit

let PORT: UInt16 = 39876
let MAGIC = "NOLETLAN"
let VERSION = 1
// 分片重组超时与已完成消息去重保留时间（秒）
let ASSEMBLY_TTL: TimeInterval = 30
let DONE_TTL: TimeInterval = 300

// MARK: - 协议包

struct Packet: Decodable {
    let m: String
    let v: Int
    let id: String
    let ts: Int64
    let dev: String
    let n: Int
    let i: Int
    let iv: String
    let d: String
}

// MARK: - 分片重组

final class Assembly {
    let id: String
    let device: String
    let total: Int
    var chunks: [Int: Data] = [:]
    let createdAt: Date = Date()

    init(id: String, device: String, total: Int) {
        self.id = id
        self.device = device
        self.total = total
    }

    var isComplete: Bool { chunks.count == total }

    func joinedText() -> String? {
        var data = Data()
        for i in 0..<total {
            guard let chunk = chunks[i] else { return nil }
            data.append(chunk)
        }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - 接收端

final class Receiver {
    let key: SymmetricKey
    var listener: NWListener?
    var assemblies: [String: Assembly] = [:]
    // 已完成消息 id（忽略手机为抗丢包重复广播的多轮报文）
    var completed: [String: Date] = [:]

    init(code: String) {
        let codeData = Data(code.utf8)
        self.key = SymmetricKey(data: SHA256.hash(data: codeData))
    }

    func start() throws {
        let listener = try NWListener(using: .udp, on: NWEndpoint.Port(rawValue: PORT)!)
        listener.newConnectionHandler = { [weak self] conn in
            guard let self else { return }
            conn.start(queue: .main)
            self.receiveLoop(conn)
        }
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("NoLet LAN receiver listening on udp/\(PORT)")
            case .failed(let err):
                print("Listener failed: \(err)（端口被占用？）")
                exit(1)
            default:
                break
            }
        }
        listener.start(queue: .main)
        self.listener = listener

        // 定时清理未收齐的过期分片与已完成去重记录
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.gc()
        }
    }

    private func receiveLoop(_ conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let error {
                print("Receive error: \(error)")
                conn.cancel()
                return
            }
            if let data {
                self.handleDatagram(data)
            }
            self.receiveLoop(conn)
        }
    }

    private func handleDatagram(_ data: Data) {
        guard let packet = try? JSONDecoder().decode(Packet.self, from: data) else { return }
        guard packet.m == MAGIC, packet.v == VERSION else { return }
        gc()
        if completed[packet.id] != nil { return }

        guard
            packet.n > 0, packet.n <= 32,
            packet.i >= 0, packet.i < packet.n,
            let iv = Data(base64Encoded: packet.iv), iv.count == 12,
            let body = Data(base64Encoded: packet.d)
        else { return }

        // combined = nonce(12) || ciphertext || tag(16)
        var combined = Data()
        combined.append(iv)
        combined.append(body)
        guard let box = try? AES.GCM.SealedBox(combined: combined),
              let plain = try? AES.GCM.open(box, using: key) else {
            print("忽略无法解密的分片（接收码是否一致？）id=\(packet.id) i=\(packet.i)")
            return
        }

        let assembly = assemblies[packet.id] ?? Assembly(id: packet.id, device: packet.dev, total: packet.n)
        if assembly.total != packet.n { return }
        assembly.chunks[packet.i] = plain
        assemblies[packet.id] = assembly

        if assembly.isComplete, let text = assembly.joinedText() {
            assemblies[packet.id] = nil
            completed[packet.id] = Date()
            accept(text: text, device: assembly.device)
        }
    }

    private func accept(text: String, device: String) {
        let preview = text.replacingOccurrences(of: "\n", with: " ").prefix(40)
        print("[\(timestamp())] 收到来自 \(device) 的 \(text.count) 字符：\(preview)")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        notify(title: "NoLet 已接收", body: "来自 \(device)，已写入剪贴板")
    }

    private func gc() {
        let now = Date()
        assemblies = assemblies.filter { now.timeIntervalSince($0.value.createdAt) < ASSEMBLY_TTL }
        completed = completed.filter { now.timeIntervalSince($0.value) < DONE_TTL }
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }

    private func notify(title: String, body: String) {
        // 命令行进程无需签名即可投递 NSUserNotification（系统旧 API，仍可用）
        let center = NSUserNotificationCenter.default
        let note = NSUserNotification()
        note.title = title
        note.informativeText = body
        note.soundName = nil
        center.deliver(note)
    }
}

// MARK: - 入口

func resolveCode() -> String? {
    if CommandLine.arguments.count >= 2, !CommandLine.arguments[1].isEmpty {
        return CommandLine.arguments[1]
    }
    let path = NSString(string: "~/.nolet-lan-code").expandingTildeInPath
    if let s = try? String(contentsOfFile: path, encoding: .utf8) {
        let code = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.isEmpty { return code }
    }
    return nil
}

guard let code = resolveCode() else {
    print("""
    用法: NoLetLanReceiver <6位接收码>
       或把接收码写入 ~/.nolet-lan-code 后直接运行

    接收码在手机：设置 → 更多设置 → 电脑快传 中查看（需先开启局域网共享）。
    电脑与手机需在同一 Wi-Fi / 局域网。
    """)
    exit(1)
}

// 日志实时落盘（launchd 重定向时也能立刻看到）
setbuf(stdout, nil)
setbuf(stderr, nil)

let receiver = Receiver(code: code)
do {
    try receiver.start()
} catch {
    print("启动失败: \(error)")
    exit(1)
}

dispatchMain()
