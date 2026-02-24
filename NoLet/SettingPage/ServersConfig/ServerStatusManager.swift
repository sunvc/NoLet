//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ServerStatusManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/2/13 23:50.

import Combine
import Foundation

// MARK: - Manager

final class SCServerStatusManager: ObservableObject {
    private let server: PushServerModel

    @Published private(set) var status: SCServerStatus
    @Published private(set) var processes: [SCProcess] = []
    @Published var showProcessSheet: Bool = false
    @Published var processSort: ProcessSort = .cpuDesc
    @Published var errorCount: Int = 0

    private var refreshTask: Task<Void, Never>?
    private var http = NetworkManager()
    var refreshInterval: UInt64 = 2

    init(server: PushServerModel) {
        status = .placeholder
        self.server = server
        self.start()
    }

    @MainActor deinit { self.stop() }

    func start() {
        stop()
        refreshTask = Task.detached { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }

                await self.refresh()

                if await self.errorCount >= 3 {
                    try? await Task.sleep(for: .seconds(self.errorCount))
                    await MainActor.run { self.errorCount = 0 }
                    continue
                }
                try? await Task.sleep(for: .seconds(self.refreshInterval))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    nonisolated func refresh() async {
        do {
            async let fetchedStatus = fetchStatus()
            if await showProcessSheet {
                async let fetchedProcesses = fetchProcesses()
                let (s, p) = try await (fetchedStatus, fetchedProcesses)
                await updateUI(status: s, processes: p)
            } else {
                let s = try await fetchedStatus
                await updateUI(status: s, processes: nil)
            }
            await MainActor.run { self.errorCount = 0 }
        } catch {
            Toast.error(title: "连接失败!")
            await MainActor.run {
                self.errorCount += 1
            }
        }
    }

    private func updateUI(status: SCServerStatus, processes: [SCProcess]?) {
        self.status = status
        if let processes = processes {
            self.processes = processes
        }
    }

    private func fetchStatus() async throws -> SCServerStatus {
        let response = try await http.fetch(
            url: self.server.url,
            path: "/info",
            params: ["mode": "monitor"],
            headers: CryptoManager.signature(sign: self.server.sign, server: server.key),
            timeout: 3
        )
        let result: SCServerStatusResponse = try response.decode()
        return SCServerStatusMapper.map(from: result)
    }

    private func fetchProcesses() async throws -> [SCProcess] {
        let response = try await http.fetch(
            url: self.server.url,
            path: "/info",
            params: ["mode": "processes"],
            headers: CryptoManager.signature(sign: self.server.sign, server: server.key),
            timeout: 3
        )
        let result: [SCProcessResponse] = try response.decode()
        return result.map { p in
            SCProcess(
                pid: p.pid,
                name: p.name,
                cpu: p.cpuPercent,
                mem: formatBytes(Double(p.memBytes), separator: ""),
                memPercent: p.memPercent
            )
        }
    }
}

struct SCProcessResponse: Codable {
    let pid: Int32
    let name: String
    let cpuPercent: Double
    let memBytes: UInt64
    let memPercent: Double
}

// MARK: - API Contract

struct SCServerStatusResponse: Codable {
    let name: String
    let osInfo: String

    let cpuUsagePercent: Double
    let systemUsagePercent: Double
    let userUsagePercent: Double
    let ioWaitPercent: Double
    let stealPercent: Double
    let idlePercent: Double

    let uptimeSeconds: Int
    let load1: Double
    let load5: Double
    let load15: Double

    let cores: [SCCoreUsageResponse]

    let memory: SCMemoryResponse
    let network: SCNetworkResponse
    let disks: [SCDiskResponse]?
    let containers: [SCContainerResponse]?
}

struct SCCoreUsageResponse: Codable {
    let system: Double
    let user: Double
    let iowait: Double
    let steal: Double
    let idle: Double
}

struct SCMemoryResponse: Codable {
    let availableBytes: Double
    let usedBytes: Double
    let cacheBytes: Double
    let usagePercent: Double
}

struct SCNetworkResponse: Codable {
    let totalUploadBps: Double
    let totalDownloadBps: Double
    let totalUploadBytes: Double
    let totalDownloadBytes: Double
    let retransRatePercent: Double
    let activeConn: Int
    let passiveConn: Int
    let failConn: Int
    let established: Int
    let timeWait: Int
    let closeWait: Int
    let synRecv: Int
    let interfaces: [SCNetworkInterfaceResponse]
}

struct SCNetworkInterfaceResponse: Codable {
    let name: String
    let ip: String?
    let isVirtual: Bool
    let uploadBps: Double
    let downloadBps: Double
    let totalUploadBytes: Double
    let totalDownloadBytes: Double
}

struct SCDiskResponse: Codable {
    let mountPoint: String
    let device: String
    let fileSystem: String
    let usedBytes: Double
    let totalBytes: Double

