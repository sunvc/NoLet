//
//  Image+.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//
import SwiftUI
import Photos


//MARK: - 保存图片到相册
extension UIImage {
    /// 保存图片到相册
    /// 需要授权`Privacy - Photo Library Additions Usage Description`和`Privacy - Photo Library Usage Description`
    /// @param albumName 自定义相册的名字
    /// @param complete `success`代表图片保存是否成功,`authorizationStatus`代表授权状态
    func bat_save(intoAlbum albumName: String?, complete: @escaping (_ success: Bool, _ authorizationStatus: PHAuthorizationStatus) -> ()) {
        
        let albumName = albumName ?? BaseConfig.AppName
        
        let oldStatus = PHPhotoLibrary.authorizationStatus()
        if oldStatus == .authorized{
            let status = self.p_excuteSaveImage(intoAlbum: albumName)
            complete(status, .authorized)
        }else{
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                switch status {
                case .authorized, .limited:
                    complete(self.p_excuteSaveImage(intoAlbum: albumName), .authorized)
                default:
                    complete(false, status)
                }
                
           }
        }
        
    }
    
    /// 私有的，负责具体的保存图片的操作
    private func p_excuteSaveImage(intoAlbum albumName: String?) -> Bool {
        
        guard let albumName = albumName else {
            // 保存图片到`相机胶卷`
            do{
                try PHPhotoLibrary.shared().performChangesAndWait({
                    PHAssetChangeRequest.creationRequestForAsset(from: self)
                })
                return true
            }catch{
                NLog.error(
                    error.localizedDescription
                )
                return false
            }
        }
        
        // 获得相片
        guard let createdAssets = p_createdAssets() else { return false }

        // 获得相册
        guard let createdCollection = p_createdCollection(albumName: albumName) else {
            return false
        }
        
        do{
            try PHPhotoLibrary.shared().performChangesAndWait({
                let request = PHAssetCollectionChangeRequest(for: createdCollection)
                request?.insertAssets(createdAssets, at: NSIndexSet(index: 0) as IndexSet)
            })
            return true
        }catch{
            NLog.error(error.localizedDescription)
            return false
        }
    
    }
    
    /// 当前App对应的自定义相册
    private func p_createdCollection(albumName: String) -> PHAssetCollection? {
        
        // 抓取所有的自定义相册
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        
        // 查找当前App对应的自定义相册
        for index in 0..<collections.count {
            let collection = collections.object(at: index)
            if collection.localizedTitle == albumName {
                return collection
            }
        }
        
        // 当前App对应的自定义相册没有被创建过
        // 创建一个`自定义相册`
        var createdCollectionID: String = ""
        guard let _ = try? PHPhotoLibrary.shared().performChangesAndWait({
            createdCollectionID = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName).placeholderForCreatedAssetCollection.localIdentifier
        }) else {
            return nil
        }
        
        // 根据唯一标识获得刚才创建的相册
        return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [createdCollectionID], options: nil).firstObject
    }
    
    /// 返回刚才保存到`相机胶卷`的图片
    private func p_createdAssets() -> PHFetchResult<PHAsset>? {
        do{
            var assetID: String = ""
            try PHPhotoLibrary.shared().performChangesAndWait({
                assetID = PHAssetChangeRequest.creationRequestForAsset(from: self).placeholderForCreatedAsset?.localIdentifier ?? ""
            })
            return PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        }catch{
            NLog.error(error.localizedDescription)
            return nil
        }
        
    }
    
    func scaledSize(withWidth width: CGFloat) -> CGSize {
        let scaleFactor = width / self.size.width
        let newHeight = self.size.height * scaleFactor
        return CGSize(width: width, height: newHeight)
    }
}

extension Image {
    
    @ViewBuilder
    func customDraggable(_ width:CGFloat = .zero, appear:((Image)-> Void)? = nil, disappear:((Image)-> Void)? = nil) -> some View{
        self
            .draggable(self){
                self
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width == .zero ? 300 : width)
                    .onAppear{
                        appear?(self)
                    }
                    .onDisappear{
                        disappear?(self)
                    }
            }
    }
}



