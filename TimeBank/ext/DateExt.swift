//
//  DateExt.swift
//  BookTime
//
//  Created by Liu Rui on 2021/12/8.
//

import Foundation

extension Date {
    func text() -> String{
        return format("yyyy-MM-dd HH:mm:ss")
    }
    
    func dayString() -> String{
        return format("yyyy-MM-dd")
    }
    
    func timeString() -> String{
        return format("HH:mm:ss")
    }
    
    func format(_ format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
    
//    func dayString() -> String{
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .medium
////        dateFormatter.locale
//        return dateFormatter.string(from: self)
//    }
    
    func start() -> Date{
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        return calendar.startOfDay(for: self)
    }
    
    var dayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self)!
    }
    
    init (_ str:String){
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "yyyy-MM-dd"
           
           let target = dateFormatter.date(from: String(str))!
           self.init(timeIntervalSince1970: target.timeIntervalSince1970)
    }
    
    func getDaysInMonth() -> Int{
        let calendar = Calendar.current

        let dateComponents = DateComponents(year: calendar.component(.year, from: self), month: calendar.component(.month, from: self))
        let date = calendar.date(from: dateComponents)!

        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count

        return numDays
    }

    func isSameDay(_ date2:Date) -> Bool{
        return Calendar.current.isDate(self, equalTo: date2, toGranularity: .day)
    }
    
    func elapsedMin(_ date2:Date) -> Int{
        // 使用当前日历
        let calendar = Calendar.current

        // 计算两个日期之间的差异
        let diffComponents = calendar.dateComponents([.minute], from: self, to: date2)

        // 获取分钟差异的整数部分
        if let minutes = diffComponents.minute {
            return minutes
        } else {
            return 0
        }
    }
}
