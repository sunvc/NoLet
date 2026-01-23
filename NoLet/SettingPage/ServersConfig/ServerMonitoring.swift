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

import Charts
import Defaults
import SwiftUI

struct ServerMonitoringView: View {
    @StateObject private var manager = AppManager.shared
    // 监控数据模型
    @State private var cpuUsage: CPUUsage = .init(pidPercentage: 0.0, osPercentage: 0)
    @State private var memoryInfo: MemoryInfo = .init(pidRamMB: 0, osRamGB: 0, totalRamGB: 0)
    @State private var connectionsInfo = ConnectionsInfo(pidConns: 0, osConns: 0, load_svg: 0)

    // 历史数据记录
    @State private var cpuHistory: [Double] = Array(repeating: 0, count: 10)
    @State private var memoryHistory: [Double] = Array(repeating: 0, count: 10)
    @State private var connectionsHistory: [Double] = Array(repeating: 0, count: 10)

    // 历史最大连接数
    @State private var maxHistoricalConnections: Int = 1

    var server: PushServerModel

    let network = NetworkManager()

    @State private var timer: Timer? = nil

    @State private var errorCount = 0

    var body: some View {
        List {
            Section {
                // CPU使用率卡片
                CPUCard(
                    pidPercentage: cpuUsage.pidPercentage,
                    osPercentage: cpuUsage.osPercentage,
                    chartData: cpuHistory
                )
            }.listSectionSeparator(.hidden)

            Section {
                // 内存使用情况卡片
                MemoryCard(
                    pidRamMB: memoryInfo.pidRamMB,
                    osRamGB: memoryInfo.osRamGB,
                    totalRamGB: memoryInfo.totalRamGB,
                    chartData: memoryHistory
                )
            }.listSectionSeparator(.hidden)

            Section {
                // 连接数卡片
                ConnectionsCard(
                    pidConns: connectionsInfo.pidConns,
                    osConns: connectionsInfo.osConns,
                    chartData: connectionsHistory,
                    load_svg: connectionsInfo.load_svg,
                    maxConnections: maxHistoricalConnections
                )
            }.listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .task {
            if self.timer == nil {
                updateData()
                self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    Task { @MainActor in
                        self.updateData()
                    }
                }
                logger.error("启动定时器")
            }
        }
        .onDisappear {
            self.timer?.invalidate()
            self.timer = nil
        }
        .navigationTitle("服务器监控")
    }

    // 数据更新
    private func updateData() {
        Task {
            do {
                let data: ServerData = try await network.fetch(
                    url: server.url,
                    path: "/monitor",
                    method: .GET,
                    headers: CryptoManager.signature(sign: server.sign, server: server.key)
                )

                await MainActor.run {
                    // 使用新的API数据更新UI模型
                    self.cpuUsage = CPUUsage.fromAPIData(data: data)
                    self.memoryInfo = MemoryInfo.fromAPIData(data: data)
                    self.connectionsInfo = ConnectionsInfo.fromAPIData(data: data)

                    // 更新历史数据
                    // 移除最旧的数据点并添加新的数据点
                    cpuHistory.removeFirst()
                    cpuHistory.append(cpuUsage.osPercentage) // 使用OS CPU使用率

                    memoryHistory.removeFirst()
                    // 计算OS内存使用百分比：已使用OS内存/总OS内存
                    let memoryUsagePercentage = (memoryInfo.osRamGB / memoryInfo.totalRamGB) * 100
                    memoryHistory.append(memoryUsagePercentage)

                    // 更新历史最大连接数
                    if connectionsInfo.pidConns >= maxHistoricalConnections {
                        maxHistoricalConnections = connectionsInfo.pidConns + 2
                    }

                    connectionsHistory.removeFirst()
                    // 计算连接数比例：pid连接数/历史最大连接数 * 100（转为百分比）
                    let connectionsPercentage =
                        (Double(connectionsInfo.pidConns) / Double(maxHistoricalConnections)) * 100

                    connectionsHistory.append(connectionsPercentage)
                }
            } catch {
                errorCount += 1
                logger.error("\(error)")
                Toast.error(title: "服务器连接失败")
            }
        }
    }
}

// CPU卡片组件（横向布局）
private struct CPUCard: View {
    var pidPercentage: Double
    var osPercentage: Double
    var chartData: [Double]

    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cyan.opacity(0.1))

            // 背景图表
            UsageChartView(dataPoints: chartData, color: .red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(2)

            VStack(spacing: 0) {
                // 顶部：标题和图标
                HStack {
                    Text("CPU 使用情况")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))

                    Spacer()

                    Image(systemName: "cpu")
                        .foregroundColor(.primary)
                }
                .padding([.horizontal, .top])

                // 中间：横向布局的百分比显示
                HStack(alignment: .bottom, spacing: 10) {
                    // PID百分比（大字体）
                    Text(String(format: "%.1f%%", pidPercentage))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    Text(verbatim: "/")
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .offset(y: -10)
                    // OS百分比（小字体）
                    Text(String(format: "%.1f%%", osPercentage))
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.7))
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
                .minimumScaleFactor(0.5)

                Spacer()
            }
        }
        .frame(height: 180)
    }
}

