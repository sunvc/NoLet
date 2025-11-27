//
//  RouterExtension.swift
//  pushme
//
//  Created by AI Assistant 2024/05/29.
//

import SwiftUI

extension View {
    @ViewBuilder
    func router(_: AppManager) -> some View {
        navigationDestination(for: RouterPage.self) { page in
            switch page {
            case .server:
                ServersConfigView()
            case .crypto:
                CryptoConfigListView()
            case .sound:
                SoundView()
            case .more:
                MoreOperationsView()
            case let .widget(title, data):
                Text(title ?? "Widget")
            case let .assistantSetting(account):
                Text("Assistant Setting")
            case .about:
                AboutNoLetView()
            }
        }
    }
}
