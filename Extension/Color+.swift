//
//  Color+.swift
//  NoLet
//
//  Created by lynn on 2025/6/22.
//

import Foundation
import UIKit
import SwiftUI


extension UIColor {
    convenience init?(hexString: String) {
        // 只保留 0-9 A-F a-f
        let hex = hexString.uppercased().filter { "0123456789ABCDEF".contains($0) }
        guard !hex.isEmpty else { return nil }
        
        guard let int = UInt64(hex, radix: 16) else { return nil }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255,  blue: CGFloat(b) / 255,  alpha: CGFloat(a) / 255)
    }
    
  
}