// 内存卡片组件
private struct MemoryCard: View {
    var pidRamMB: Double
    var osRamGB: Double
    var totalRamGB: Double
    var chartData: [Double]

    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cyan.opacity(0.1))

            // 背景图表
            UsageChartView(dataPoints: chartData, color: .blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(2)

            VStack(spacing: 0) {
                // 顶部：标题和图标
                HStack {
                    Text("内存使用情况")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))

                    Spacer()

                    Image(systemName: "memorychip")
                        .foregroundColor(.primary)
                }
                .padding([.horizontal, .top])

                // 中间：主值显示（PID RAM）
                Text(String(format: "%.1f MB", pidRamMB))
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
                    .minimumScaleFactor(0.5)

                Spacer()

                // 底部：OS RAM和总RAM
                HStack {
                    Spacer()

                    VStack(alignment: .center) {
                        Text("已使用")
                            .font(.system(size: 12))
                            .foregroundColor(.primary.opacity(0.7))

                        Text(String(format: "%.1f GB", osRamGB))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .center) {
                        Text("总内存")
                            .font(.system(size: 12))
                            .foregroundColor(.primary.opacity(0.7))

                        Text(String(format: "%.1f GB", totalRamGB))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(height: 180)
    }
}

// 连接数卡片组件
private struct ConnectionsCard: View {
    var pidConns: Int
    var osConns: Int
    var chartData: [Double]
    var load_svg: Double
    var maxConnections: Int = 1 // 默认最大连接数

    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cyan.opacity(0.1))

            // 背景图表
            UsageChartView(dataPoints: chartData, color: .purple)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(2)

            VStack(spacing: 0) {
                // 顶部：标题和图标
                HStack {
                    Text("活动连接")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))

                    Text(verbatim: String(format: "- %.1f ms", load_svg))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))

                    Spacer()

                    Image(systemName: "network")
                        .foregroundColor(.primary)
                }
                .padding([.horizontal, .top])

                // 中间：横向布局的连接数显示
                HStack(alignment: .bottom, spacing: 10) {
                    // PID连接数（大字体）
                    Text(verbatim: "\(pidConns)")
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Text(verbatim: "/")
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .offset(y: -10)
                    // OS连接数（小字体）
                    Text(verbatim: "\(osConns)")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.7))
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
                .minimumScaleFactor(0.5)

                Spacer()
            }
        }
        .frame(height: 180)
    }
}

// 使用Charts框架的图表组件
private struct UsageChartView: View {
    var dataPoints: [Double]
    var color: Color

    // 将原始数据转换为结构化数据点
    private var chartData: [UsageDataPoint] {
        dataPoints.enumerated().map { index, value in
            UsageDataPoint(id: index, time: index, value: value)
        }
    }

    var body: some View {
        Chart(chartData) { point in
            // 线条标记
            LineMark(
                x: .value(Text(verbatim: "Time"), point.time),
                y: .value(Text(verbatim: "Usage"), point.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            // 区域填充
            AreaMark(
                x: .value(Text(verbatim: "Time"), point.time),
                y: .value(Text(verbatim: "Usage"), point.value)
            )
            .foregroundStyle(color.opacity(0.2))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

// 创建数据点结构体以符合Charts要求
private struct UsageDataPoint: Identifiable {
    let id: Int
    let time: Int
    let value: Double
}

// 数据模型
private struct DetailItem: Codable {
    var label: String
    var value: String
}

// 数据模型
private struct ServerData: Codable {
    var pid: ServerProcessInfo
    var os: SystemInfo
}

private struct ServerProcessInfo: Codable {
    var cpu: Double
    var ram: Double
    var conns: Int
}

private struct SystemInfo: Codable {
    var cpu: Double
    var ram: Double
    var total_ram: Double
    var load_avg: Double
    var conns: Int
}

// CPU使用率数据模型
private struct CPUUsage {
    var pidPercentage: Double
    var osPercentage: Double

    static func fromAPIData(data: ServerData) -> CPUUsage {
        return CPUUsage(
            pidPercentage: data.pid.cpu,
            osPercentage: data.os.cpu
        )
    }
}

// 内存信息数据模型
private struct MemoryInfo {
    var pidRamMB: Double
    var osRamGB: Double
    var totalRamGB: Double

    static func fromAPIData(data: ServerData) -> MemoryInfo {
        // 将进程内存从字节转换为MB
        let pidMemoryMB = Double(data.pid.ram) / 1024 / 1024

        // 将系统内存从字节转换为GB
        let osMemoryGB = Double(data.os.ram) / 1024 / 1024 / 1024
        let totalMemoryGB = Double(data.os.total_ram) / 1024 / 1024 / 1024

        return MemoryInfo(
            pidRamMB: pidMemoryMB,
            osRamGB: osMemoryGB,
            totalRamGB: totalMemoryGB
        )
    }
}

// 连接数数据模型
private struct ConnectionsInfo {
    var pidConns: Int
    var osConns: Int
    var load_svg: Double

    static func fromAPIData(data: ServerData) -> ConnectionsInfo {
        return ConnectionsInfo(
            pidConns: data.pid.conns,
            osConns: data.os.conns,
            load_svg: data.os.load_avg
        )
    }
}

// 预览
#Preview {
    ServerMonitoringView(server: PushServerModel(url: "https://example.com"))
}


