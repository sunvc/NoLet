//
//  NotificationViewController.swift
//  MarkdownExtension
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//   Created by Neo on 2025/6/2.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import cmark_gfm
import cmark_gfm_extensions
import WebKit
import Defaults

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var tipsView: UILabel!
    @IBOutlet var web: WKWebView!
    
    var scrollViewHeight:CGFloat = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tipsView.text = ""
        tipsView.adjustsFontForContentSizeCategory = true
        tipsView.textAlignment = .center
        tipsView.font = UIFont.preferredFont(ofSize: 16)
        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
        
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.preferredContentSize = CGSize(width: view.bounds.width, height: 1) // 初始高度
        
        // 监听 WKWebView 高度变化
        web.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        

    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let scrollView = object as? UIScrollView {
            
            if scrollView.contentSize.height > self.preferredContentSize.height{
                self.preferredContentSize = CGSize(width: self.view.bounds.width, height: max(10, scrollView.contentSize.height +  tipsView.bounds.height))
                
                scrollViewHeight = scrollView.contentSize.height
            }
            
        }
    }

    deinit {
        web.scrollView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    
    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
    
        
        if let body:String = userInfo.raw(Params.body),
           let htmlContent = convertMarkdownToHTML(body),
           let cssPath = Bundle.main.path(forResource: "markdown", ofType: "css") {
            let baseURL = URL(fileURLWithPath: cssPath).deletingLastPathComponent()
            web.loadHTMLString(htmlContent, baseURL:baseURL)
            
        } else {
            web.loadHTMLString("<h1>Error loading content</h1>", baseURL: nil)
        }
        web.frame = .init(x: 0, y: 0, width: self.view.bounds.width, height: web.frame.height)
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: tipsView.bounds.height + web.bounds.height)
    }
    
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let action = Identifiers.Action(rawValue: response.actionIdentifier){
            switch action {
            case .copyAction:
                if let copy = userInfo[Params.copy.name] as? String {
                    UIPasteboard.general.string = copy
                } else {
                    UIPasteboard.general.string = response.notification.request.content.body
                }
                showTips(text:String(localized: "复制成功"))
            case .muteAction:
                let group = response.notification.request.content.threadIdentifier
                Defaults[.muteSetting][group] = Date().addingTimeInterval(60 * 60)
                showTips(text:  String(localized: "[\(group)]分组静音成功"))
            }
        }
        completion(.doNotDismiss)
    }
    
    func showTips(text: String) {
        Haptic.impact()
        tipsView.text = text
        tipsView.frame = CGRect(x: 0, y: 0,
                                     width: view.bounds.width,
                                     height: 35)
        view.addSubview(tipsView)
        
        web.frame = CGRect(x: 0, y:  tipsView.bounds.height, width: view.bounds.width, height: scrollViewHeight)
        
        preferredContentSize = CGSize(width: view.bounds.width, height:  tipsView.bounds.height + scrollViewHeight)
        
    }

    
    private func convertMarkdownToHTML(_ markdown: String) -> String? {
       
        guard let htmlBody = PBMarkdown.markdownToHTML(markdown) else { return nil }
        return """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

            <link rel="stylesheet" type="text/css" href="markdown.css">
             <style>
                  body { font-family: -apple-system; padding: 10px; color: #333; background: #fff; }
                  img { max-width: 100%; height: auto; background: #ff0000;border-radius: 10px;}
                  pre { background: #f4f4f4; padding: 10px; overflow-x: auto; border-radius: 5px; }
                  code { font-family: monospace; color: #d63384; }
                  blockquote { color: #6a737d; padding-left: 10px; border-left: 4px solid #dfe2e5; }
                  h1, h2, h3 { color: #0056b3; }
                  @media (prefers-color-scheme: dark) {
                      body { background: #121212; color: #ffffff}
                      pre { background: #1e1e1e; }
                      blockquote { color: #bbb; border-left-color: #444; }
                      h1, h2, h3 { color: #4da3ff; }
                  }
             </style>
        </head>
        <body>
        <article class="markdown-body">
            \(htmlBody)
        </article>
        </body>
        </html>
        """
    }
    
}
