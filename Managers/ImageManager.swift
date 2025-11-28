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

/// Image Manager
///
/// - Overview: A unified wrapper around Kingfisher's `ImageCache` and `ImageDownloader` to download
///   images and persist them to disk.
/// - Capabilities:
///   1. Download by URL and cache to disk, returning the local cache path
///   2. Store raw image data to a specified cache
///   3. Optional proxy and signed headers via `getOptionsInfo(from:)` for protected resources
/// - Storage: Uses `NCONFIG.FolderType.image.path` as the shared cache directory, suitable for App
///   and extension sharing.
/// - Concurrency: All Kingfisher operations are wrapped with `withCheckedContinuation` to provide
///   `async` interfaces without blocking the main thread.
/// - Failure Handling: Returns `nil` on download or cache setup failures; callers should implement
///   graceful fallbacks based on a `nil` result.
class ImageManager {
    
    static let memoryCache = NSCache<NSString, UIImage>()
    
    /// Store raw image bytes into the specified cache (disk-only)
    /// - Parameters:
    ///   - cache: Target `ImageCache`; if `nil`, uses the default cache (`defaultCache()`)
    ///   - data: Raw image data to persist
    ///   - key: Cache key (use a stable key such as `URL.cacheKey`)
    ///   - expiration: Cache expiration policy; defaults to `.never`
    /// - Notes: Uses Kingfisher `storeToDisk` to write directly to disk; does not populate memory
    /// cache.
    /// - Errors: If default cache creation fails, the method returns immediately.
    class func storeImage(
        cache: ImageCache? = nil, data: Data, key: String, expiration: StorageExpiration = .never
    ) async {
        let cacheTem: ImageCache

        if let cache = cache {
            cacheTem = cache
        } else {
            guard let cache = defaultCache() else { return }
            cacheTem = cache
        }

        return await withCheckedContinuation { continuation in
            cacheTem.storeToDisk(data, forKey: key, expiration: expiration) { _ in
                continuation.resume()
            }
        }
    }

    /// Download an image by URL and cache to disk
    /// - Parameters:
    ///   - imageUrl: Image URL as a string
    ///   - expiration: Cache expiration policy; defaults to `.never`
    /// - Returns: Local disk cache path on success; otherwise `nil`
    /// - Flow:
    ///   1. If the default cache cannot be created, return `nil`
    ///   2. Check the original URL string as the cache key; return path if cached
    ///   3. Check `URL.cacheKey` as the standard key; return path if cached
    ///   4. If not cached, download → store to disk → return path
    /// - Proxy & Auth: When proxy is enabled (`Defaults[.proxyServer]`), request headers include
    /// custom
    ///   UA, Authorization, and signed `X-DATA` (see `getOptionsInfo(from:)`).
    class func downloadImage(_ imageURL: String, expiration: StorageExpiration = .never) async
        -> String?
    {
        guard let cache = defaultCache() else { return nil }

        // Return cached path if image is already cached
        if cache.diskStorage.isCached(forKey: imageURL) { return cache.cachePath(forKey: imageURL) }

        guard let imageResource = URL(string: imageURL) else { return nil }

        let cacheKey = imageResource.cacheKey

        if cache.diskStorage.isCached(forKey: cacheKey) { return cache.cachePath(forKey: cacheKey) }

        let (optionsInfo, server) = getOptionsInfo(from: imageResource.absoluteString)

        guard let result = try? await downloadImage(
            url: server ?? imageResource,
            options: optionsInfo 
        ).get() else { return nil }

        // Cache downloaded image
        await storeImage(
            cache: cache, data: result.originalData, key: cacheKey, expiration: expiration
        )

        return cache.cachePath(forKey: cacheKey)
    }

    /// Low-level Kingfisher download helper
    /// - Parameters:
    ///   - url: Remote image URL
    ///   - options: Kingfisher options (request modifiers, cache policies, etc.)
    /// - Returns: `Result<ImageLoadingResult, KingfisherError>` including original data and image
    /// on success
    /// - Details: Default download timeout is `15s`.
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

    /// Get the default disk image cache
    /// - Returns: `ImageCache` instance; `nil` if creation fails
    /// - Location: Uses `NCONFIG.FolderType.image.path` as the cache root, suitable for shared
    /// storage.
    class func defaultCache() -> ImageCache? {
        return try? ImageCache(name: "shared", cacheDirectoryURL: NCONFIG.FolderType.image.path)
    }

    /// Build Kingfisher options from proxy configuration
    /// - Parameters:
    ///   - mediaUrl: The media URL string to be requested
    /// - Returns: Kingfisher options; `nil` if proxy is disabled or signing fails
    /// - Behavior:
    ///   - Enabled only when `Defaults[.proxyServer]` is active and uses HTTP(S)
    ///   - If proxy URL equals `NCONFIG.server`, use fixed config; otherwise derive a signature
    /// from
    ///     `proxyServer.sign`
    ///   - Request headers set:
    ///     - `User-Agent`: `NCONFIG.customUserAgent`
    ///     - `Authorization`: `Defaults[.id]`
    ///     - `X-DATA`: Encrypted signature string (safe Base64)
    private class func getOptionsInfo(from mediaURL: String) -> (KingfisherOptionsInfo?, URL?) {
        let proxyServer = Defaults[.proxyServer]

        guard proxyServer.url.hasHttp,
              proxyServer.status,
              let serverURL = URL(string: proxyServer.url) else { return (nil, nil) }

        var config: CryptoModelConfig? {
            guard let sign = proxyServer.sign else { return .data }
            return CryptoModelConfig(inputText: sign)
        }

        guard let config = config,
              let signStr = CryptoManager(config).encrypt(mediaURL)?.safeBase64
        else {
            return (nil, nil)
        }

        return (
            [
                .requestModifier(
                    AnyModifier { request in
                        var request = request
                        request.setValue(NCONFIG.customUserAgent, forHTTPHeaderField: "User-Agent")
                        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization")
                        request.setValue(signStr, forHTTPHeaderField: "X-DATA")
                        return request
                    }),
            ], serverURL
        )
    }
    
    class func preloading(_ urls: [String], maxPixel: CGFloat = 800){
        Task.detached( priority: .background) { 
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await thumbImage(url, maxPixel: maxPixel)
                    }
                }
            }
        }
    }
    
    
    class func thumbImage( _ url:String, maxPixel: CGFloat = 800) async -> UIImage? {
        // 1. memory cache
        
        if let cached = ImageManager.memoryCache.object(forKey: url as NSString) {
            return cached
        }
        
        if let file = await ImageManager.downloadImage( url),
           let thumb = await loadThumbnail(path: file, maxPixel: maxPixel) {
            ImageManager.memoryCache.setObject(thumb, forKey: url as NSString)
            return thumb
            
        }
        
        return nil
    }
    
   class func loadThumbnail(path: String, maxPixel: CGFloat) async -> UIImage? {
        let url = URL(fileURLWithPath: path)
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
