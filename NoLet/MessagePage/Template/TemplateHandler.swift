//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - MessageTemplateHandler.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/18 21:37.

import SwiftUI

struct MessageCardView: View {
    var message: Message
    var searchText: String = ""
    var showGroup: Bool = true
    var showAllTTL: Bool = false
    var assistantAccounsCount: Int
    var selectID: String? = nil
    var delete: () -> Void

    var focusColor: Color {
        guard let selectID = selectID else {
            return .clear
        }
        return selectID.uppercased() == message.id.uppercased() ? .orange : .clear
    }

    private var messageConfig: MessageCardConfiguration {
        MessageCardConfiguration(
            searchText: searchText,
            showGroup: showGroup,
            showAllTTL: showAllTTL,
            accounts: assistantAccounsCount,
            selectID: selectID,
            delete: delete,
            focusColor: focusColor
        )
    }

    var body: some View {
        switch message.style?.lowercased() {
        case "markdown":
            MarkdownMessageCard(message: message, config: messageConfig)

        case "terminal":
            TerminalMessageCard(message: message, config: messageConfig)

        case "github":
            GitHubMessageCard(message: message, config: messageConfig)

        case "pay":
            PaymentMessageCard(message: message, config: messageConfig)

        default:
            PlainMessageCard(message: message, config: messageConfig)
        }
    }
}

protocol MessageCardProtocol: View {
    // 1. 核心数据源
    var message: Message { get }
    var config: MessageCardConfiguration { get }
}

struct MessageCardConfiguration {
    var searchText: String = ""
    var showGroup: Bool = true
    var showAllTTL: Bool = false
    var accounts: Int = 0
    var selectID: String? = nil
    var delete: () -> Void = {}
    var focusColor: Color = .clear
}
