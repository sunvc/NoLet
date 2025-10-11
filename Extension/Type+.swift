//
//  Type+.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//

import UniformTypeIdentifiers


extension UTType {
    static var trnExportType = UTType(exportedAs: "me.uuneo.pushback.exv")
}

extension Bundle {
    /// 判断当前是否是 App Extension
    var isAppExtension: Bool {
        return bundlePath.hasSuffix(".appex")
    }
}
