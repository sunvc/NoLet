//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - EQSliderView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description: AI-generated. Use with caution.

//  History:
//    Created by Neo on 2026/6/16 05:52.

import Defaults
import SwiftUI

struct EQSliderView: View {
    @State private var dragPointYLocations: [CGFloat] = Array(repeating: .zero, count: 6)
    @State private var resetPoints: [Double] = Array(repeating: .zero, count: 6)

    @State private var eqViewFrame: CGRect = .zero

    @Default(.eqBands) var eqBands
    @Default(.eqPreset) var eqPreset

    private var maxGain = EqualizerPreset.maxGain
    private var minGain = EqualizerPreset.minGain

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Draw labels for gain values
                VStack {
                    Text(verbatim: "\(Int(maxGain))db")
                        .font(.caption2)
                        .foregroundColor(.black)
                    Spacer()
                    Text(verbatim: "0dB")
                        .font(.caption2)
                        .foregroundColor(.black)
                    Spacer()
                    Text(verbatim: "\(Int(minGain))db")
                        .font(.caption2)
                        .foregroundColor(.black)
                }
                GeometryReader { innerGeo in
                    ZStack {
                        LineShape(values: dragPointYLocations.map { Double($0) })
                            .stroke(Color.mint, lineWidth: 2)
                            .animation(.easeInOut(duration: 0.2), value: eqPreset)
                            .onAppear {
                                resetPoints = resetPoints.map { _ in Double(gainToYPosition(
                                    at: 0,
                                    in: innerGeo.size
                                )) }
                            }

                        Path { path in
                            for index in 0..<dragPointYLocations.count {
                                let x = positionForDragPoint(at: index, size: innerGeo.size)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: innerGeo.size.height))
                            }
                            path.move(to: CGPoint(x: 0, y: innerGeo.size.height / 2))
                            path.addLine(to: CGPoint(
                                x: innerGeo.size.width,
                                y: innerGeo.size.height / 2
                            ))
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)

                        ForEach(eqBands) { band in
                            Circle()
                                .fill(Color.mint)
                                .frame(width: 20, height: 20)
                                .position(
                                    x: positionForDragPoint(at: band.index, size: innerGeo.size),
                                    y: dragPointYLocations[band.index]
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newY = min(
                                                max(value.location.y, 0),
                                                innerGeo.size.height
                                            )
                                            dragPointYLocations[band.index] = newY
                                            updateGainValue(at: band.index, in: innerGeo.size)
                                        }
                                )
                                .onAppear {
                                    dragPointYLocations[band.index] = gainToYPosition(
                                        at: band.value,
                                        in: innerGeo.size
                                    )
                                }
                        }
                    }
                    .onChange(of: eqPreset) { value in
                        if value != .custom {
                            self.eqBands = value.bands
                            resetPositions(in: innerGeo.size)
                        }
                    }
                    .onChange(of: eqBands) { datas in
                        let values = datas.map { $0.value }
                        var ok = false
                        for item in EqualizerPreset.allCases {
                            if item.gains == values {
                                self.eqPreset = item
                                ok = true
                            }
                        }
                        if !ok {
                            self.eqPreset = EqualizerPreset.custom
                        }
                    }

                    ForEach(eqBands) { band in
                        Text(band.frequency)
                            .position(
                                x: positionForDragPoint(at: band.index, size: innerGeo.size),
                                y: innerGeo.size.height + 8
                            )
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }

    func positionForDragPoint(at index: Int, size: CGSize) -> CGFloat {
        size.width / 12 * CGFloat(index * 2 + 1)
    }

    func updateGainValue(at index: Int, in size: CGSize) {
        let percentage = dragPointYLocations[index] / size.height
        let gain = (1 - Float(percentage)) * (maxGain - minGain) + minGain
        eqBands[index].value = gain
    }

    func gainToYPosition(at gain: Float, in size: CGSize) -> CGFloat {
        let percentage = 1 - (gain - minGain) / (maxGain - minGain)
        return CGFloat(percentage) * size.height
    }

    func resetPositions(in size: CGSize) {
        let values = eqBands.map { gainToYPosition(at: $0.value, in: size) }
        withAnimation(.easeInOut(duration: 0.2)) {
            dragPointYLocations = values
        }
    }
}

struct EQGlobalGainSlider: View {
    @Default(.globalGain) var globalGain

    @State private var gain: Double = 0

    @ObservedObject private var pttManager = PushTalkManager.shared
    // 配置常量
    private let minGain: Double = -24.0
    private let maxGain: Double = 24.0
    private let alertGain: Double = 12.0 // 超过 12dB 变红

    var body: some View {
        VStack(spacing: 20) {
            // 头部数据读数
            HStack(alignment: .lastTextBaseline) {
                Text("音量增益")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(verbatim: String(format: "%.1f", gain))
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(gain > alertGain ? .red : (gain < 0 ? .yellow : .green))
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.2), value: gain)
                Text(verbatim: "dB")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 5)

            // 自定义滑块核心组件
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let centerPoint = width / 2

                let currentX = CGFloat((gain - minGain) / (maxGain - minGain)) * width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: height)

                    if gain < 0 {
                        Capsule()
                            .fill(Color.yellow)
                            .frame(width: centerPoint - currentX, height: height)
                            .offset(x: currentX)
                    } else if gain > 0 {
                        if gain <= alertGain {
                            Capsule()
                                .fill(Color.green)
                                .frame(width: currentX - centerPoint, height: height)
                                .offset(x: centerPoint)
                        } else {
                            let alertX = CGFloat((alertGain - minGain) / (maxGain - minGain)) *
                                width

                            Capsule()
                                .fill(Color.green)
                                .frame(width: alertX - centerPoint, height: height)
                                .offset(x: centerPoint)

                            Capsule()
                                .fill(Color.red)
                                .frame(width: currentX - alertX, height: height)
                                .offset(x: alertX)
                        }
                    }

                    Rectangle()
                        .fill(Color(.systemBackground).opacity(0.8))
                        .frame(width: 3, height: height + 6)
                        .position(x: centerPoint, y: height / 2)

                    let alertLineX = CGFloat((alertGain - minGain) / (maxGain - minGain)) * width
                    Rectangle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 2, height: height + 2)
                        .position(x: alertLineX, y: height / 2)

                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .frame(width: height * 2.5, height: height * 2.5)
                        .position(x: currentX, y: height / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let boundedX = min(max(0, value.location.x), width)
                                    let percentage = Double(boundedX / width)
                                    let calculatedGain = minGain + percentage * (maxGain - minGain)
                                    self.gain = (calculatedGain * 10).rounded() / 10
                                }
                                .onEnded { _ in
                                    self.globalGain = gain
                                    pttManager.changeEQ()
                                }
                        )
                }
            }
            .frame(height: 12)
            .padding(.vertical, 10)

            HStack {
                HStack {
                    Text(verbatim: "\(Int(minGain))dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture { quickSet(minGain) }
                    Spacer()
                }
                Spacer()
                HStack {
                    Text(verbatim: "0dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .offset(x: -15)
                        .onTapGesture { quickSet(0.0) }
                    Spacer()
                    Text(verbatim: "12dB")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                        .onTapGesture { quickSet(12.0) }
                    Spacer()
                    Text(verbatim: "\(Int(maxGain))dB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onTapGesture { quickSet(maxGain) }
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            self.gain = globalGain
        }
    }

    func quickSet(_ value: Double) {
        self.globalGain = value
        self.gain = value
        pttManager.changeEQ()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        EQGlobalGainSlider()
    }
}
