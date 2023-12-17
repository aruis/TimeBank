//
//  TimeStep.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import Foundation
import SwiftData


@Model
class ItemLog {
    var id:UUID = UUID()
    var bankItem:BankItem?
    
    var begin:Date = Date()
    var end:Date = Date()
    var saveMin:Int = 0
    var rating:Int?
    
    init(bankItem: BankItem, begin: Date, end:Date) {
        self.id = UUID()
        self.bankItem = bankItem
        self.begin = begin
        self.end = end
        
        
        // 使用当前日历
        let calendar = Calendar.current

        // 计算两个日期之间的差异
        let diffComponents = calendar.dateComponents([.minute], from: begin, to: end)

        // 获取分钟差异的整数部分
        if let minutes = diffComponents.minute {
            self.saveMin =  minutes
        } else {
            self.saveMin = 0
        }
    }
}
