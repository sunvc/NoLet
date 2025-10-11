//
//  AppDelegate.swift
//  pushme
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import Defaults
import AVFAudio
import CloudKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate{
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
       
        Identifiers.setCategories()
        // 预防用户切换系统语言导致语言不匹配
        Multilingual.resetTransLang()
        
        if !Defaults[.firstStart] {
            Task{
                await AppManager.shared.registerForRemoteNotifications()
            }
            
        }

        if Defaults[.id] == ""{
            Defaults[.id] = KeychainHelper.shared.getDeviceID()
        }

        return true
    }
    
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        Defaults[.deviceToken] = token
        Task.detached(priority: .userInitiated) {
            _ = await CloudManager.shared.queryUser(token: token)
        }
        
        let manager = AppManager.shared
        if Defaults[.servers].count == 0{
            Task.detached(priority: .userInitiated) {
                if !manager.customServerURL.isEmpty{
                    _ = await manager.appendServer(server: PushServerModel(url: manager.customServerURL))
                }else{
                    _ = await manager.appendServer(server: PushServerModel(url: BaseConfig.defaultServer))
                }

            }
        }else{
            manager.registers()
        }
    }
    
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        
        return sceneConfiguration
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let content = response.notification.request.content
        
        
        DispatchQueue.main.async{
            AppManager.shared.page = .message
            AppManager.shared.router = []
            AppManager.shared.selectId = response.notification.request.content.targetContentIdentifier
            AppManager.shared.selectGroup = content.threadIdentifier
        }
        
        notificatonHandler(userInfo: content.userInfo)
        
        // 清除通知中心的显示
        center.removeDeliveredNotifications(withIdentifiers: [content.threadIdentifier])
        
        
        completionHandler()
    }
   
    
    
    // 处理应用程序在前台是否显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 由于Sqlit 底层通知延迟，手动更新
        Task.detached(priority: .background) {
            await  MessagesManager.shared.updateGroup()
        }
        
        if notification.request.content.interruptionLevel.rawValue > 1{
            completionHandler([.banner])
        }else{
            completionHandler(.badge)
        }
        Haptic.impact(.light)

        notificatonHandler(userInfo: notification.request.content.userInfo)
    }
    
    func notificatonHandler(userInfo: [AnyHashable : Any]){
        if let urlStr = userInfo[Params.url.name] as? String, let url = URL(string: urlStr) {
            AppManager.openUrl(url: url)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        DispatchQueue.main.async{
            AppManager.shared.page = .setting
            AppManager.shared.router = [.more]
        }
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let id:String = userInfo.raw(.id), let group = MessagesManager.shared.delete(id) {
            UNUserNotificationCenter.current()
                .removeDeliveredNotifications(withIdentifiers: [group])
        }
        
    
        
        Task{
            await AppManager.shared.registerForRemoteNotifications()
        }
        
        completionHandler(.newData)
        
    }
    

    
}
