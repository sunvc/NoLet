//
//  DeleteMessages.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/4/14.
//

import AppIntents
import SwiftUI

struct DeleteMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "删除消息"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "日期")
    var date: Date

    static var parameterSummary: some ParameterSummary {
        Summary("删除 \(\.$date) 之前的消息")
    }


    func perform() async throws -> some IntentResult {
        do {
            try await MessageDBManager.shared.delete(beforeDate: date)
        } catch {
            logger.error("删除旧消息失败: \(error)")
        }
        return .result()
    }
}
