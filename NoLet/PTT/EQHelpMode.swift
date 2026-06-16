//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - EQHelpMode.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/16 06:33.

import Defaults
import Foundation
import SwiftUI

struct EQBand: Identifiable, Codable, Equatable {
    var id: Int { index }
    var frequency: String
    var min: Float
    var max: Float
    var value: Float
    let index: Int
}

extension EQBand: @MainActor Defaults.Serializable {}



nonisolated struct LineShape: Shape {
    var values: [Double]

    var animatableData: AnimatableLine {
        get { AnimatableLine(values: values) }
        set { values = newValue.values }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.size.width / 12, y: values.first ?? 0))
        for index in 1..<values.count {
            let x = positionForDragPoint(at: index, size: rect.size)
            let y = values[index]
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }

    func positionForDragPoint(at index: Int, size: CGSize) -> CGFloat {
        size.width / 12 * CGFloat(index * 2 + 1)
    }
}

nonisolated struct AnimatableLine: VectorArithmetic {
    var values: [Double]

    var magnitudeSquared: Double {
        return values.map { $0 * $0 }.reduce(0, +)
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    static var zero: AnimatableLine {
        return AnimatableLine(values: [0.0])
    }

    static func - (lhs: AnimatableLine, rhs: AnimatableLine) -> AnimatableLine {
        return AnimatableLine(values: zip(lhs.values, rhs.values).map(-))
    }

    static func -= (lhs: inout AnimatableLine, rhs: AnimatableLine) {
        lhs = lhs - rhs
    }

    static func + (lhs: AnimatableLine, rhs: AnimatableLine) -> AnimatableLine {
        return AnimatableLine(values: zip(lhs.values, rhs.values).map(+))
    }

    static func += (lhs: inout AnimatableLine, rhs: AnimatableLine) {
        lhs = lhs + rhs
    }
}

nonisolated enum EqualizerPreset: String, CaseIterable, Codable {
    case flat
    case bass
    case vocal
    case rock
    case pop
    case custom

    static let bandFrequencies: [Float] = [60, 230, 910, 2400, 4000, 14000]
    static let minGain: Float = -12
    static let maxGain: Float = 12

    var displayName: String {
        switch self {
        case .flat: String(localized: "原声")
        case .bass: String(localized: "低音增强")
        case .vocal: String(localized: "人声增强")
        case .rock: String(localized: "摇滚")
        case .pop: String(localized: "流行")
        case .custom: String(localized: "自定义")
        }
    }

    // 1. 将 gains 改为返回可选型，明确表达 .custom 没有固定的 gains
    var gains: [Float]? {
        switch self {
        case .flat: return [0, 0, 0, 0, 0, 0]
        case .bass: return [6, 4, 0, -1, -2, -3]
        case .vocal: return [-2, 0, 4, 5, 5, 2]
        case .rock: return [4, 2, -1, 1, 3, 5]
        case .pop: return [2, 4, 3, 2, 0, 2]
        case .custom: return nil
        }
    }

    var bands: [EQBand] {
        // 2. 使用 guard let 安全解包，优雅地避开了越界风险和硬编码判断
        guard let currentGains = self.gains else { return [] }

        // 3. 使用 zip 将频率和增益合并，天然防御两个数组长度不一致的问题
        return zip(Self.bandFrequencies, currentGains).enumerated().map { index, element in
            let (frequencyValue, gainValue) = element
            
            // 4. 优化频率字符转换，支持 2.4K 这种带小数的表现形式
            let frequencyStr: String
            if frequencyValue >= 1000 {
                let khz = frequencyValue / 1000
                // 如果能被 1 整除（如 4000 -> 4），就显示 4K；否则显示 2.4K
                frequencyStr = khz.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(khz))K" : String(format: "%.1fK", khz)
            } else {
                frequencyStr = String(Int(frequencyValue))
            }

            return EQBand(
                frequency: frequencyStr,
                min: Self.minGain,
                max: Self.maxGain,
                value: gainValue,
                index: index
            )
        }
    }

    var iconName: String {
        switch self {
        case .flat: return "slider.horizontal.3"
        case .bass: return "speaker.wave.3.fill"
        case .vocal: return "mic.fill"
        case .rock: return "guitars.fill"
        case .pop: return "music.note"
        case .custom: return "slider.vertical.3"
        }
    }
}
extension EqualizerPreset: @MainActor Defaults.Serializable{ }


extension Defaults.Keys {
    static let eqBands = Key<[EQBand]>("EQBands", default: EqualizerPreset.flat.bands)
    static let eqPreset = Key<EqualizerPreset>("EqualizerPreset", default: .flat)
    static let globalGain = Key<Double>("EqualizerGlobalGain", default: 0.0)
}
