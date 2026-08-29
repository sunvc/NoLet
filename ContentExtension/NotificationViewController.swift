//
//  NotificationViewController.swift
//  NotificationContentExtension
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//   Created by Neo on 2025/4/3.
//

import Defaults
import MapKit
import OSLog
import UIKit
import UserNotifications
import UserNotificationsUI
import WebKit

private let logger = Logger(subsystem: "app.wzs.logger", category: "NotificationViewController")

class NotificationViewController: UIViewController, @MainActor UNNotificationContentExtension,
    WKNavigationDelegate
{
    @IBOutlet var tipsView: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var web: WKWebView!

    private var markdownHeight: CGFloat = 0
    private var imageHeight: CGFloat = 0
    private var currentCategory: Identifiers?

    private var tips: String?
    private var replyText: String?

    // 翻译 / 总结
    private var resultMode: ChatPrompt.ChatPromptMode?
    private var results: [ChatPrompt.ChatPromptMode: String] = [:]
    private var originalHTML: String?
    private var sourceText: String = ""
    private var streamTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        tipsView.text = ""
        tipsView.textAlignment = .center
        tipsView.adjustsFontForContentSizeCategory = true
        tipsView.font = UIFont.preferredFont(ofSize: 16)
        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)

        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.frame = .init(x: 0, y: 0, width: view.bounds.width, height: 0)

        web.navigationDelegate = self
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.contentInset = .zero
        web.scrollView.scrollIndicatorInsets = .zero

        preferredContentSize = CGSize(width: view.bounds.width, height: 1)
    }

    // MARK: - Notification

    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        tipsView.text = ""
        tipsView.frame = .zero
        imageHeight = 0
        imageView.isHidden = true
        imageView.image = nil

        streamTask?.cancel()
        resultMode = nil
        results = [:]

        web.frame.size.width = view.bounds.width

        if let autoCopy = userInfo.raw(.autoCopy, as: Bool.self), autoCopy {
            if let copy = userInfo.raw(.copy, as: String.self) {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = notification.request.content.body
            }
        }

        let attachments = notification.request.content.attachments
        if let imageURL = attachments.first?.url {
            ImageHandler(imageURL: imageURL)
        } else {
            imageView.isHidden = true
            imageView.frame.size.height = 0
        }

        // MARK: - Markdown 渲染判断

        let category = notification.request.content.categoryIdentifier
        self.currentCategory = Identifiers(rawValue: category)

        if self.currentCategory != .myNotificationCategory,
           let body = userInfo.raw(Params.body, as: String.self),
           let html = convertMarkdownToHTML(body),
           let cssPath = Bundle.main.path(forResource: "css/markdown", ofType: "css")
        {
            self.sourceText = body
            self.originalHTML = html
            self.resultMode = nil
            let cssURL = URL(fileURLWithPath: cssPath).deletingLastPathComponent()
            web.isHidden = false
            web.loadHTMLString(html, baseURL: cssURL)
        } else {
            self.sourceText = notification.request.content.body
            self.originalHTML = nil
            self.resultMode = nil
            web.isHidden = true
            markdownHeight = 0
            web.frame = .zero
            updateLayout(webHeight: 0)
        }
    }

    // MARK: - WebView Height

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        webView
            .evaluateJavaScript("document.querySelector('.markdown-body').offsetHeight") { [
                weak self
            ] result, _ in
                guard let self = self, let height = result as? CGFloat else { return }
                self.updateLayout(webHeight: height + 10)
            }
    }

    private func updateLayout(webHeight: CGFloat) {
        markdownHeight = webHeight

        let tipsHeight = tipsView.bounds.height
        let isReply = currentCategory == .reply

        let startY: CGFloat = isReply ? 0 : tipsHeight

        imageView.frame = CGRect(
            x: 0,
            y: startY,
            width: view.bounds.width,
            height: imageHeight
        )

        web.frame = CGRect(
            x: 0,
            y: startY + imageHeight,
            width: view.bounds.width,
            height: webHeight
        )

        if isReply {
            tipsView.frame.origin.y = imageHeight + webHeight
        } else {
            tipsView.frame.origin.y = 0
        }

        preferredContentSize = CGSize(
            width: view.bounds.width,
            height: tipsHeight + imageHeight + webHeight
        )
    }

    // MARK: - Actions
    
    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption)
            -> Void
    ) {
        let content = response.notification.request.content

        if let action = Identifiers.Action(rawValue: response.actionIdentifier) {
            switch action {
            case .copyAction:
                if let copy = content.userInfo[Params.copy.name] as? String {
                    UIPasteboard.general.string = copy
                } else {
                    UIPasteboard.general.string = response.notification.request.content.body
                }
                showTips(text: String(localized: "复制成功"))

            case .muteAction:
                let group = response.notification.request.content.threadIdentifier
                Defaults[.muteSetting][group] = Date().addingTimeInterval(3600)
                showTips(text: String(localized: "[\(group)]分组静音成功"))

            case .translateAction:
                toggleResult(.translate(Defaults[.lang]))

            case .abstractAction:
                toggleResult(.abstract(Defaults[.lang]))
            }
        } else if response.actionIdentifier == Identifiers.reply.rawValue {
            guard let response = response as? UNTextInputNotificationResponse else { return }
            let text = response.userText
            guard self.replyText == nil else { return }
            self.replyText = text
            if let reply = content.userInfo.raw(.reply, as: String.self) {
                Task {
                    do {
                        showTips(text: String(localized: "正在回复..."), color: .orange)
                        let result = try await NetworkManager().fetch(url: reply + text)
                        if result.check() {
                            extensionContext?.dismissNotificationContentExtension()
                            return
                        } else {
                            showTips(
                                text: "\(String(localized: "回复失败")):\(result.header.statusCode)",
                                color: .red, afterClose: true
                            )
                        }
                    } catch {
                        showTips(
                            text: "\(String(localized: "发生错误")):\(error.localizedDescription)",
                            color: .red, afterClose: true
                        )
                    }
                    self.replyText = nil
                }
            }
        } else if let action = Defaults[.customNotificationCategories]
            .queryAction(identifier: response.actionIdentifier),
            let scriptName = action.scriptName
        {
            
            let data = ScriptParams(values: content.userInfo, actionMode: response.actionIdentifier)
            
            Task { 
                showTips(text: String(localized: "执行脚本中"), afterClose: false)
    
                let result = await ScriptManager.shared.actionHandler(
                    scriptName,
                    params: data.values
                )
                switch result {
                case .success(_):
                    showTips(text: String(localized: "执行成功"), afterClose: true)
                case .failure(let error):
                    showTips(text: error.localizedDescription, afterClose: true)
                }
            }
        }

        completion(.doNotDismiss)
    }

    func showTips(text: String, color: UIColor = .tintColor, afterClose: Bool = false) {
        self.tips = text
        Haptic.impact()
        tipsView.text = text
        tipsView.textColor = color
        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 35)

        updateLayout(webHeight: markdownHeight)
        if afterClose {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.tips == text {
                    self.tipsView.text = ""
                    self.tipsView.frame = .zero
                    self.updateLayout(webHeight: self.markdownHeight)
                }
            }
        }
    }

    // MARK: - 翻译 / 总结

    private func toggleResult(_ mode: ChatPrompt.ChatPromptMode) {
        // 再次点击当前模式 → 还原原文
        if resultMode == mode {
            streamTask?.cancel()
            resultMode = nil
            if let originalHTML {
                web.isHidden = false
                web.loadHTMLString(originalHTML, baseURL: cssBaseURL())
            } else {
                web.isHidden = true
                updateLayout(webHeight: 0)
            }
            return
        }

        streamTask?.cancel()
        resultMode = mode

        let lang = Defaults[.lang]

        let text: String
        if case .abstract = mode {
            text = sourceText.removingAllWhitespace
        } else {
            text = sourceText
        }

        guard !text.isEmpty else {
            showTips(text: String(localized: "没有可处理的内容"), color: .red, afterClose: true)
            return
        }

        if let cached = results[mode], !cached.isEmpty {
            renderResult(cached)
            return
        }

        results[mode] = ""
        renderResult(String(localized: "正在处理中..."))

        var clientMode: ChatPrompt.ChatPromptMode {
            if case .translate = mode {
                return .translate(lang)
            } else {
                return .abstract(lang)
            }
        }

        streamTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.stream(text: text, mode: clientMode) { [weak self] delta in
                    guard let self, self.resultMode == mode else { return }
                    var acc = self.results[mode] ?? ""
                    acc += delta
                    self.results[mode] = acc
                    self.renderResult(acc)
                    Haptic.selection(limitFrequency: true)
                }
            } catch {
                if Task.isCancelled { return } // 用户切换 / 还原
                logger.error("\(error)")
                self.results[mode] = ""
                self.resultMode = nil
                if let originalHTML = self.originalHTML {
                    self.web.isHidden = false
                    self.web.loadHTMLString(originalHTML, baseURL: self.cssBaseURL())
                } else {
                    self.web.isHidden = true
                    self.updateLayout(webHeight: 0)
                }
                self.showTips(
                    text: "\(String(localized: "发生错误")): \(error.localizedDescription)",
                    color: .red, afterClose: true
                )
            }
        }
    }

    private func renderResult(_ markdown: String) {
        guard let html = convertMarkdownToHTML(markdown) else { return }
        web.isHidden = false
        web.loadHTMLString(html, baseURL: cssBaseURL())
    }

    private func cssBaseURL() -> URL? {
        guard let cssPath = Bundle.main.path(forResource: "css/markdown", ofType: "css") else {
            return nil
        }
        return URL(fileURLWithPath: cssPath).deletingLastPathComponent()
    }

    // MARK: - Markdown → HTML

    private func convertMarkdownToHTML(_ markdown: String) -> String? {
        guard let htmlBody = PBMarkdown.markdownToHTML(markdown) else { return nil }
        return """
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <link rel="stylesheet" type="text/css" href="markdown.css">
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

extension NotificationViewController {
    enum ClientError: Error {
        case noAccount
    }

    func stream(
        text: String,
        mode: ChatPrompt.ChatPromptMode,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        guard let account = Defaults[.assistantAccouns].first(where: \.current) else {
            throw ClientError.noAccount
        }
        let query = ChatQuery(
            messages: [
                .system(.init(content: .textContent(mode.prompt.content))),
                .user(.init(content: .string(text))),
            ],
            model: account.model
        )

        let stream = NoLetChatClient(account: account).chatsStream(query: query)

        for try await result in stream {
            if let content = result.choices.first?.delta.content, !content.isEmpty {
                onDelta(content)
            }
        }
    }
}

extension NotificationViewController {
    func ImageHandler(imageURL: URL) {
        if imageURL.startAccessingSecurityScopedResource() {
            if let image = UIImage(contentsOfFile: imageURL.path()) {
                let size = self.sizecalculation(size: image.size)

                self.imageView.isHidden = false
                self.imageView.image = image
                self.imageView.frame = CGRect(
                    x: 0,
                    y: self.tipsView.frame.maxY,
                    width: size.width,
                    height: size.height
                )

                self.imageHeight = size.height

                let longPressGesture = UILongPressGestureRecognizer(
                    target: self,
                    action: #selector(self.handleLongPressOnImage(_:))
                )
                self.imageView.addGestureRecognizer(longPressGesture)

                self.updateLayout(webHeight: self.markdownHeight)
            } else {
                self.imageView.isHidden = true
                self.imageHeight = 0
                self.imageView.frame = CGRect(
                    x: 0,
                    y: self.tipsView.frame.maxY,
                    width: self.view.bounds.width,
                    height: 0
                )
                self.updateLayout(webHeight: self.markdownHeight)
            }

            imageURL.stopAccessingSecurityScopedResource()
        }
    }

    func sizecalculation(size: CGSize) -> CGSize {
        let viewWidth = view.bounds.size.width
        let aspectRatio = size.width / size.height
        let viewHeight = viewWidth / aspectRatio
        preferredContentSize = CGSize(width: viewWidth, height: viewHeight)
        return preferredContentSize
    }

    // 长按手势回调方法
    @objc func handleLongPressOnImage(_ gesture: UILongPressGestureRecognizer) {
        Haptic.impact()
        guard gesture.state == .began else { return }

        guard let image = imageView.image else { return }

        let alertController = UIAlertController(
            title: String(localized: "保存图片"),
            message: String(localized: "是否将图片保存到相册？"),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(
            title: String(localized: "保存"),
            style: .default,
            handler: { _ in
                UIImageWriteToSavedPhotosAlbum(
                    image,
                    self,
                    #selector(self.image(_:didFinishSavingWithError:contextInfo:)),
                    nil
                )
            }
        ))
        alertController.addAction(UIAlertAction(
            title: String(localized: "取消"),
            style: .cancel,
            handler: nil
        ))

        present(alertController, animated: true, completion: nil)
    }

    // 保存完成后的回调方法
    @objc func image(
        _: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo _: UnsafeRawPointer
    ) {
        Haptic.impact()
        let alertController: UIAlertController

        if let error = error {
            alertController = UIAlertController(
                title: String(localized: "保存失败"),
                message: String(localized: "保存图片时出现错误"),
                preferredStyle: .alert
            )
            logger.error("\(error)")
        } else {
            alertController = UIAlertController(
                title: String(localized: "保存成功"),
                message: String(localized: "图片已成功保存到相册！"),
                preferredStyle: .alert
            )
        }

        alertController.addAction(UIAlertAction(
            title: String(localized: "确定"),
            style: .default,
            handler: nil
        ))

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

struct ScriptParams: @unchecked Sendable {
    let values: [AnyHashable: Any]
    
    init(values: [AnyHashable : Any], actionMode: String) {
        var values = values
        values["actionmode"] = actionMode
        self.values = values
    }
}

// MARK: - Dynamic Font Extension

extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}
