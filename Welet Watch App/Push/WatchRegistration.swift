//
//  WatchRegistration.swift
//  Welet Watch App
//
//  用手表本地的服务器注册手表自己的 APNs token。
//  与手机 AppManager.register 同协议:POST {url}/register,
//  body 键名与 DeviceInfo CodingKeys 一致(key/token/talk/location/voip/group)。
//  key 留空时由服务端分配,响应里的 key 回写到本地服务器。
//

import Foundation
import OSLog

struct RegisterResponse: Decodable {
    let code: Int
    let message: String?
    let data: Payload?

    struct Payload: Decodable {
        let key: String?
        let token: String?
        let core: Int?
    }
}

@MainActor
final class WatchRegistration {
    static let shared = WatchRegistration()
    private init() {}

    private var registering = false

    func registrationsChanged() async {
        await registerAll(force: true)
    }

    /// token 到位、服务器列表变化或进前台时调用。
    func registerAll(force: Bool = false) async {
        guard !registering else { return }
        guard let token = WatchCache.deviceToken, !token.isEmpty else { return }
        let servers = WatchServerStore.shared.servers
        guard !servers.isEmpty else { return }

        registering = true
        defer { registering = false }

        let configs = WatchCryptoStore.shared.configs
        let deviceID = WatchCache.deviceUUID
        let store = WatchServerStore.shared

        await withTaskGroup(of: (String, String?).self) { group in
            for server in servers {
                group.addTask {
                    let assignedKey = await Self.register(
                        server: server,
                        token: token,
                        deviceID: deviceID,
                        configs: configs
                    )
                    return (server.id, assignedKey)
                }
            }
            for await (serverID, assignedKey) in group where assignedKey != nil {
                if let assignedKey {
                    store.updateKey(assignedKey, for: serverID)
                }
            }
        }
    }

    private nonisolated static func register(
        server: PushServerModel,
        token: String,
        deviceID: String,
        configs: [WatchCryptoConfig]
    ) async -> String? {
        guard var components = URLComponents(string: server.url) else { return nil }
        components.path = (components.path as NSString).appendingPathComponent("register")
        guard let url = components.url else { return nil }

        var body: [String: Any] = [
            "key": server.key,
            "token": token,
        ]
        if let group = server.group, !group.isEmpty {
            body["group"] = group
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.allHTTPHeaderFields = WatchCrypto.signature(
            sign: server.sign,
            deviceID: deviceID,
            serverKey: server.key,
            configs: configs
        )
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  200...299 ~= http.statusCode
            else { return nil }
            let decoded = try? JSONDecoder().decode(RegisterResponse.self, from: data)
            // 仅当本地原本没有 key 时采用服务端分配的 key
            return server.key.isEmpty ? decoded?.data?.key : nil
        } catch {
            CloudSchema.cloudLog.error("watch register failed: \(error as NSError)")
            return nil
        }
    }
}
