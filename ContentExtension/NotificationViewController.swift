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

import UIKit
import UserNotifications
import UserNotificationsUI
import Defaults
import AVFoundation


class NotificationViewController: UIViewController, UNNotificationContentExtension {

    
    @IBOutlet weak var musicView: UIView!
    @IBOutlet weak var tipsView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private var voiceHeight: CGFloat {
        Defaults[.voicesViewShow] ? 35 : 0
    }
    
    var contentSize: CGSize{
        let height = imageView.bounds.height + musicView.bounds.height + tipsView.bounds.height
        return  CGSize(width: view.bounds.width, height: height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        musicView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: voiceHeight)
        imageView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
        tipsView.text = ""
        tipsView.adjustsFontForContentSizeCategory = true
        tipsView.textAlignment = .center
        tipsView.font = UIFont.preferredFont(ofSize: 16)
        tipsView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
    }
    
    


    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        // 兼容bark
        if let autoCopy:Bool = userInfo.raw(.autoCopy), autoCopy {
            if let copy: String = userInfo.raw(.copy) {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = notification.request.content.body
            }
        }
        
        if Defaults[.voicesViewShow]{
            var music: MusicInfoView{
                let music = MusicInfoView()
                music.text = userInfo.voiceText()
                music.frame = musicView.frame
                return music
            }
            self.musicView.addSubview(music)
        }
        
        
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: voiceHeight)
        
        let imageList = mediaHandler(userInfo: userInfo, name: Params.image.name)
        if let imageUrl = imageList.first { ImageHandler(imageUrl: imageUrl) }
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



    func ImageHandler(imageUrl: String) {
        Task.detached(priority: .high) {
            if let localPath = await ImageManager.downloadImage(imageUrl, expiration: .days(Defaults[.imageSaveDays].rawValue)),
               let image = UIImage(contentsOfFile: localPath) {

                let size = await self.sizecalculation(size: image.size)

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                   
                    self.imageView.image = image
                    self.imageView.frame = CGRect(x: 0, y: voiceHeight, width: size.width, height: size.height)
                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnImage(_:)))
                    self.imageView.addGestureRecognizer(longPressGesture)
                    
                    self.preferredContentSize = .init(width: size.width, height: size.height + voiceHeight)
                }
            } else {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.preferredContentSize = CGSize(width: self.view.bounds.width, height: voiceHeight)
                }
            }
        }
    }
    

    func sizecalculation(size: CGSize) -> CGSize {
        let viewWidth = view.bounds.size.width
        let aspectRatio = size.width / size.height
        let viewHeight = viewWidth / aspectRatio
        self.preferredContentSize = CGSize(width: viewWidth, height: viewHeight)
        return self.preferredContentSize
    }
  
    func showTips(text: String) {
        Haptic.impact()
        tipsView.text = text
        tipsView.frame = CGRect(x: 0, y: voiceHeight,
                                     width: view.bounds.width,
                                     height: 35)
        view.addSubview(tipsView)
        imageView.frame = CGRect(x: 0,
                                      y: voiceHeight + 35,
                                      width: imageView.bounds.width,
                                      height: imageView.bounds.height)
        
        preferredContentSize = contentSize
        
    }
}

extension NotificationViewController{
    

    func mediaHandler(userInfo:[AnyHashable:Any], name:String) -> [String]{

        if let media = userInfo[name] as? String{
            return [media]
        }else if let medias = userInfo[name] as? [String]{
            return medias
        }
        return []
    }
    
    // 长按手势回调方法
      @objc func handleLongPressOnImage(_ gesture: UILongPressGestureRecognizer) {
          Haptic.impact()
          guard gesture.state == .began else { return }

          guard let image = imageView.image else { return }

          // 弹出保存选项
          let alertController = UIAlertController(title: String(localized:"保存图片"), message:  String(localized:"是否将图片保存到相册？"), preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title:  String(localized:"保存"), style: .default, handler: { _ in
              UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
          }))
          alertController.addAction(UIAlertAction(title:  String(localized:"取消"), style: .cancel, handler: nil))

          present(alertController, animated: true, completion: nil)
      }

      // 保存完成后的回调方法
      @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
          Haptic.impact()
          let alertController: UIAlertController

          if let error = error {
              // 保存失败提示
              alertController = UIAlertController(
                  title:  String(localized:"保存失败"),
                  message:  String(localized:"保存图片时出现错误：\(error.localizedDescription)"),
                  preferredStyle: .alert
              )
          } else {
              // 保存成功提示
              alertController = UIAlertController(
                  title:  String(localized:"保存成功"),
                  message:  String(localized:"图片已成功保存到相册！"),
                  preferredStyle: .alert
              )
          }

          // 添加确定按钮
          alertController.addAction(UIAlertAction(title:  String(localized:"确定"), style: .default, handler: nil))

          // 显示弹窗
          DispatchQueue.main.async {
              self.present(alertController, animated: true, completion: nil)
          }
      }


}



