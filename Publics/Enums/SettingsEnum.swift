//
//  OtherModel.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/26.
//

import Defaults
import Foundation


enum DefaultBrowserModel: String, CaseIterable {
    case auto
    case safari
    case app
}


enum ExpirationTime: Int, CaseIterable, Equatable {
    case forever = 999_999
    case month = 30
    case weekDay = 7
    case oneDay = 1
    case no = 0

    var days: Int { rawValue }
}
