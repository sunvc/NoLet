//
//  ImageManager.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/14.
//

import Foundation
import Kingfisher
import Photos
import UIKit

enum ImageManager {
    static let customCache: ImageCache = {
        let cache = (try? ImageCache(
            name: "shared",
            cacheDirectoryURL: NCONFIG.FolderType.image.path
        )) ??
            ImageCache.default
        return cache
    }()

    static func storeImage(
        cache: ImageCache? = nil, data: Data, key: String, expiration: StorageExpiration = .never
    ) async {
        return await withCheckedContinuation { continuation in
            customCache.storeToDisk(data, forKey: key, expiration: expiration) { _ in
                continuation.resume()
            }
        }
    }

    static func downloadImage(
        _ imageURL: String,
        expiration: StorageExpiration = .never
    ) async -> String? {
        // Return cached path if image is already cached
        if customCache.diskStorage.isCached(forKey: imageURL) {
            return customCache.cachePath(forKey: imageURL)
        }

        guard let imageResource = URL(string: imageURL) else { return nil }

        let cacheKey = imageResource.cacheKey

        if customCache.diskStorage
            .isCached(forKey: cacheKey) { return customCache.cachePath(forKey: cacheKey) }

        guard let result = try? await downloadImage(url: imageResource).get() else { return nil }

        // Cache downloaded image
        await storeImage(
            cache: customCache, data: result.originalData, key: cacheKey, expiration: expiration
        )

        return customCache.cachePath(forKey: cacheKey)
    }

    static func downloadImage(
        url: URL,
        options: KingfisherOptionsInfo? = nil
    ) async -> Result<ImageLoadingResult, KingfisherError> {
        return await withCheckedContinuation { continuation in
            let downloader = Kingfisher.ImageDownloader.default

            downloader.downloadTimeout = 10.0
            downloader.downloadImage(with: url, options: options) { result in
                continuation.resume(returning: result)
            }
        }
    }

    static func thumbImage(_ url: String, maxPixel: CGFloat = 800) async -> UIImage? {
        if let file = await ImageManager.downloadImage(url),
           let thumb = await loadThumbnail(path: file, maxPixel: maxPixel)
        {
            return thumb
        }

        return nil
    }

    static func loadThumbnail(path: String, maxPixel: CGFloat) async -> UIImage? {
        let url = URL(fileURLWithPath: path)
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions)
        else { return nil }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true,
        ] as CFDictionary

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}

extension ImageManager {
    /// 保存图片到相册
    static func saveToAlbum(
        albumName: String? = nil,
        imageURL: String? = nil,
        image: UIImage? = nil
    ) async -> (Bool, PHAuthorizationStatus) {
        let status = await Self.requestAuthorization(for: .readWrite)
        guard status.0 else {
            return (status.0, status.1)
        }

        // 1. 准备数据源 (在执行 performChanges 之前完成)
        let source: SaveSource
        if let img = image {
            source = .image(img)
        } else if let urlStr = imageURL, let localPath = await downloadImage(urlStr) {
            source = .file(URL(fileURLWithPath: localPath))
        } else {
            return (false, status.1)
        }

        do {
            let finalAlbumName = albumName ?? NCONFIG.AppName

            // 2. 获取或创建相册
            let collection = try await fetchOrCreateAlbum(named: finalAlbumName)

            // 3. 使用原生异步 performChanges (iOS 16+)
            // 这种写法下，变量 localID 的捕获由编译器自动处理，不会有隔离报错
            try await PHPhotoLibrary.shared().performChanges {
                let assetRequest: PHAssetChangeRequest
                switch source {
                case .image(let img):
                    assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: img)
                case .file(let url):
                    assetRequest = PHAssetChangeRequest
                        .creationRequestForAssetFromImage(atFileURL: url)!
                }

                if let placeholder = assetRequest.placeholderForCreatedAsset {
                    let albumRequest = PHAssetCollectionChangeRequest(for: collection)
                    albumRequest?.addAssets([placeholder] as NSArray)
                }
            }
            return (true, status.1)
        } catch {
            logger.fault("Save to album failed: \(error)")
            return (false, status.1)
        }
    }

    /// 查找或创建相册的核心逻辑
    private static func fetchOrCreateAlbum(named name: String) async throws -> PHAssetCollection {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions
        )

        if let existing = collections.firstObject {
            return existing
        }

        // 使用原生异步接口创建相册
        var localID: String?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(withTitle: name)
            localID = request.placeholderForCreatedAssetCollection.localIdentifier
        }

        guard let id = localID,
              let newCol = PHAssetCollection.fetchAssetCollections(
                  withLocalIdentifiers: [id],
                  options: nil
              ).firstObject
        else {
            throw NSError(
                domain: "ImageManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Album creation failed"]
            )
        }

        return newCol
    }

    private enum SaveSource {
        case image(UIImage)
        case file(URL)
    }

    static func requestAuthorization(for accessLevel: PHAccessLevel) async
        -> (Bool, PHAuthorizationStatus, String)
    {
        let status = await PHPhotoLibrary.requestAuthorization(for: accessLevel)
        let success: Bool
        let msg: String
        switch status {
        case .notDetermined:
            success = false
            msg = String(localized: "未选择权限")

        case .restricted, .limited:
            msg = String(localized: "有限的访问权限")
            success = true

        case .denied:
            success = false
            msg = String(localized: "拒绝了访问权限")

        case .authorized:
            msg = String(localized: "已授权访问照片库")
            success = true

        @unknown default:
            msg = String(localized: "未知状态")
            success = false
        }
        return (success, status, msg)
    }
}
