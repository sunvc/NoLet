//
//  AppShortcutsProvider.swift
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

class NoLetShortcuts: AppShortcutsProvider, @unchecked Sendable {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DeleteMessageIntent(),
            phrases:
            ["清除\(.applicationName)"],
            shortTitle: "清除过期通知",
            systemImageName: "trash"
        )
    }
}
