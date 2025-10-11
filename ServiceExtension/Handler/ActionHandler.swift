//
//  ActionHandler.swift
//  pushback
//
//  Created by uuneo 2024/11/14.
//

import Foundation
import Intents
import Defaults
import SwiftUI
import cmark_gfm
import UserNotifications

class ActionHandler: NotificationContentHandler{
	
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        // MARK: - 处理 Ringtone
        let call:Int? = bestAttemptContent.userInfo.raw(.call)
        if  call != 1, bestAttemptContent.soundName == nil, bestAttemptContent.getLevel() < 3{
            bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(Defaults[.sound]).caf" ))
        }
		
		// MARK: - 处理 badge
		switch Defaults[.badgeMode] {
		case .auto:
			// MARK: 通知角标 .auto
            bestAttemptContent.badge = NSNumber(value:  MessagesManager.shared.unreadCount())
			
        case .custom:
            // MARK: 通知角标 .custom
            if let badgeStr:String = bestAttemptContent.userInfo.raw(.badge), let badge = Int(badgeStr) {
                bestAttemptContent.badge = NSNumber(value: badge)
            }
        }
        

		// MARK: - 删除过期消息
        await MessagesManager.shared.deleteExpired()
        
        // MARK: - 静音分组
        for setting in Defaults[.muteSetting] {
            if setting.value < Date() {
                Defaults[.muteSetting].removeValue(forKey: setting.key)
            }
        }

        if let date = Defaults[.muteSetting][bestAttemptContent.threadIdentifier], date > Date(){
            bestAttemptContent.interruptionLevel = .passive
        }
        
        // MARK: -  回调
        if let host:String = bestAttemptContent.userInfo.raw(.host),
           let id = bestAttemptContent.targetContentIdentifier{
            let http = NetworkManager()
            if let url = http.appendQueryParameter(to: host.hasHttp() ? host : "https://\(host)", key: "id", value: id){
                await http.fetchVoid(url: url)
            }
            
        }
    
        
        if let widget:String = bestAttemptContent.userInfo.raw(.widget), let _ = URL(string: widget){
            Defaults[.widgetURL] = widget
        }
        
        let mores = Defaults[.moreMessageCache]
        if mores.count > 0{
            let oneHourAgo = Date().addingTimeInterval(-3600)
            Defaults[.moreMessageCache].removeAll { message in
                message.createDate < oneHourAgo
            }
        }
        
        
       
        
        return bestAttemptContent
        
    
	}
    
}
