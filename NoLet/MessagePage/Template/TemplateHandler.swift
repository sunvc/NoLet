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
    var showAvatar: Bool = true
    var assistantAccounsCount: Int
    var selectID: String? = nil
    var delete: () -> Void

    var body: some View {
        switch message.style {
        case "markdown":
            MarkdownMessageView(
                message: message,
                searchText: searchText,
                showAvatar: showAvatar,
                assistantAccounsCount: assistantAccounsCount,
                delete: delete
            )
        default:
            PlainMessageView(
                message: message,
                searchText: searchText,
                assistantAccouns: assistantAccounsCount,
                delete: delete
            )
        }
    }
}
