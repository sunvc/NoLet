//
//  Type+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//

import UniformTypeIdentifiers

extension UTType {
    static var trnExportType = UTType(exportedAs: "me.uuneo.nolet.exv")
}

extension Bundle {
    /// 判断当前是否是 App Extension
    var isAppExtension: Bool {
        return bundlePath.hasSuffix(".appex")
    }
}
