//
//  SceneDelegate.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/2.
//

import Defaults
import GRDB
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var overlayWindow: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let hosting = UIHostingController(rootView: ContentView())

        window?.rootViewController = hosting
        window?.makeKeyAndVisible()
        // 2. 添加 overlay window（如 Toast 层）
        if overlayWindow == nil {
            let overlay = PassthroughWindow(windowScene: windowScene)
            overlay.backgroundColor = .clear

            let toastController = UIHostingController(rootView: ToastGroup())
            toastController.view.backgroundColor = .clear
            toastController.view.frame = windowScene.coordinateSpace.bounds

            overlay.rootViewController = toastController
            overlay.isHidden = false
            overlay.isUserInteractionEnabled = true
            overlayWindow = overlay
        }

        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            // 处理这个 URL
            _ = AppManager.shared.HandlerOpenURL(url: url.absoluteString)
        } else if let shortcutItem = connectionOptions.shortcutItem {
            _ = AppManager.runQuick(shortcutItem.type)
        }
    }

    func windowScene(
        _: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem
    ) async -> Bool {
        return AppManager.runQuick(shortcutItem.type)
    }

    func sceneDidBecomeActive(_: UIScene) {
        setLangAssistantPrompt()
    }

    func sceneWillResignActive(_: UIScene) {}

    func sceneWillEnterForeground(_: UIScene) {
        _syncAppInfo()
    }

    func sceneDidEnterBackground(_: UIScene) {
        UIApplication.shared.shortcutItems = QuickAction
            .allShortcutItems(showAssistant: Defaults[.assistantAccouns].count > 0)
        
        _syncAppInfo()

        Task { @MainActor in
            let unread = MessagesManager.shared.unreadCount
            UNUserNotificationCenter.current().setBadgeCount(unread)
        }
    }

    private var syncTask: Task<Void, Never>?
    func _syncAppInfo() {
        syncTask?.cancel()
        syncTask = Task.detached(name: "sceneWillEnterForeground", priority: .background) {
            await MessagesManager.shared.deleteExpired()
            await AppManager.syncServer()
            await NoLetChatManager.shared.clearunuse()
        }
    }

    func setLangAssistantPrompt() {
        if let currentLang = Locale.preferredLanguages.first {
            if Defaults[.lang] != currentLang {
                let prompts = ChatPromptMode.prompts
                Task.detached(priority: .background) {
                    try await DatabaseManager.shared.dbQueue.write { db in
                        // 删除 inside == true 的项
                        try ChatPrompt.filter(ChatPrompt.Columns.inside == true).deleteAll(db)

                        // 添加默认 prompts
                        for prompt in prompts {
                            try prompt.insert(db)
                        }

                        // 回到主线程设置语言
                        DispatchQueue.main.async {
                            Defaults[.lang] = currentLang
                        }
                    }
                }
            }
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = AppManager.shared.HandlerOpenURL(url: url.absoluteString)
    }
}

extension QuickAction {
    static func allShortcutItems(showAssistant: Bool) -> [UIApplicationShortcutItem] {
        var items = [UIApplicationShortcutItem(
            type: Self.scan.rawValue,
            localizedTitle: String(localized: "扫描二维码"),
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "qrcode.viewfinder"),
            userInfo: ["name": assistant.rawValue as NSSecureCoding]
        )]

        if showAssistant {
            items.insert(UIApplicationShortcutItem(
                type: Self.assistant.rawValue,
                localizedTitle: String(localized: "问智能助手"),
                localizedSubtitle: "",
                icon: UIApplicationShortcutIcon(systemImageName: "message.and.waveform"),
                userInfo: ["name": scan.rawValue as NSSecureCoding]
            ), at: 0)
        }
        return items
    }
}

class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else { return nil }

        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                /// Finding if any of rootview's is receving hit test
                let pointInSubView = subview.convert(point, from: rootView)
                if subview.point(inside: pointInSubView, with: event) {
                    return hitView
                }
            }

            return nil
        } else {
            return hitView == rootView ? nil : hitView
        }
    }
}

enum QuickAction: String, CaseIterable {
    static var selectAction: UIApplicationShortcutItem?
    case assistant
    case scan
}
