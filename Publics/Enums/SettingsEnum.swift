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

extension Defaults.Keys {
    static let messageExpiration = Key<ExpirationTime>("messageExpirtionTime", .forever)
    static let imageSaveDays = Key<ExpirationTime>("imageSaveDays", .forever)
}
extension ExpirationTime: Codable, Defaults.Serializable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(Int64.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum ExpirationTime: Equatable, Hashable {
    
    case forever
    case day(Int64)
    case no

    init(rawValue: Int64) {
        if rawValue == 0 {
            self = .no
        } else if rawValue < 0 {
            self = .forever
        } else {
            self = .day(rawValue)
        }
    }

    var rawValue: Int64 {
        switch self {
        case .forever:
            return -1
        case .day(let day):
            return day
        case .no:
            return 0
        }
    }

    var seconds: TimeInterval {
        TimeInterval(self.isPermanent ? rawValue : rawValue * 24 * 60 * 60)
    }

    func messageTTL(now: Date = Date()) -> Int64 {
        self.isPermanent ? rawValue :
            Int64(now.addingTimeInterval(seconds)
                .timeIntervalSince1970)
    }

    var isPersisted: Bool { self != .no }

    var isPermanent: Bool { self == .forever }
}
