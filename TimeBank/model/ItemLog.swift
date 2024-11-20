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
        self.saveMin = begin.elapsedMin(end)
    }
    
    var exchange:Float {
        return Float(self.saveMin) * self.bankItem!.rate;
    }
    
    var exchangeString:String{
        return String(format: "%.2f",self.exchange)
    }
}
