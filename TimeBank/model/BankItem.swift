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
    var rate:Float = 1.0
    
    @Relationship(deleteRule: .cascade, inverse: \ItemLog.bankItem)
    var logs:[ItemLog]?
    
    init(name: String = "", sort: Int = 0, parent: BankItem? = nil,  isSave: Bool = true, rate:Float = 1) {
        self.id = UUID()
        self.name = name
        self.sort = sort
//        self.parent = parent
        self.isSave = isSave
        self.rate = rate
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
    
    var exchange:Float {
        return Float(self.saveMin) * self.rate;
    }
    
    var exchangeString:String{
        return String(format: "%.2f",self.exchange)
    }
}
extension BankItem {
    struct TimerStopResult {
        let shouldRecord: Bool
        let recordedLog: ItemLog?
    }

    static func displaySort(_ lhs: BankItem, _ rhs: BankItem) -> Bool {
        if lhs.isPin != rhs.isPin {
            return lhs.isPin && !rhs.isPin
        }

        switch (lhs.lastTouch, rhs.lastTouch) {
        case let (.some(left), .some(right)):
            return left > right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.createTime > rhs.createTime
        }
    }

    func value(useRate: Bool) -> Float {
        useRate ? exchange : Float(saveMin)
    }

    @discardableResult
    func stopTimer(start: Date, end: Date = Date()) -> TimerStopResult {
        guard start.elapsedMin(end) >= 1 else {
            return TimerStopResult(shouldRecord: false, recordedLog: nil)
        }

        if logs == nil {
            logs = []
        }

        lastTouch = end
        let log = ItemLog(bankItem: self, begin: start, end: end)
        logs?.append(log)
        return TimerStopResult(shouldRecord: true, recordedLog: log)
    }
}

extension Collection where Element == BankItem {
    func filteredAndSorted(isSave: Bool) -> [BankItem] {
        filter { $0.isSave == isSave }
            .sorted(by: BankItem.displaySort)
    }

    func totalValue(isSave: Bool, useRate: Bool) -> Float {
        reduce(0) { partialResult, item in
            guard item.isSave == isSave else {
                return partialResult
            }

            return partialResult + item.value(useRate: useRate)
        }
    }

    func balanceValue(useRate: Bool) -> Float {
        totalValue(isSave: true, useRate: useRate) - totalValue(isSave: false, useRate: useRate)
    }
}
