//
//  ServerMonitoring.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/9/28.
//
import SwiftUI

// MARK: - ContentView

struct ServerMonitoringView: View {
    @StateObject private var manager: SCServerStatusManager

    let server: PushServerModel
    init(server: PushServerModel) {
        self.server = server
        self._manager = StateObject(wrappedValue:
            SCServerStatusManager(server: server)
        )
    }

    var body: some View {
        let status = manager.status
        List {
            Section {
                // CPU Card
                SCCPUCardView(status: status)
                    .spaceStyle()
            } header: {
                HStack {
                    Text(verbatim: "CPU")
                    Spacer()
                    Text(status.osInfo)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
            }

            Section {
                // Memory Card
                SCMemoryCardView(status: status)
                    .spaceStyle()
            } header: {
                Text(verbatim: "Memory")
                    .padding(.horizontal)
            }

            Section {
                // Network Card
                SCNetworkCardView(status: status.network)
                    .spaceStyle()
            } header: {
                Text(verbatim: "Network")
                    .padding(.horizontal)
            }

            // Docker Card
            if !status.containers.isEmpty {
                Section {
                    SCDockerCardView(containers: status.containers)
                        .spaceStyle()
                } header: {
                    Text(verbatim: "Docker")
                        .padding(.horizontal)
                }
            }
            if !status.disks.isEmpty{
                Section {
                    // Disk Cards
                    ForEach(status.disks) { disk in
                        SCDiskCardView(disk: disk)
                            .spaceStyle()
                            .padding(.bottom, 10)
                    }
                } header: {
                    Text(verbatim: "Disk")
                        .padding(.horizontal)
                }
            }
            
        }
        .listStyle(.grouped)
        .navigationTitle(server.url.removeHTTPPrefix())
        .sheet(isPresented: $manager.showProcessSheet) {
            SCProcessSheet(
                processes: manager.processes,
                sort: $manager.processSort
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if manager.errorCount >= 3 {
                    Button {
                        manager.errorCount = 0
                    } label: {
                        Label("开启", systemImage: "power.circle.fill")
                    }
                }else{
                    Button {
                        manager.errorCount = 3
                    } label: {
                        Label("暂停", systemImage: "pause.fill")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.showProcessSheet.toggle()
                } label: {
                    Label("进程列表", systemImage: "archivebox.circle")
                }
            }
        }
    }
}

// MARK: - Process Sheet

enum ProcessSort {
    case cpuDesc, cpuAsc, memDesc, memAsc

    mutating func toggleCPU() {
        self = (self == .cpuDesc) ? .cpuAsc : .cpuDesc
    }

    mutating func toggleMem() {
        self = (self == .memDesc) ? .memAsc : .memDesc
    }
}

struct SCProcessSheet: View {
    let processes: [SCProcess]
    @Binding var sort: ProcessSort
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let sorted = sortedProcesses(processes, by: sort)
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("进程列表")
                .font(.title3.weight(.semibold))
                .padding(.vertical)

            ScrollView {
                LazyVStack(alignment: .center, spacing: 10, pinnedViews: .sectionHeaders) {
                    Section {
                        ForEach(sorted) { p in
                            HStack(alignment: .firstTextBaseline) {
                                Text(p.name)
                                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: 12)
                                Text(verbatim: String(format: "%.0f%%", p.cpu))
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .frame(width: 44, alignment: .trailing)
                                Text(verbatim: p.mem)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal)
                        }
                    } header: {
                        // Header
                        VStack {
                            HStack {
                                Text(verbatim: "Process")
                                    .foregroundColor(.gray)
                                Spacer()
                                Button(action: { sort.toggleCPU() }) {
                                    HStack(spacing: 4) {
                                        Text(verbatim: "CPU%")
                                        Image(systemName: sort == .cpuAsc ? "arrow.up" :
                                            "arrow.down")
                                            .imageScale(.small)
                                    }
                                    .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)

                                Button(action: { sort.toggleMem() }) {
                                    HStack(spacing: 4) {
                                        Text(verbatim: "Mem")
                                        Image(systemName: sort == .memAsc ? "arrow.up" :
                                            "arrow.down")
                                            .imageScale(.small)
                                    }
                                    .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 16)
                            }
                            .font(.callout)
                            .padding(.horizontal)
                            Divider().background(Color.gray.opacity(0.4))
                        }
                        .padding(.vertical, 5)
                        .background(.background)
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func sortedProcesses(_ processes: [SCProcess], by sort: ProcessSort) -> [SCProcess] {
        switch sort {
        case .cpuDesc:
            return processes.sorted { $0.cpu > $1.cpu }
        case .cpuAsc:
            return processes.sorted { $0.cpu < $1.cpu }
        case .memDesc:
            return processes.sorted { $0.memPercent > $1.memPercent }
        case .memAsc:
            return processes.sorted { $0.memPercent < $1.memPercent }
        }
    }

    private func bytes(from formatted: String) -> Double {
        // formatted like "27M" or "512K" without space, convert back to bytes for sorting
        let suffix = formatted.suffix(1)
        let numberString = formatted.dropLast()
        guard let value = Double(numberString) else { return 0 }
        switch suffix.uppercased() {
        case "K": return value * 1024
        case "M": return value * 1024 * 1024
        case "G": return value * 1024 * 1024 * 1024
        case "T": return value * 1024 * 1024 * 1024 * 1024
        default: return value
        }
    }
}

// MARK: - Components

struct SCCPUCardView: View {
    let status: SCServerStatus

    var body: some View {
        let coreCount = max(1, Double(status.cores.count))
        let load1Norm = min(1.0, status.load1 / coreCount)
        let load5Norm = min(1.0, status.load5 / coreCount)
        let load15Norm = min(1.0, status.load15 / coreCount)

        VStack(alignment: .leading, spacing: 15) {
            // Top Stats
            HStack(alignment: .top) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: "\(Int(status.cpuUsage))")
                        .font(.system(size: 40, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.35), value: status.cpuUsage)
                        .minimumScaleFactor(0.8)
                    Text(verbatim: "%")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                }
                .padding(.trailing, 10)

                HStack {
                    SCStatItem(
                        label: String(localized: "系统"),
                        value: "\(Int(status.systemUsage)) %",
                        color: .red
                    )
                    Spacer(minLength: 0)
                    SCStatItem(
                        label: String(localized: "用户"),
                        value: "\(Int(status.userUsage)) %",
                        color: .green
                    )
                    Spacer(minLength: 0)
                    SCStatItem(
                        label: String(localized: "IO 等待"),
                        value: "\(Int(status.ioWait)) %",
                        color: .purple
                    )
                    Spacer(minLength: 0)
                    SCStatItem(label: "STEAL", value: "\(Int(status.steal)) %", color: .yellow)
                }
                .padding(.leading)
            }

            VStack {
                ForEach(status.cores) { core in
                    // Dot Chart Visualization
                    SCDotChartView(core: core)
                        .frame(height: 8)
                }
            }

            // Bottom Stats
            HStack {
                VStack(alignment: .leading) {
                    Text("核数")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(verbatim: "\(status.cores.count)")
                        .font(.headline)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.35), value: status.cores.count)
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading) {
                    Text("空闲")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 5) {
                        Text(verbatim: "\(Int(status.idle))")
                            .font(.headline)
                            .minimumScaleFactor(0.5)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.35), value: status.idle)
                        Text(verbatim: "%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .center) {
                    Text("运行时间")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(alignment: .bottom, spacing: 5) {
                        Text(verbatim: "\(status.uptimeDays)")
                            .font(.headline)
                            .minimumScaleFactor(0.5)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.35), value: status.uptimeDays)
                        Text(verbatim: "D")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 1)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing) {
                    Text("负载")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(verbatim: "1, 5, 15m")
                        .font(.caption)
                        .minimumScaleFactor(0.5)
                }

                SCLoadRingView(
                    load1: load1Norm,
                    load5: load5Norm,
                    load15: load15Norm
                )
                .padding(.leading)
            }
        }
        .padding()
        .mbackground26(.message, radius: 16)
    }
}

