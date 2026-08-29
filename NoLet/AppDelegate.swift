//
//  AppDelegate.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/2.
//

import AVFAudio
import CloudKit
import Defaults
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, @MainActor UNUserNotificationCenterDelegate {
    
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Defaults[.member].id = IDManager.id
        UNUserNotificationCenter.current().delegate = self
        Identifiers.setCategories()
        Multilingual.resetTransLang()

        // FIXME: - 修复MAC不能使用PushToTalk崩溃
        if .isiOSAppOnMac {
            Defaults[.usePtt] = false
        }

        LocManager.shared.startMonitoringLocationPushes { token in
            Defaults[.member].location = token
        }

        if !.isiOSAppOnMac {
            Task {
                try await PTTChannelManager.shared.start()
            }
        }

        Task {
            if !Defaults[.firstStart] {
                await AppManager.shared.registerForRemoteNotifications()
            }
        }

        WeChatManager.shared.register()

        return true
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        Defaults[.member].token = token

        Task.detached(priority: .userInitiated) {
            if Defaults[.servers].count == 0 {
                if await !AppManager.shared.customServerURL.isEmpty {
                    _ = await AppManager.shared
                        .appendServer(server:
                            PushServerModel(url: AppManager.shared.customServerURL)
                        )
                } else {
                    _ = await AppManager.shared.appendServer(server:
                        PushServerModel(url: NCONFIG.server)
                    )
                }
            } else {
                await AppManager.shared.registers()
                await AppManager.shared.register( deviceKey: IDManager.id)
            }

            try await Defaults[.member].save(to: NCONFIG.publicCloudDatabase)

            try? await PushServerModel.registerChangesSubscription()
        }

        logger.info("获取到设备Token: \(token)")
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )

        return sceneConfiguration
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content

        Task {
            AppManager.shared.page = .message
            AppManager.shared.router = []
            AppManager.shared.selectID = response.notification.request.content
                .targetContentIdentifier
            AppManager.shared.selectGroup = content.threadIdentifier
        }

        notificatonHandler(userInfo: content.userInfo)

        center.removeDeliveredNotifications(withIdentifiers: [content.threadIdentifier])

        completionHandler()
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
            -> Void
    ) {
        Haptic.impact(.light)
        notificatonHandler(userInfo: notification.request.content.userInfo)
        completionHandler([.banner])
    }

    func notificatonHandler(userInfo: [AnyHashable: Any]) {
        if let urlStr = userInfo.raw(.url, as: String.self),
           let url = URL(string: urlStr)
        {
            AppManager.openURL(url: url, .safari)
        }
    }

    func userNotificationCenter(_: UNUserNotificationCenter, openSettingsFor _: UNNotification?) {
        Task {
            AppManager.shared.page = .setting
            AppManager.shared.router = [.more]
        }
    }

    func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)
            -> Void
    ) {
        Task {
            PushServerModel.subHandler(userInfo) {
                await AppManager.syncServer()
            }
            await MessagesManager.shared.delete(userInfo)
            await AppManager.shared.registerForRemoteNotifications()
            completionHandler(.newData)
        }
    }
}
