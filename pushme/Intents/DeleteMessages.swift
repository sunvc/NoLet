//
//  DeleteMessages.swift
//  pushback
//
//  Created by lynn on 2025/4/14.
//

import AppIntents
import SwiftUI
import GRDB

struct DeleteMessageIntent: AppIntent {
    
    static var title: LocalizedStringResource = "删除消息"
    static var openAppWhenRun: Bool = false
    
    
    @Parameter(title: "日期")
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("删除 \(\.$date) 之前的消息")
    }
    
    @MainActor
    func perform()  async throws -> some IntentResult {
        do {
           _ = try await DatabaseManager.shared.dbQueue.write { db in
                try Message
                   .filter(Message.Columns.createDate < date)
                    .deleteAll(db)
            }
        } catch {
            NLog.error("❌ 删除旧消息失败: \(error)")
        }
        return .result()
    }
}