struct SCMemoryCardView: View {
    let status: SCServerStatus

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 20) {
                        SCStatItem(
                            label: String(localized: "可用"),
                            value: status.memoryAvailable,
                            color: .green
                        )
                        Spacer(minLength: 0)
                        SCStatItem(
                            label: String(localized: "已用"),
                            value: status.memoryUsed,
                            color: .orange
                        )
                        Spacer(minLength: 0)
                        SCStatItem(
                            label: String(localized: "页面缓存"),
                            value: status.memoryCache,
                            color: .gray
                        )
                        Spacer(minLength: 0)
                    }
                }
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: status.memoryUsagePercent)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    SCUnitValueText(
                        value: "\(Int(status.memoryUsagePercent * 100))%",
                        baseFont: .caption,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray,
                        weight: .bold
                    )
                }
                .frame(width: 40, height: 40)
            }
        }
        .padding(20)
        .mbackground26(.message, radius: 16)
    }
}

struct SCNetworkCardView: View {
    let status: SCNetworkStatus

    var body: some View {
        let activeInterfaces = status.interfaces.filter { ($0.uploadRatio + $0.downloadRatio) > 0 }
        let physicalInterfaces = activeInterfaces.filter { !$0.isVirtual }
        let virtualInterfaces = activeInterfaces.filter { $0.isVirtual }
        let primaryInterface = physicalInterfaces
            .max(by: { $0.uploadRatio + $0.downloadRatio < $1.uploadRatio + $1.downloadRatio })

        VStack(alignment: .leading, spacing: 20) {
            // Summary Section
            HStack(alignment: .center) {
                // Upload Speed
                SCNetSpeedItem(icon: "arrow.up", label: "/S", value: status.totalUploadSpeed)

                Spacer()

                // Download Speed
                SCNetSpeedItem(icon: "arrow.down", label: "/S", value: status.totalDownloadSpeed)

                Spacer()

                // Total Traffic
                VStack(alignment: .trailing, spacing: 4) {
                    SCNetTrafficItem(icon: "arrow.up", value: status.totalUpload, color: .orange)
                    SCNetTrafficItem(icon: "arrow.down", value: status.totalDownload, color: .green)
                }

                Spacer()

                // Ring Chart
                SCTrafficRingView(upRatio: status.uploadRatio, downRatio: status.downloadRatio)
                    .frame(width: 50, height: 50)
            }

            // Connection Stats
            HStack {
                SCNetStatItem(label: String(localized: "重传率"), value: status.retransRate)
                Spacer()
                SCNetStatItem(label: String(localized: "主动建连"), value: "\(status.activeConn)")
                Spacer()
                SCNetStatItem(
                    label: String(localized: "被动建连"),
                    value: formatCount(status.passiveConn)
                )
                Spacer()
                SCNetStatItem(label: String(localized: "建连失败"), value: "\(status.failConn)")
            }

            HStack {
                SCNetStatItem(label: "ESTABLISHED", value: "\(status.established)")
                Spacer()
                SCNetStatItem(label: "TIME_WAIT", value: "\(status.timeWait)")
                Spacer()
                SCNetStatItem(label: "CLOSE_WAIT", value: "\(status.closeWait)")
                Spacer()
                SCNetStatItem(label: "SYN_RECV", value: "\(status.synRecv)")
            }

            Divider().background(Color.gray.opacity(0.3))

            // Primary physical interface only
            if let primary = primaryInterface {
                SCNetworkInterfaceRow(interface: primary)
                    .padding(.vertical, 8)
            } else {
                Text("No active physical interface")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            DisclosureGroup {
                ForEach(virtualInterfaces) { interface in
                    SCNetworkInterfaceRow(interface: interface)
                        .padding(.vertical, 8)
                }
            } label: {
                HStack {
                    Text(verbatim: "VIRTUAL INTERFACES")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(verbatim: "\(virtualInterfaces.count)")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .mbackground26(.message, radius: 16)
    }

    func formatCount(_ number: Int) -> String {
        if number > 1000 {
            return trimZero(Double(number) / 1000) + "k"
        }
        return "\(number)"
    }

    private func trimZero(_ value: Double) -> String {
        let formatted = String(format: "%.1f", value)
        if formatted.hasSuffix(".0") {
            return String(formatted.dropLast(2))
        }
        return formatted
    }
}

struct SCDiskCardView: View {
    let disk: SCDiskStatus

    var body: some View {
        VStack(spacing: 15) {
            // Header: Mount point, Device, Usage Bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: disk.mountPoint)
                        .font(.headline)
                    Text(verbatim: disk.device)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(verbatim: disk.fileSystem)
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 2) {
                        SCUnitValueText(
                            value: disk.used,
                            baseFont: .subheadline,
                            unitFont: .caption2,
                            valueColor: .primary,
                            unitColor: .gray,
                            weight: .medium
                        )
                        Text(verbatim: "/")
                            .font(.caption)
                            .foregroundColor(.gray)
                        SCUnitValueText(
                            value: disk.total,
                            baseFont: .caption,
                            unitFont: .caption2,
                            valueColor: .gray,
                            unitColor: .gray
                        )
                    }
                }

                // Vertical Progress Bar
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 40)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(progress: disk.percentage))
                        .frame(width: 20, height: 40 * CGFloat(disk.percentage))
                }
                .padding(.leading, 8)
            }

