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
import UIKit
import UserNotifications
import UserNotificationsUI
import WebKit

class NotificationViewController: UIViewController, UNNotificationContentExtension,
    WKNavigationDelegate
{
    @IBOutlet var tipsView: UILabel!
    @IBOutlet var imageView: UIImageView! // ←← 新增
    @IBOutlet var web: WKWebView!

    private var markdownHeight: CGFloat = 0
    private var imageHeight: CGFloat = 0 // ←← 新增

    override func viewDidLoad() {
        super.viewDidLoad()

        // Tips View
        tipsView.text = ""
        tipsView.textAlignment = .center
        tipsView.adjustsFontForContentSizeCategory = true
        tipsView.font = UIFont.preferredFont(ofSize: 16)
        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)

        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.frame = .init(x: 0, y: 0, width: view.bounds.width, height: 0)

        // Web
        web.navigationDelegate = self
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.contentInset = .zero
        web.scrollView.scrollIndicatorInsets = .zero

        preferredContentSize = CGSize(width: view.bounds.width, height: 1)
    }

    // MARK: - Notification

    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        // 兼容bark
        if let autoCopy: Bool = userInfo.raw(.autoCopy), autoCopy {
            if let copy: String = userInfo.raw(.copy) {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = notification.request.content.body
            }
        }

        let imageList = mediaHandler(userInfo: userInfo, name: Params.image.name)
        if let imageURL = imageList.first {
            ImageHandler(imageURL: imageURL)
        } else {
            // 无图 → 隐藏
            imageView.isHidden = true
            imageView.frame.size.height = 0
        }

        // MARK: - Markdown 渲染判断

        if notification.request.content.categoryIdentifier == "markdown",
           let body: String = userInfo.raw(Params.body),
           let html = convertMarkdownToHTML(body),
           let cssPath = Bundle.main.path(forResource: "css/markdown", ofType: "css")
        {
            let baseURL = URL(fileURLWithPath: cssPath).deletingLastPathComponent()
            web.isHidden = false
            web.loadHTMLString(html, baseURL: baseURL)

        } else {
            // 非 markdown 分类 → WebView 高度为 0
            web.isHidden = true
            markdownHeight = 0
            web.frame = CGRect(x: 0, y: imageView.frame.maxY, width: view.bounds.width, height: 0)
            updateLayout(webHeight: 0)
        }
    }

    // MARK: - WebView Height

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let self = self, let height = result as? CGFloat else { return }
                self.updateLayout(webHeight: height)
            }
        }
    }

    private func updateLayout(webHeight: CGFloat) {
        markdownHeight = webHeight

        let tipsHeight = tipsView.bounds.height

        imageView.frame = CGRect(
            x: 0,
            y: tipsHeight,
            width: view.bounds.width,
            height: imageHeight
        )

        web.frame = CGRect(
            x: 0,
            y: tipsHeight + imageHeight,
            width: view.bounds.width,
            height: webHeight
        )

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

        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 35)

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
    func ImageHandler(imageURL: String) {
        Task.detached(priority: .high) {
            if let localPath = await ImageManager.downloadImage(
                imageURL,
                expiration: .days(Defaults[.imageSaveDays].rawValue)
            ),
                let image = UIImage(contentsOfFile: localPath)
            {
                let size = await self.sizecalculation(size: image.size)

                await MainActor.run { [weak self] in
                    guard let self = self else { return }

                    self.imageView.isHidden = false
                    self.imageView.image = image
                    self.imageView.frame = CGRect(
                        x: 0,
                        y: self.tipsView.frame.maxY,
                        width: size.width,
                        height: size.height
                    )

                    // ✅ 赋值 imageHeight
                    self.imageHeight = size.height

                    let longPressGesture = UILongPressGestureRecognizer(
                        target: self,
                        action: #selector(self.handleLongPressOnImage(_:))
                    )
                    self.imageView.addGestureRecognizer(longPressGesture)

                    self.updateLayout(webHeight: self.markdownHeight)
                }
            } else {
                // 无图片 → 高度置 0
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
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
            }
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

        // 弹出保存选项
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
            // 保存失败提示
            alertController = UIAlertController(
                title: String(localized: "保存失败"),
                message: String(localized: "保存图片时出现错误：\(error.localizedDescription)"),
                preferredStyle: .alert
            )
        } else {
            // 保存成功提示
            alertController = UIAlertController(
                title: String(localized: "保存成功"),
                message: String(localized: "图片已成功保存到相册！"),
                preferredStyle: .alert
            )
        }

        // 添加确定按钮
        alertController.addAction(UIAlertAction(
            title: String(localized: "确定"),
            style: .default,
            handler: nil
        ))

        // 显示弹窗
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func mediaHandler(userInfo: [AnyHashable: Any], name: String) -> [String] {
        if let media = userInfo[name] as? String {
            return [media]
        } else if let medias = userInfo[name] as? [String] {
            return medias
        }
        return []
    }
}

// MARK: - Dynamic Font Extension

extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}
