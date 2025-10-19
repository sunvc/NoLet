//
//  ImageManager.swift
//  NoLet
//
//  Created by uuneo 2024/10/14.
//

import SwiftUI
import Kingfisher

/// A manager class that handles image caching and downloading operations
class ImageManager {

    /// Stores an image in the specified cache
    /// - Parameters:
    ///   - cache: The ImageCache instance to store the image in. If nil, uses default cache
    ///   - mode: The image mode (icon or other) to determine cache location
    ///   - data: The image data to store
    ///   - key: The key to store the image under
    ///   - expiration: The expiration time for the cached image
    class func storeImage(cache: ImageCache? = nil, data: Data, key: String, expiration: StorageExpiration = .never) async {
        
        let cacheTem: ImageCache
        
        if let cache = cache { cacheTem = cache } else {
            guard let cache = defaultCache() else { return }
            cacheTem = cache
        }
        
        return await withCheckedContinuation { continuation in
            cacheTem.storeToDisk(data, forKey: key, expiration: expiration) { _ in
                continuation.resume()
            }
        }
    }
    
    /// Downloads an image from a URL and caches it
    /// - Parameters:
    ///   - imageUrl: The URL string of the image to download
    ///   - mode: The image mode (icon or other) to determine cache location
    ///   - expiration: The expiration time for the cached image
    /// - Returns: The local cache path of the downloaded image, or nil if download fails
    class func downloadImage(_ imageUrl: String, expiration: StorageExpiration = .never) async -> String? {
        
        guard let cache = defaultCache() else { return nil }
        
        // Return cached path if image is already cached
        if cache.diskStorage.isCached(forKey: imageUrl) { return cache.cachePath(forKey: imageUrl) }

        guard let imageResource = URL(string: imageUrl) else { return nil }
        
        let cacheKey = imageResource.cacheKey

        if cache.diskStorage.isCached(forKey: cacheKey) { return cache.cachePath(forKey: cacheKey) }

        // Download image
        guard let result = try? await downloadImage(url: imageResource).get() else { return nil }

        // Cache downloaded image
        await storeImage(cache: cache, data: result.originalData, key: cacheKey, expiration: expiration)

        return cache.cachePath(forKey: cacheKey)
    }

    /// Downloads an image from a URL using Kingfisher
    /// - Parameter url: The URL to download the image from
    /// - Returns: A Result containing either the downloaded image or an error
    class func downloadImage(url: URL) async -> Result<ImageLoadingResult, KingfisherError> {
        return await withCheckedContinuation { continuation in
            Kingfisher.ImageDownloader.default.downloadImage(with: url, options: nil) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Gets the default image cache for the specified mode
    /// - Parameter mode: The image mode (icon or other) to determine cache location
    /// - Returns: An ImageCache instance, or nil if cache creation fails
    class func defaultCache() -> ImageCache? {
        guard  let cache = try? ImageCache(
            name: "shared",
            cacheDirectoryURL: BaseConfig.FolderType.image.path
        )
        else { return nil }
        return cache
    }
    
}