            Divider().background(Color.gray.opacity(0.3))

            // IO Stats Grid
            HStack {
                // Header Row
                VStack(alignment: .center) {
                    BreathingDot()
                        .frame(width: 6, height: 6)
                        .padding(.top, 3)
                    Spacer()
                    Text("读")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()
                    Text("写")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("速率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    SCUnitValueText(
                        value: disk.readRate,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                    Spacer()
                    SCUnitValueText(
                        value: disk.writeRate,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("字节")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    SCUnitValueText(
                        value: disk.readBytes,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                    Spacer()
                    SCUnitValueText(
                        value: disk.writeBytes,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(verbatim: "IOPS")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    SCUnitValueText(
                        value: disk.readIOPS,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                    Spacer()
                    SCUnitValueText(
                        value: disk.writeIOPS,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("延迟")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    SCUnitValueText(
                        value: disk.readDelay,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                    Spacer()
                    SCUnitValueText(
                        value: disk.writeDelay,
                        baseFont: .subheadline,
                        unitFont: .caption2,
                        valueColor: .primary,
                        unitColor: .gray
                    )
                }
            }
        }
        .padding(20)
        .mbackground26(.message, radius: 16)
    }
}

struct BreathingDot: View {
    @State private var isBreathing = false

    var body: some View {
        Circle()
            .fill(Color.green)
            .scaleEffect(isBreathing ? 1.4 : 0.8)
            .opacity(isBreathing ? 1 : 0.5)
            .animation(
                .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

struct SCDockerCardView: View {
    let containers: [SCDockerContainer]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(verbatim: "CPU")
                    .frame(width: 50, alignment: .center)
                Text(verbatim: "MEM")
                    .frame(width: 50, alignment: .leading)
                Text(verbatim: "NET ↓↑")
                    .frame(alignment: .leading)
                Spacer()
                Text(verbatim: "BLOCK R/W")
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.bottom, 10)

            Divider().background(Color.gray.opacity(0.3))

            ForEach(containers) { container in
                VStack(spacing: 12) {
                    HStack(alignment: .center, spacing: 10) {
                        // CPU Ring
                        ZStack {
                            Circle()
                                .stroke(Color(white: 0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: container.cpuPercentage)
                                .stroke(
                                    Color.green,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            Text(verbatim: container.cpuUsage)
                                .font(.caption2)
                        }
                        .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(verbatim: container.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.gray)
                            }

                            HStack {
                                SCUnitValueText(
                                    value: container.memoryUsed,
                                    baseFont: .caption,
                                    unitFont: .caption2,
                                    valueColor: .gray,
                                    unitColor: .gray
                                )
                                .frame(width: 50, alignment: .leading)
                                HStack(spacing: 4) {
                                    SCUnitValueText(
                                        value: container.netDownload,
                                        baseFont: .caption,
                                        unitFont: .caption2,
                                        valueColor: .gray,
                                        unitColor: .gray
                                    )
                                    Text(verbatim: "/")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    SCUnitValueText(
                                        value: container.netUpload,
                                        baseFont: .caption,
                                        unitFont: .caption2,
                                        valueColor: .gray,
                                        unitColor: .gray
                                    )
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    SCUnitValueText(
                                        value: container.blockRead,
                                        baseFont: .caption,
                                        unitFont: .caption2,
                                        valueColor: .gray,
                                        unitColor: .gray
                                    )
                                    Text(verbatim: "/")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    SCUnitValueText(
                                        value: container.blockWrite,
                                        baseFont: .caption,
                                        unitFont: .caption2,
                                        valueColor: .gray,
                                        unitColor: .gray
                                    )
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 12)

                if container.id != containers.last?.id {
                    Divider().background(Color.gray.opacity(0.2))
                }
            }
        }
        .padding(20)
        .mbackground26(.message, radius: 16)
    }
}

struct SCNetworkInterfaceRow: View {
    let interface: SCNetworkInterface

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Icon, Name, IP
            HStack {
                let allRatio = interface.downloadRatio + interface.uploadRatio
                Image(systemName: "wifi")
                    .font(.system(size: 14))
                    .foregroundColor(allRatio > 0 ? .green : .gray)

                Text(verbatim: interface.name)
                    .font(.callout)

                Spacer()

                if let ip = interface.ip {
                    Text(ip)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 40) {
                        SCNetSpeedItem(icon: "arrow.up", label: "/S", value: interface.uploadSpeed)
                        SCNetSpeedItem(
                            icon: "arrow.down",
                            label: "/S",
                            value: interface.downloadSpeed
                        )
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 5) {
                        Text(verbatim: "↑")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(verbatim: interface.totalUpload)
                            .font(.caption)
                        Circle().fill(Color.orange).frame(width: 4, height: 4)
                    }
                    HStack(spacing: 5) {
                        Text(verbatim: "↓")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(verbatim: interface.totalDownload)
                            .font(.caption)
                        Circle().fill(Color.green).frame(width: 4, height: 4)
                    }
                }
                .padding(.trailing, 10)

                // Mini Ring
                SCTrafficRingView(
                    upRatio: interface.uploadRatio,
                    downRatio: interface.downloadRatio,
                    strokeWidth: 4
                )
                .frame(width: 30, height: 30)
            }
        }
    }
}

struct SCNetSpeedItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Text(verbatim: icon == "arrow.up" ? "↑" : "↓")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(verbatim: label)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            SCUnitValueText(
                value: value,
                baseFont: .callout,
                unitFont: .caption2,
                valueColor: .primary,
                unitColor: .gray,
                weight: .medium
            )
        }
    }
}

struct SCNetTrafficItem: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(verbatim: icon == "arrow.up" ? "↑" : "↓")
                .font(.caption2)
                .foregroundColor(.gray)
            SCUnitValueText(
                value: value,
                baseFont: .callout,
                unitFont: .caption2,
                valueColor: .primary,
                unitColor: .gray,
                weight: .medium
            )
            Capsule()
                .fill(color)
                .frame(width: 4, height: 10)
        }
    }
}

