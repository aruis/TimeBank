//
//  Item.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import Foundation
import SwiftData

@Model
class BankItem {
    var id:UUID = UUID()
    var name:String = ""
    var sort:Int = 0
//    var parent:BankItem?
    
    
    var isSave:Bool = true
    
    var lastTouch:Date?
    var createTime:Date = Date()
    var isPin:Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \ItemLog.bankItem)
    var logs:[ItemLog]?
    
    init(name: String = "", sort: Int = 0, parent: BankItem? = nil,  isSave: Bool = true) {
        self.id = UUID()
        self.name = name
        self.sort = sort
//        self.parent = parent
        self.isSave = isSave
        self.createTime = Date()
        self.logs = []
        self.isPin = false
    }
    
    var saveMin:Int {
        if let logs = logs {
            return logs.reduce(0) { sum, item in
                sum + item.saveMin
            }
        }else {
            return 0
        }

    }
}
