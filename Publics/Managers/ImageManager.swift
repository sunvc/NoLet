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
import UIKit

final class ImageManager {
    class func storeImage(
        cache: ImageCache? = nil, data: Data, key: String, expiration: StorageExpiration = .never
    ) async {
        return await withCheckedContinuation { continuation in
            customCache.storeToDisk(data, forKey: key, expiration: expiration) { _ in
                continuation.resume()
            }
        }
    }

    class func downloadImage(
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

    class func downloadImage(
        url: URL,
        options: KingfisherOptionsInfo? = nil
    ) async -> Result<ImageLoadingResult, KingfisherError> {
        return await withCheckedContinuation { continuation in
            let downloader = Kingfisher.ImageDownloader.default

            downloader.downloadTimeout = 15.0
            downloader.downloadImage(with: url, options: options) { result in
                continuation.resume(returning: result)
            }
        }
    }

    class func thumbImage(_ url: String, maxPixel: CGFloat = 800) async -> UIImage? {
        if let file = await ImageManager.downloadImage(url),
           let thumb = await loadThumbnail(path: file, maxPixel: maxPixel)
        {
            return thumb
        }

        return nil
    }

    class func loadThumbnail(path: String, maxPixel: CGFloat) async -> UIImage? {
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
    static var customCache: ImageCache {
        let cache = (try? ImageCache(name: "shared", cacheDirectoryURL: NCONFIG.FolderType.image.path)) ??
            ImageCache.default
        return cache
    }
}