struct SCNetStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: label)
                .font(.caption2)
                .foregroundColor(.gray)
            SCUnitValueText(
                value: value,
                baseFont: .subheadline,
                unitFont: .caption2,
                valueColor: .primary,
                unitColor: .gray
            )
        }
    }
}

struct SCTrafficRingView: View {
    let upRatio: Double
    let downRatio: Double
    var strokeWidth: CGFloat = 6

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: strokeWidth)

            // Upload (Orange)
            Circle()
                .trim(from: 0, to: upRatio)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            // Download (Green) - Start where upload ends
            Circle()
                .trim(from: 0, to: downRatio)
                .stroke(Color.green, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90 + (upRatio * 360)))
        }
    }
}

struct SCStatItem: View {
    let label: String
    let value: String
    let color: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let color = color {
                    Capsule()
                        .fill(color)
                        .frame(width: 4, height: 8)
                }
                Text(verbatim: label)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            SCUnitValueText(
                value: value,
                baseFont: .callout,
                unitFont: .caption2,
                valueColor: .primary,
                unitColor: .gray,
                weight: .medium
            )
        }
    }
}

struct SCUnitValueText: View {
    let value: String
    var baseFont: Font
    var unitFont: Font
    var valueColor: Color = .primary
    var unitColor: Color = .gray
    var weight: Font.Weight? = nil