    let readBps: Double
    let readBytes: Double
    let readIOPS: Double
    let readDelayMs: Double

    let writeBps: Double
    let writeBytes: Double
    let writeIOPS: Double
    let writeDelayMs: Double
}

struct SCContainerResponse: Codable {
    let name: String
    let cpuUsagePercent: Double
    let memoryBytes: Double
    let netUploadBytes: Double
    let netDownloadBytes: Double
    let blockReadBytes: Double
    let blockWriteBytes: Double
}

// MARK: - Mapping

private enum SCByteUnit: Int, Codable {
    case b = 0
    case k
    case m
    case g
    case t

    var symbol: String {
        switch self {
        case .b: return "B"
        case .k: return "K"
        case .m: return "M"
        case .g: return "G"
        case .t: return "T"
        }
    }
}

private func formatBytes(_ bytes: Double, separator: String = " ") -> String {
    let base = 1024.0
    var value = max(0.0, bytes)
    var unit = SCByteUnit.b

    while value >= base, unit != .t {
        value /= base
        unit = SCByteUnit(rawValue: unit.rawValue + 1) ?? .t
    }

    let formatted: String
    if unit == .b {
        formatted = String(Int(value))
    } else if value >= 10 {
        formatted = String(format: "%.0f", value)
    } else {
        formatted = String(format: "%.1f", value)
    }

    return "\(formatted)\(separator)\(unit.symbol)"
}

private func formatRate(_ bytesPerSecond: Double, separator: String = " ") -> String {
    return "\(formatBytes(bytesPerSecond, separator: separator))/s"
}

private enum SCServerStatusMapper {
    static func map(from response: SCServerStatusResponse) -> SCServerStatus {
        let memoryAvailable = formatBytes(response.memory.availableBytes)
        let memoryUsed = formatBytes(response.memory.usedBytes)
        let memoryCache = formatBytes(response.memory.cacheBytes)

        let totalUp = response.network.totalUploadBps
        let totalDown = response.network.totalDownloadBps
        let totalSpeed = max(1.0, totalUp + totalDown)

        let network = SCNetworkStatus(
            totalUploadSpeed: formatRate(totalUp),
            totalDownloadSpeed: formatRate(totalDown),
            totalUpload: formatBytes(response.network.totalUploadBytes),
            totalDownload: formatBytes(response.network.totalDownloadBytes),
            uploadRatio: min(1.0, totalUp / totalSpeed),
            downloadRatio: min(1.0, totalDown / totalSpeed),
            retransRate: String(format: "%.1f %%", response.network.retransRatePercent),
            activeConn: response.network.activeConn,
            passiveConn: response.network.passiveConn,
            failConn: response.network.failConn,
            established: response.network.established,
            timeWait: response.network.timeWait,
            closeWait: response.network.closeWait,
            synRecv: response.network.synRecv,
            interfaces: response.network.interfaces.map { iface in
                let ifaceTotal = max(1.0, iface.uploadBps + iface.downloadBps)
                return SCNetworkInterface(
                    name: iface.name,
                    ip: iface.ip,
                    isVirtual: iface.isVirtual,
                    uploadSpeed: formatRate(iface.uploadBps),
                    downloadSpeed: formatRate(iface.downloadBps),
                    totalUpload: formatBytes(iface.totalUploadBytes),
                    totalDownload: formatBytes(iface.totalDownloadBytes),
                    uploadRatio: min(1.0, iface.uploadBps / ifaceTotal),
                    downloadRatio: min(1.0, iface.downloadBps / ifaceTotal)
                )
            }
        )

        let disks = (response.disks ?? []).map { disk in
            SCDiskStatus(
                mountPoint: disk.mountPoint,
                device: disk.device,
                fileSystem: disk.fileSystem,
                used: formatBytes(disk.usedBytes, separator: ""),
                total: formatBytes(disk.totalBytes, separator: ""),
                percentage: disk.totalBytes > 0 ? min(1.0, disk.usedBytes / disk.totalBytes) : 0.0,
                readRate: formatRate(disk.readBps),
                readBytes: formatBytes(disk.readBytes),
                readIOPS: String(format: "%.0f", disk.readIOPS),
                readDelay: String(format: "%.0f", disk.readDelayMs),
                writeRate: formatRate(disk.writeBps),
                writeBytes: formatBytes(disk.writeBytes),
                writeIOPS: String(format: "%.0f", disk.writeIOPS),
                writeDelay: String(format: "%.0f", disk.writeDelayMs)
            )
        }

        let containers = (response.containers ?? []).map { container in
            let cpuPercent = max(0.0, min(100.0, container.cpuUsagePercent))
            return SCDockerContainer(
                name: container.name,
                cpuUsage: String(format: "%.0f%%", cpuPercent),
                cpuPercentage: cpuPercent / 100.0,
                memoryUsed: formatBytes(container.memoryBytes, separator: ""),
                netUpload: formatBytes(container.netUploadBytes, separator: ""),
                netDownload: formatBytes(container.netDownloadBytes, separator: ""),
                blockRead: formatBytes(container.blockReadBytes, separator: ""),
                blockWrite: formatBytes(container.blockWriteBytes, separator: "")
            )
        }

        return SCServerStatus(
            name: response.name,
            osInfo: response.osInfo,
            cpuUsage: response.cpuUsagePercent,
            systemUsage: response.systemUsagePercent,
            userUsage: response.userUsagePercent,
            ioWait: response.ioWaitPercent,
            steal: response.stealPercent,
            idle: response.idlePercent,
            uptimeDays: max(0, response.uptimeSeconds / 86400),
            load1: response.load1,
            load5: response.load5,
            load15: response.load15,
            cores: response.cores.map {
                SCCoreUsage(
                    system: $0.system,
                    user: $0.user,
                    iowait: $0.iowait,
                    steal: $0.steal,
                    idle: $0.idle
                )
            },
            memoryAvailable: memoryAvailable,
            memoryUsed: memoryUsed,
            memoryCache: memoryCache,
            memoryUsagePercent: response.memory.usagePercent,
            network: network,
            disks: disks,
            containers: containers
        )
    }
}

// MARK: - View Models

struct SCCoreUsage: Identifiable {
    let id = UUID()
    let system: Double
    let user: Double
    let iowait: Double
    let steal: Double
    let idle: Double
}

struct SCNetworkInterface: Identifiable {
    let id = UUID()
    let name: String
    let ip: String?
    let isVirtual: Bool

