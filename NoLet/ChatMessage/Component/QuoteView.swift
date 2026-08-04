//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - QuoteView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/15 13:42.

import Foundation
import SwiftUI

extension ReasoningEffort {
    static func allCases(_ value: String) -> [ReasoningEffort] {
        [.none, .minimal, .low, .medium, .high]
    }

    var level: Int {
        switch self {
        case .none: 0
        case .minimal: 1
        case .low: 2
        case .medium: 3
        case .high: 4
        case .customValue: 5
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

    var emptyData: Bool {
        self == .none || self == .minimal
    }
}


struct QuoteView: View {
    var message: String

    var body: some View {
        HStack(spacing: 5) {
            Text(verbatim: "\(message.removingAllWhitespace)")
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.caption2)

            Image(systemName: "quote.bubble")
                .foregroundColor(.gray)
                .padding(.leading, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MCPResultView: View {
    var text: String

    var body: some View {
        HStack {
            Text(verbatim: text)
            Spacer(minLength: 0)
        }
        .padding(.vertical)
        .padding(.horizontal, 10)
        .background26(.ultraThinMaterial)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 10,
            bottomTrailingRadius: 10,
            topTrailingRadius: 0,
            style: .continuous
        ))
    }
}
