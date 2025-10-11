//
//  SceneDelegate.swift
//  pushme
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import SwiftUI
import WidgetKit
import GRDB
import Defaults


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var overlayWindow: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let hosting = UIHostingController(rootView: ContentView())
       
        self.window?.rootViewController = hosting
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
            overlay.tag = 1009
            
            overlayWindow = overlay
        }
        
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            // 处理这个 URL
            _ = AppManager.shared.HandlerOpenUrl(url: url.absoluteString)
        }
        
    }
    
    
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        let manager = AppManager.shared
        
        switch QuickAction(rawValue: shortcutItem.type.lowercased()){
        case .assistant:
            manager.page = .message
            manager.router = [.assistant]
        case .scan:
            manager.page = .setting
            manager.router = []
            manager.fullPage = .scan
        default:
            break
        }
        
        completionHandler(true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {  }

    func sceneDidBecomeActive(_ scene: UIScene) {

        let manager = AppManager.shared
        if !manager.isWarmStart{
            NLog.log("❄️ 冷启动")
            manager.isWarmStart = true
            openChatManager.shared.clearunuse()
        }
        Task.detached(priority: .userInitiated) {
            await MessagesManager.shared.updateGroup()
        }
        
        
        setLangAssistantPrompt()
        
    }

    func sceneWillResignActive(_ scene: UIScene) {  }

    func sceneWillEnterForeground(_ scene: UIScene) {


        UIApplication.shared.shortcutItems = QuickAction.allShortcutItems(showAssistant: Defaults[.assistantAccouns].count > 0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        WidgetCenter.shared.reloadAllTimelines()
        Task.detached(priority: .userInitiated) {
            await MessagesManager.shared.deleteExpired()
            let unread = MessagesManager.shared.unreadCount()
            try await UNUserNotificationCenter.current().setBadgeCount(unread)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) { }

    
    func setLangAssistantPrompt(){
        if let currentLang  = Locale.preferredLanguages.first{
           
            if Defaults[.lang] != currentLang{
                Task.detached(priority: .background) {
                    try await DatabaseManager.shared.dbQueue.write { db in
                        // 删除 inside == true 的项
                        try ChatPrompt.filter(ChatPrompt.Columns.inside == true).deleteAll(db)
                        
                        // 添加默认 prompts
                        for prompt in ChatPrompt.prompts {
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
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = AppManager.shared.HandlerOpenUrl(url: url.absoluteString)
    }
}