    // Traffic
    let uploadSpeed: String
    let downloadSpeed: String
    let totalUpload: String
    let totalDownload: String

    // For chart ratio (0.0 - 1.0)
    let uploadRatio: Double
    let downloadRatio: Double
}

struct SCNetworkStatus {
    // Summary
    let totalUploadSpeed: String
    let totalDownloadSpeed: String
    let totalUpload: String
    let totalDownload: String
    let uploadRatio: Double
    let downloadRatio: Double

    // TCP Stats
    let retransRate: String
    let activeConn: Int
    let passiveConn: Int
    let failConn: Int
    let established: Int
    let timeWait: Int
    let closeWait: Int
    let synRecv: Int

    let interfaces: [SCNetworkInterface]
}

struct SCDiskStatus: Identifiable {
    let id = UUID()
    let mountPoint: String
    let device: String
    let fileSystem: String
    let used: String
    let total: String
    let percentage: Double

    // Read Stats
    let readRate: String
    let readBytes: String
    let readIOPS: String
    let readDelay: String

    // Write Stats
    let writeRate: String
    let writeBytes: String
    let writeIOPS: String
    let writeDelay: String
}

struct SCDockerContainer: Identifiable {
    let id = UUID()
    let name: String
    let cpuUsage: String
    let cpuPercentage: Double // 0.0 - 1.0
    let memoryUsed: String

    // Network
    let netUpload: String
    let netDownload: String

    // Block I/O
    let blockRead: String
    let blockWrite: String
}

struct SCServerStatus {
    let name: String
    let osInfo: String
    let cpuUsage: Double
    let systemUsage: Double
    let userUsage: Double
    let ioWait: Double
    let steal: Double
    let idle: Double
    let uptimeDays: Int
    let load1: Double
    let load5: Double
    let load15: Double

    // Usage per core
    let cores: [SCCoreUsage]

    let memoryAvailable: String
    let memoryUsed: String
    let memoryCache: String
    let memoryUsagePercent: Double

    let network: SCNetworkStatus

    let disks: [SCDiskStatus]

    let containers: [SCDockerContainer]
}

extension SCNetworkStatus {
    static let placeholder = SCNetworkStatus(
        totalUploadSpeed: "--",
        totalDownloadSpeed: "--",
        totalUpload: "--",
        totalDownload: "--",
        uploadRatio: 0,
        downloadRatio: 0,
        retransRate: "--",
        activeConn: 0,
        passiveConn: 0,
        failConn: 0,
        established: 0,
        timeWait: 0,
        closeWait: 0,
        synRecv: 0,
        interfaces: []
    )
}

extension SCServerStatus {
    static let placeholder = SCServerStatus(
        name: "--",
        osInfo: "--",
        cpuUsage: 0,
        systemUsage: 0,
        userUsage: 0,
        ioWait: 0,
        steal: 0,
        idle: 0,
        uptimeDays: 0,
        load1: 0,
        load5: 0,
        load15: 0,
        cores: [],
        memoryAvailable: "--",
        memoryUsed: "--",
        memoryCache: "--",
        memoryUsagePercent: 0,
        network: .placeholder,
        disks: [],
        containers: []
    )
}

struct SCProcess: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let cpu: Double
    let mem: String
    let memPercent: Double
}