    var body: some View {
        let parts = splitValueUnit(value)
        let spacing: CGFloat = parts.hadSpace ? 2 : 0

        if let unit = parts.unit {
            HStack(alignment: .lastTextBaseline, spacing: spacing) {
                Text(verbatim: parts.value)
                    .font(baseFont)
                    .foregroundColor(valueColor)
                    .fontWeight(weight)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.35), value: parts.value)
                Text(verbatim: unit)
                    .font(unitFont)
                    .foregroundColor(unitColor)
                    .fontWeight(weight)
            }
        } else {
            Text(verbatim: value)
                .font(baseFont)
                .foregroundColor(valueColor)
                .fontWeight(weight)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.35), value: value)
        }
    }

    private func splitValueUnit(_ text: String) -> (value: String, unit: String?, hadSpace: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return (text, nil, false) }

        var unitStart = trimmed.endIndex
        while unitStart > trimmed.startIndex {
            let prev = trimmed.index(before: unitStart)
            let ch = trimmed[prev]
            if ch.isLetter || ch == "%" || ch == "/" {
                unitStart = prev
            } else {
                break
            }
        }

        guard unitStart < trimmed.endIndex else { return (text, nil, false) }

        let hadSpace = unitStart > trimmed
            .startIndex && trimmed[trimmed.index(before: unitStart)] == " "
        let valuePart = String(trimmed[..<unitStart]).trimmingCharacters(in: .whitespaces)
        let unitPart = String(trimmed[unitStart...])

        guard !valuePart.isEmpty else { return (text, nil, false) }
        return (valuePart, unitPart, hadSpace)
    }
}

