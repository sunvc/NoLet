//
//  NotificationViewController.swift
//  MarkdownExtension
//
//  Created by Neo on 2025/6/2.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import WebKit
import Defaults

class NotificationViewController: UIViewController, UNNotificationContentExtension, WKNavigationDelegate {

    @IBOutlet weak var tipsView: UILabel!
    @IBOutlet var web: WKWebView!

    private var markdownHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tips View
        tipsView.text = ""
        tipsView.textAlignment = .center
        tipsView.adjustsFontForContentSizeCategory = true
        tipsView.font = UIFont.preferredFont(ofSize: 16)
        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
        
        // Web
        web.navigationDelegate = self
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false  
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.contentInset = .zero
        web.scrollView.scrollIndicatorInsets = .zero

        preferredContentSize = CGSize(width: view.bounds.width, height: 10)
    }

    // MARK: - Notification
    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        guard let body:String = userInfo.raw(Params.body),
              let html = convertMarkdownToHTML(body),
              let cssPath = Bundle.main.path(forResource: "markdown", ofType: "css") else {

            web.loadHTMLString("<h1>Error loading content</h1>", baseURL: nil)
            return
        }

        let baseURL = URL(fileURLWithPath: cssPath).deletingLastPathComponent()
        web.loadHTMLString(html, baseURL: baseURL)
    }

    // MARK: - WebView Height
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        // 延时执行一次，避免还在动态布局
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, error in
                guard let self = self, let height = result as? CGFloat else { return }
                self.updateLayout(webHeight: height)
            }
        }
    }

    private func updateLayout(webHeight: CGFloat) {
        self.markdownHeight = webHeight

        let tipsHeight = tipsView.bounds.height

        web.frame = CGRect(x: 0, y: tipsHeight, width: view.bounds.width, height: webHeight)

        preferredContentSize = CGSize(
            width: view.bounds.width,
            height: tipsHeight + webHeight
        )
    }

    // MARK: - Actions

    func didReceive(_ response: UNNotificationResponse,
                    completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {

        let userInfo = response.notification.request.content.userInfo

        if let action = Identifiers.Action(rawValue: response.actionIdentifier) {

            switch action {
            case .copyAction:
                if let copy = userInfo[Params.copy.name] as? String {
                    UIPasteboard.general.string = copy
                } else {
                    UIPasteboard.general.string = response.notification.request.content.body
                }
                showTips(text: String(localized: "复制成功"))

            case .muteAction:
                let group = response.notification.request.content.threadIdentifier
                Defaults[.muteSetting][group] = Date().addingTimeInterval(3600)
                showTips(text: String(localized: "[\(group)]分组静音成功"))
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

        updateLayout(webHeight: markdownHeight)
    }

    // MARK: - Markdown → HTML
    private func convertMarkdownToHTML(_ markdown: String) -> String? {

        guard let htmlBody = PBMarkdown.markdownToHTML(markdown) else { return nil }

        return """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <link rel="stylesheet" type="text/css" href="markdown.css">

            <style>
                body { font-family: -apple-system; padding: 0; margin: 0; color: #333; background: #fff; }
                img { max-width: 100%; height: auto; border-radius: 10px; }
                pre { background: #f4f4f4; padding: 10px; border-radius: 8px; overflow-x: auto; }
                code { font-family: monospace; color: #d63384; }
                blockquote { color: #6a737d; padding-left: 10px; border-left: 4px solid #dfe2e5; }
                h1, h2, h3 { color: #0056b3; }

                @media (prefers-color-scheme: dark) {
                    body { background: #121212; color: #fff; }
                    pre { background: #1e1e1e; }
                    blockquote { border-left-color: #444; }
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

// MARK: - Dynamic Font Extension
extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}

