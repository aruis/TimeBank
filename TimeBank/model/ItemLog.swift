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
    var end:Date?
    var saveMin:Int = 0
    var rating:Int?
    
    init(bankItem: BankItem, begin: Date) {
        self.id = UUID()
        self.bankItem = bankItem
        self.begin = begin
        self.saveMin = 0
    }
}