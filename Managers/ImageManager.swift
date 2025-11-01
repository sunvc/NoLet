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
    class func downloadImage(_ imageUrl: String,  expiration: StorageExpiration = .never) async -> String? {
        
        guard let cache = defaultCache() else { return nil }
        
        // Return cached path if image is already cached
        if cache.diskStorage.isCached(forKey: imageUrl) { return cache.cachePath(forKey: imageUrl) }

        guard let imageResource = URL(string: imageUrl) else { return nil }
        
        let cacheKey = imageResource.cacheKey

        if cache.diskStorage.isCached(forKey: cacheKey) { return cache.cachePath(forKey: cacheKey) }

        
        var responseData: Data? = nil
        
        
        if  let fileUrl = try? await downloadFile(from: imageUrl, proxy: Defaults[.proxyServer]) {
            responseData = try? Data(contentsOf: fileUrl)
        }else if let result = try? await downloadImage(url: imageResource).get(){
            responseData = result.originalData
        }
        
        guard let responseData else  { return nil}
        
        
        // Cache downloaded image
        await storeImage(cache: cache, data: responseData, key: cacheKey, expiration: expiration)

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
            cacheDirectoryURL: NCONFIG.FolderType.image.path
        )
        else { return nil }
        return cache
    }
    
    
    /// 下载文件到本地
    /// - Parameters:
    ///   - url: 文件下载 URL（完整路径）
    ///   - headers: 自定义请求头
    ///   - progressHandler: 可选进度回调（0.0 ~ 1.0）
    /// - Returns: 下载完成后文件在本地的 URL
    class func downloadFile(from mediaUrl: String, proxy proxyServer: PushServerModel? = nil) async throws -> URL {
        
        guard let proxyServer = proxyServer, proxyServer.status,
              let fileURL = URL(string: proxyServer.url) else { throw "No Proxy" }
        
        var config: CryptoModelConfig?{
            if proxyServer.url == NCONFIG.server{ return .data }
            if let sign = proxyServer.sign{  return CryptoModelConfig(inputText: sign) }
            return nil
        }
        
        guard let config = config,
              let signStr = CryptoManager(config).encrypt(mediaUrl)?.safeBase64 else {
            throw "invalid sign"
        }
        
        
        
        var request = URLRequest(url: fileURL)
        request.httpMethod = "GET"
        
        // 添加默认头
        request.setValue(NCONFIG.customUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization")
        
        request.timeoutInterval = 15
        
        // 打印请求信息（用于调试）
        request.assumesHTTP3Capable = true
        
       
       
        request.setValue(signStr, forHTTPHeaderField: "X-DATA")
        
        let configReq = URLSessionConfiguration.default
        configReq.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: configReq, delegate: nil, delegateQueue: .main)
        
        // 创建下载任务
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.downloadTask(with: request) { tempURL, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let tempURL = tempURL,
                      let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: NSError(
                        domain: "Nolet",
                        code: 1001,
                        userInfo: [NSLocalizedDescriptionKey: "加载失败，请稍后再试"]
                    ))
                    return
                }
                
                continuation.resume(returning: tempURL)
            }
            
            task.resume()
        }
    }

}
