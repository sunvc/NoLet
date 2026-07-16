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

import SwiftUI

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
