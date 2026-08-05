//
//  Date+.swift
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

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        self.date(from: dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }
}

extension Date {
    // MARK: - 静态快捷日期

    static var yesterday: Date { Date().startOfDay.dayBefore }
    static var tomorrow: Date { Date().startOfDay.dayAfter }

    private static let sharedDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt
    }()

    func formatString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = Date.sharedDateFormatter
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    static var lastHour: Date {
        Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    }

    /// Unix时间起点：1970-01-01 00:00:00 UTC
    static var s1970: Date { Date(timeIntervalSince1970: 0) }

    // MARK: - 日期偏移（基于自身self）

    var dayBefore: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: startOfDay) ?? self
    }

    var dayAfter: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? self
    }

    var startOfDay: Date {
        Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self) ?? self
    }

    /// 当前日期往前推 N 天（零点对齐）
    func someDayBefore(_ day: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -day, to: startOfDay) ?? self
    }

    /// 当前日期【self】往前推 N 小时（修复原BUG）
    func someHourBefore(_ hour: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hour, to: self) ?? self
    }

    func zeroDate(_ unit: Calendar.Component = .second) -> Date {
        let calendar = Calendar.current
        
        switch unit {
        case .second:
            return calendar.date(
                bySetting: .second,
                value: 0,
                of: self
            ) ?? self

        case .minute:
            return calendar.date(
                bySettingHour: calendar.component(.hour, from: self),
                minute: 0,
                second: 0,
                of: self
            ) ?? self

        case .hour:
            return calendar.date(
                bySettingHour: 0,
                minute: 0,
                second: 0,
                of: self
            ) ?? self
        default:
            return calendar.startOfDay(for: self)
        }
    }
}
