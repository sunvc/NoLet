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
import MapKit
import Photos
import UIKit

extension String {
    func avatarImage(size: CGFloat = 300, padding: CGFloat = 16) -> UIImage? {
        guard let textColor = (self.filter { !$0.isWhitespace }).decomposeTextAndColor()
        else { return nil }

        let singleEmoji = textColor.text.first?.isEmoji ?? false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let backgroundColor: UIColor = singleEmoji ? .clear : textColor.background

        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)

            let availableRect = rect.insetBy(dx: padding, dy: padding)

            let fontSize = availableRect.height * (singleEmoji ? 1 : 0.85)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: textColor.color,
            ]

            let textSize = textColor.text.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            )

            textColor.text.draw(at: textOrigin, withAttributes: attributes)
        }
    }

    func decomposeTextAndColor(
        _ defaultColor: UIColor = .white,
        _ backgroundColor: UIColor = .systemBlue
    ) -> (text: String, color: UIColor, background: UIColor)? {
        let parts = split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let first = parts.first, !first.isEmpty else {
            return nil
        }

        let chars = Array(first)
        var firstChar: String

        if chars.first?.isEmoji == true {
            firstChar = String(chars[0])
        } else {
            if chars.count >= 2 {
                if chars[0].isLetter || chars[0].isNumber,
                   chars[1].isLetter || chars[1].isNumber
                {
                    firstChar = String(chars[0...1])
                } else {
                    firstChar = String(chars[0])
                }
            } else {
                firstChar = String(chars[0])
            }
        }

        switch parts.count {
        case 1:
            return (firstChar, defaultColor, backgroundColor)
        case 2:
            return (firstChar, .white, UIColor(hexString: parts[1]) ?? backgroundColor)
        case 3...:
            return (
                firstChar,
                UIColor(hexString: parts[1]) ?? defaultColor,
                UIColor(hexString: parts[2]) ?? backgroundColor
            )
        default:
            return nil
        }
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.uppercased().filter { "0123456789ABCDEF".contains($0) }
        guard !hex.isEmpty else { return nil }

        guard let int = UInt64(hex, radix: 16) else { return nil }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

enum ImageManager {
    static let customCache: ImageCache = {
        let cache = (try? ImageCache(
            name: "NoletAlbum",
            cacheDirectoryURL: NCONFIG.Path(.library)
        )) ??
            ImageCache.default
        return cache
    }()

    static func storeImage(
        data: Data, key: String, expiration: StorageExpiration = .never
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
        if customCache.diskStorage.isCached(forKey: imageURL) {
            return customCache.cachePath(forKey: imageURL)
        }

        guard let imageResource = URL(string: imageURL) else { return nil }

        guard let result = try? await downloadImage(url: imageResource).get() else { return nil }

        await storeImage(
            data: result.originalData, key: imageURL, expiration: expiration
        )

        return customCache.cachePath(forKey: imageURL)
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
        // On iOS CGImageSourceCreateWithURL picks its decoder from the file
        // extension, so extensionless files (Kingfisher cache) fail. Create
        // from mapped data so ImageIO sniffs the content type instead.
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let source = CGImageSourceCreateWithData(
                  data as CFData,
                  [kCGImageSourceShouldCache: false] as CFDictionary
              )
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

            let collection = try await fetchOrCreateAlbum(named: finalAlbumName)

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
            logger.error("Save to album failed: \(error)")
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

extension ImageManager {
    /// 异步解析经纬度并在地图截图上绘制圆形定位点
    /// - Parameters:
    ///   - locationString: 经纬度字符串 (例如 "41.3414, 126.1852")
    ///   - mapSize: 期望的地图图片尺寸
    /// - Returns: 绘制好定位点的 UIImage，若解析或截图失败则返回 nil
    static func generateMapSnapshot(
        from locationString: String,
        mapSize: CGSize
    ) async -> String? {
        let separators = CharacterSet(charactersIn: ",，:")
        let components = locationString.components(separatedBy: separators)

        guard components.count >= 2,
              let latitude = Double(components[0].trimmingCharacters(in: .whitespaces)),
              let longitude = Double(components[1].trimmingCharacters(in: .whitespaces))
        else {
            return nil
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        options.size = mapSize
        let scale = await MainActor.run { UIScreen.main.scale }
        options.scale = scale
        options.mapType = .standard

        let snapshotter = MKMapSnapshotter(options: options)

        let finalImage: UIImage? =
            await withCheckedContinuation { (continuation: CheckedContinuation<
                UIImage?,
                Never
            >) in
                snapshotter.start { snapshot, error in
                    guard let snapshot = snapshot, error == nil else {
                        continuation.resume(returning: nil)
                        return
                    }
                    UIGraphicsBeginImageContextWithOptions(
                        snapshot.image.size,
                        true,
                        snapshot.image.scale
                    )

                    snapshot.image.draw(at: .zero)
                    if let context = UIGraphicsGetCurrentContext() {
                        let point = snapshot.point(for: coordinate)
                        let outerRadius: CGFloat = 11.0
                        let innerRadius: CGFloat = 7.0
                        context.saveGState()
                        context.setShadow(
                            offset: CGSize(width: 0, height: 2),
                            blur: 4,
                            color: UIColor.black.withAlphaComponent(0.35).cgColor
                        )
                        context.setFillColor(UIColor.white.cgColor)
                        context.addArc(
                            center: point,
                            radius: outerRadius,
                            startAngle: 0,
                            endAngle: .pi * 2,
                            clockwise: true
                        )
                        context.fillPath()
                        context
                            .setFillColor(UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
                                .cgColor)
                        context.addArc(
                            center: point,
                            radius: innerRadius,
                            startAngle: 0,
                            endAngle: .pi * 2,
                            clockwise: true
                        )
                        context.fillPath()

                        context.restoreGState()
                    }

                    let imageWithPin = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    continuation.resume(returning: imageWithPin)
                }
            }

        guard let image = finalImage, let data = image.pngData() else {
            return nil
        }

        await Self.storeImage(data: data, key: locationString)
        return await Self.downloadImage(locationString)
    }
}
