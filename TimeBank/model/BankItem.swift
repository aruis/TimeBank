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
    static let minimumLogDurationMinutes = 1
    static let defaultManualLogDurationMinutes = 30

    struct TimerStopResult {
        let shouldRecord: Bool
        let recordedLog: ItemLog?
    }

    enum LogRecordError: Error {
        case invalidRange
        case durationTooShort
        case overlappingLog
        case futureRange
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

    func refreshLastTouchFromLogs() {
        lastTouch = logs?.map(\.end).max()
    }

    func overlappingLogs(begin: Date, end: Date, excluding log: ItemLog? = nil) -> [ItemLog] {
        (logs ?? []).filter { candidate in
            guard candidate.id != log?.id else {
                return false
            }

            return candidate.begin < end && begin < candidate.end
        }
    }

    func latestAvailableRangeEndingNow(
        now: Date = Date(),
        preferredDurationMinutes: Int = BankItem.defaultManualLogDurationMinutes
    ) -> (begin: Date, end: Date) {
        let roundedNow = Calendar.current.dateInterval(of: .minute, for: now)?.start ?? now
        var candidateEnd = roundedNow

        while true {
            let candidateBegin = candidateEnd.minus(preferredDurationMinutes, component: .minute)
            let conflicts = overlappingLogs(begin: candidateBegin, end: candidateEnd)
                .sorted { lhs, rhs in
                    if lhs.end != rhs.end {
                        return lhs.end > rhs.end
                    }
                    return lhs.begin > rhs.begin
                }

            guard let latestConflict = conflicts.first else {
                return (candidateBegin, candidateEnd)
            }

            if latestConflict.end < candidateEnd {
                return (latestConflict.end, candidateEnd)
            }

            candidateEnd = latestConflict.begin
        }
    }

    private func validateLogRange(begin: Date, end: Date, excluding log: ItemLog? = nil) throws {
        guard end > begin else {
            throw LogRecordError.invalidRange
        }

        guard end <= Date() else {
            throw LogRecordError.futureRange
        }

        guard begin.elapsedMin(end) >= BankItem.minimumLogDurationMinutes else {
            throw LogRecordError.durationTooShort
        }

        guard overlappingLogs(begin: begin, end: end, excluding: log).isEmpty else {
            throw LogRecordError.overlappingLog
        }
    }

    func updateLog(_ log: ItemLog, begin: Date, end: Date) throws {
        try validateLogRange(begin: begin, end: end, excluding: log)

        log.begin = begin
        log.end = end
        log.saveMin = begin.elapsedMin(end)
        refreshLastTouchFromLogs()
    }

    func removeLog(_ log: ItemLog) {
        logs?.removeAll(where: { $0.id == log.id })
        refreshLastTouchFromLogs()
    }

    @discardableResult
    func recordLog(begin: Date, end: Date = Date()) throws -> ItemLog {
        try validateLogRange(begin: begin, end: end)

        if logs == nil {
            logs = []
        }

        let log = ItemLog(bankItem: self, begin: begin, end: end)
        logs?.append(log)
        refreshLastTouchFromLogs()
        return log
    }

    @discardableResult
    func stopTimer(start: Date, end: Date = Date()) -> TimerStopResult {
        do {
            let log = try recordLog(begin: start, end: end)
            return TimerStopResult(shouldRecord: true, recordedLog: log)
        } catch LogRecordError.durationTooShort {
            return TimerStopResult(shouldRecord: false, recordedLog: nil)
        } catch {
            return TimerStopResult(shouldRecord: false, recordedLog: nil)
        }
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
