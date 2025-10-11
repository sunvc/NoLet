//
//  MessageHandler.swift
//  pushback
//
//  Created by uuneo 2024/11/23.
//

import Foundation
import Defaults
import UserNotifications


class ArchiveMessageHandler: NotificationContentHandler{
    
    func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        
        
        let userInfo = bestAttemptContent.userInfo
        
        var body:String =  {
            if let body:String = userInfo.raw(.body){
                /// 解决换行符渲染问题
                return MessagesManager.ensureMarkdownLineBreaks(body)
            }
           return ""
        }()
        
        // MARK: - markdownbody body 显示
        if bestAttemptContent.categoryIdentifier == Identifiers.markdown.rawValue{
            let plainText = PBMarkdown.plain(body).components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .joined(separator: ",")
                .replacingOccurrences(of: "\n", with: "")
            
            bestAttemptContent.body = plainText.count > 15 ? String(plainText.prefix(15)) + "..." : plainText
        }
        
        
        let group:String = userInfo.raw(.group) ?? String(localized: "默认")
        bestAttemptContent.threadIdentifier = group
        
        let ttl:String? = userInfo.raw(.ttl)
        let title:String? = userInfo.raw(.title)
        let subtitle:String? = userInfo.raw(.subtitle)
        let url:String? = userInfo.raw(.url)
        let icon:String? = userInfo.raw(.icon)
        let image:String? = userInfo.raw(.image)
        let host:String? = userInfo.raw(.host)
        let messageId = bestAttemptContent.targetContentIdentifier
        let level =  bestAttemptContent.getLevel()
        let other = userInfo.toJSONString(excluding: Params.allCases.allString())


        //  获取保存时间
        var saveDays:Int {
            if let isArchive = ttl, let saveDaysTem = Int(isArchive){
                return saveDaysTem
            }else{
                return Defaults[.messageExpiration].days
            }
        }
        
        Defaults[.allMessagecount] += 1
        
        guard title != nil || subtitle != nil || !body.isEmpty else  {
            bestAttemptContent.interruptionLevel = .passive
            return bestAttemptContent
        }
        
       
        if let count:Int = userInfo.raw(.count), let index:Int = userInfo.raw(.index), let messageId{

            Defaults[.moreMessageCache].append(MoreMessage(createDate: .now, id: messageId, body: body, index: index, count: count))
            
            var datas = Defaults[.moreMessageCache].filter({$0.id == messageId})
            
            datas.sort(by: {$0.index < $1.index})
            let content = datas.reduce("") { $0 + $1.body }
            body = content
            bestAttemptContent.body = content
            
            if datas.count == count {
                
                Defaults[.moreMessageCache].removeAll(where: {$0.id == messageId})
                
            }else{
                bestAttemptContent.interruptionLevel = .passive
                return bestAttemptContent
            }
            
        }
        
        guard saveDays > 0 else { return bestAttemptContent }
        
        //  保存数据到数据库
        let message = Message(id: messageId ?? UUID().uuidString, group: group,
                              createDate: .now, title: title, subtitle: subtitle,
                              body: body, icon: icon, url: url, image: image,
                              host: host, level: Int(level), ttl: saveDays, read: false, other: other)
        
        
        Task.detached(priority: .userInitiated) {
            await MessagesManager.shared.add(message)
        }
        
        return bestAttemptContent
    }
    
}
