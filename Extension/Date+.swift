//
//  Date+.swift
//  NoLet
//
//  Created by lynn on 2025/6/5.
//
import SwiftUI

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }
}

// MARK: -  Date+.swift

extension Date {
   public func formatString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func agoFormatString() -> String {
        let calendar = Calendar(identifier: .gregorian)
        guard let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date()) as DateComponents? else {
            return String(localized: "未知时间")
        }
        
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        // Check if the date is within the current year
        let isCurrentYear = calendar.isDate(self, equalTo: Date(), toGranularity: .year)
        
        if year > 0 || month > 0 || day > 0 || hour > 12 {
            // Display full date if it's more than 12 hours ago
            if isCurrentYear {
                return formatString(format: "MM-dd HH:mm") // Exclude year if within the current year
            } else {
                return formatString(format: "yyyy-MM-dd HH:mm") // Include year if not the current year
            }
        }
        
        if hour > 1 {
            // Display in hours and minutes if it's more than 1 hour ago
            return formatString(format: "HH:mm")
        }
        if hour > 0 {
            // Display in hours and optionally minutes
            if minute > 0 {
                return String(format: String(localized: "%1$d小时%2$d分钟前"), hour, minute)
            }
            return String(format: String(localized: "%1$d小时前"), hour)
        }
        if minute > 1 {
            // Display in minutes if it's more than 1 minute ago
            return String(format: String(localized: "%1$d分钟前"), minute)
        }
        // Display "just now" for time differences of less than 1 minute
        return String(localized: "刚刚")
    }
    
    // 计算日期与当前日期的差异，并根据差异生成颜色
    func colorForDate() -> Color {
        let now = Date()
        let timeDifference = now.timeIntervalSince(self) // 获取过去的时间差（秒为单位）
        
        let threeHours: TimeInterval = 3 * 60 * 60
        let fiveHours: TimeInterval = 5 * 60 * 60
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        let oneWeek: TimeInterval = 7 * twentyFourHours
        
        // 根据过去时间的长短判断颜色
        // 3小时以内，显示绿色
        if timeDifference <= threeHours {
            return Color.green
        }
        // 3小时到5小时之间，显示黄色
        else if timeDifference <= fiveHours {
            return Color.yellow
        }
        // 5小时到24小时之间，显示蓝色
        else if timeDifference <= twentyFourHours {
            return Color.blue
        }
        // 24小时到一周之间，显示灰色
        else if timeDifference <= oneWeek {
            return Color.gray
        }
        // 超过一周，显示深灰色
        return Color(UIColor.darkGray)
    }
    
    
    /// 计算给定天数减去（当前日期 - 自身日期）的天数
    /// - Parameter days: 给定的天数
    /// - Returns: 剩余的天数
    func daysRemaining(afterSubtractingFrom days: Int) -> Int {
        // 计算当前日期和目标日期之间的天数差
        guard let daysBetween = Calendar.current.dateComponents([.day], from: Date(), to: self).day else {
            return -1
        }
        // 返回给定天数减去天数差
        return days - daysBetween
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    static var lastHour: Date { return Calendar.current.date(byAdding: .hour, value: -1, to: Date())! }
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
    
    func someDayBefore(_ day: Int)-> Date{
        return Calendar.current.date(byAdding: .day, value: -day, to: noon)!
    }
    
    func someHourBefore(_ hour:Int)-> Date{
        return Calendar.current.date(byAdding: .hour, value: -hour, to: Date())!
    }
    
    var s1970: Date{
        return Calendar.current.date(from: DateComponents(year: 1970, month: 1,day: 1))!
    }
    
    func isExpired(days: Int) -> Bool {
        // 计算指定天数后的日期
        
        guard let targetDate = Calendar.current.date(byAdding: .day, value: days, to: self), days >= 0 else {
            return false
        }
        return Date() > targetDate
    }
}



