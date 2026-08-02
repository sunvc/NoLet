//
//  Application+.swift
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
import UIKit

// MARK: -  keyPath+.swift

func == <T, Value: Equatable>(keyPath: KeyPath<T, Value>, value: Value) -> (T) -> Bool {
    { $0[keyPath: keyPath] == value }
}

