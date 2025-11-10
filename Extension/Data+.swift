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
import SwiftUI
import CryptoKit


extension Data{
    func sha256() -> String{
        // 计算 SHA-256 哈希值
        // 将哈希值转换为十六进制字符串
        return SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }
    
    
    func toThumbnail(max:Int = 300)-> UIImage?{
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max
        ]
        
        if let source = CGImageSourceCreateWithData(self as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            
            return  UIImage(cgImage: cgImage)
        }
        return nil
    }
    
}

