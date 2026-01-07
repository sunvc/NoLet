//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChatQuery+.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/6 22:43.

import Foundation
import OpenAI

typealias ReasoningEffort = ChatQuery.ReasoningEffort

extension ReasoningEffort:  @retroactive Hashable {
    var rawValue: String {
        switch self {
        case .none: return "none"
        case .minimal: return "minimal"
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .customValue(let value): return value
        }
    }

    static func allCases(_ value: String) -> [ReasoningEffort] {
        [.none, .minimal, .low, .medium, .high]
    }

    public var level: Int {
        switch self {
        case .none: 0
        case .minimal: 1
        case .low: 2
        case .medium: 3
        case .high: 4
        case .customValue: 5
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .none
        case "minimal": self = .minimal
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        default: self = .customValue(rawValue)
        }
    }

    var symbol: String {
        switch self {
        case .none: "bolt.slash"
        case .minimal: "bolt.slash"
        case .low: "gauge.low"
        case .medium: "gauge.medium"
        case .high: "gauge.high"
        case .customValue: "gauge.medium.badge.plus"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(level)
    }
    
    var emptyData: Bool{
        self == .none || self == .minimal
    }
}
