//
//  AppShortcutsProvider.swift
//  pushback
//
//  Created by lynn on 2025/4/14.
//

import AppIntents


class PushbackShortcuts:  AppShortcutsProvider, @unchecked Sendable {
    

    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: DeleteMessageIntent(), phrases:
                        [ "清除\(.applicationName)" ],
                    shortTitle:  "清除过期通知",
                    systemImageName: "trash"
        )
        
        AppShortcut(intent: EasyPushIntent(), phrases:
                        [ "\(.applicationName)" ],
                    shortTitle:  "快速通知",
                    systemImageName: "ellipsis.message"
        )
        
    }
}