struct SCDotChartView: View {
    let core: SCCoreUsage

    // Constants for layout
    private let itemWidth: CGFloat = 4
    private let itemHeight: CGFloat = 8
    private let spacing: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let totalItemWidth = itemWidth + spacing
            // Calculate how many columns fit in the available width
            let columnCount = Int(geometry.size.width / totalItemWidth)

            HStack(spacing: spacing) {
                ForEach(0..<columnCount, id: \.self) { index in
                    Capsule()
                        .fill(color(for: index, totalColumns: columnCount))
                        .frame(width: itemWidth, height: itemHeight)
                }
            }
        }
        .drawingGroup() // Improve performance
    }

    func color(for index: Int, totalColumns: Int) -> Color {
        let systemDots = Int(Double(totalColumns) * core.system)
        let userDots = Int(Double(totalColumns) * core.user)
        let iowaitDots = Int(Double(totalColumns) * core.iowait)
        let stealDots = Int(Double(totalColumns) * core.steal)

        let t1 = systemDots
        let t2 = t1 + userDots
        let t3 = t2 + iowaitDots
        let t4 = t3 + stealDots

        if index < t1 { return .red }
        if index < t2 { return .green }
        if index < t3 { return .purple }
        if index < t4 { return .yellow }

        return Color.primary.opacity(0.1)
    }
}

struct SCLoadRingView: View {
    let load1: Double
    let load5: Double
    let load15: Double

    private let width: CGFloat = 38

    var body: some View {
        ZStack {
            SCRingShapeView(value: load1)
                .frame(width: width, height: width)

            SCRingShapeView(value: load5)
                .frame(width: width - 10, height: width - 10)

            SCRingShapeView(value: load15)
                .frame(width: width - 20, height: width - 20)
        }
    }
}

struct SCRingShapeView: View {
    var value: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    Color.green,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(90))
                .animation(.easeInOut(duration: 0.6), value: value)
        }
    }
}

extension Color {
    fileprivate static let transparent = Color.white.opacity(0)

    fileprivate init(progress: Double) {
        if progress >= 0.9 {
            self = .red
        } else if progress >= 0.8 {
            self = .orange
        } else {
            self = .green
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func spaceStyle() -> some View {
        self.listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .padding(.horizontal, 5)
    }
}

// 预览
#Preview {
    ServerMonitoringView(server: PushServerModel(url: "https://example.com"))
}
