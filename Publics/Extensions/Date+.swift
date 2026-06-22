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

// MARK: -  Date+.swift

extension Date {
    
    nonisolated func formatString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    /// 计算给定天数减去（当前日期 - 自身日期）的天数
    /// - Parameter days: 给定的天数
    /// - Returns: 剩余的天数
    nonisolated
    func daysRemaining(afterSubtractingFrom days: Int) -> Int {
        // 计算当前日期和目标日期之间的天数差
        guard let daysBetween = Calendar.current.dateComponents([.day], from: Date(), to: self).day
        else {
            return -1
        }
        // 返回给定天数减去天数差
        return days - daysBetween
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    static var lastHour: Date {
        return Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    }

    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }

    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }

    var noon: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }

    var month: Int {
        return Calendar.current.component(.month, from: self)
    }

    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }

    func someDayBefore(_ day: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -day, to: noon)!
    }

    func someHourBefore(_ hour: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: -hour, to: Date())!
    }

    var s1970: Date {
        return Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1))!
    }

    func isExpired(days: Int) -> Bool {
        // 计算指定天数后的日期

        guard let targetDate = Calendar.current.date(byAdding: .day, value: days, to: self),
              days >= 0
        else {
            return false
        }
        return Date() > targetDate
    }
}
