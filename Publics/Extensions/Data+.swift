//
//  Data+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//
import CryptoKit
import SwiftUI

extension Data {
    func sha256() -> String {
        return SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }

    nonisolated
    func toThumbnail(max: Int = 300) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max,
        ]

        if let source = CGImageSourceCreateWithData(self as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
