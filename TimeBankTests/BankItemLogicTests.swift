import Foundation
import Testing
@testable import TimeBank

struct BankItemLogicTests {
    @Test
    func filteredAndSortedPinsFirstThenLastTouchThenCreateTime() {
        let pinned = BankItem(name: "Pinned", isSave: true)
        pinned.isPin = true
        pinned.lastTouch = Date(timeIntervalSince1970: 200)

        let recent = BankItem(name: "Recent", isSave: true)
        recent.lastTouch = Date(timeIntervalSince1970: 150)

        let older = BankItem(name: "Older", isSave: true)
        older.lastTouch = Date(timeIntervalSince1970: 100)

        let noTouchNewer = BankItem(name: "NoTouchNewer", isSave: true)
        noTouchNewer.lastTouch = nil
        noTouchNewer.createTime = Date(timeIntervalSince1970: 75)

        let noTouchOlder = BankItem(name: "NoTouchOlder", isSave: true)
        noTouchOlder.lastTouch = nil
        noTouchOlder.createTime = Date(timeIntervalSince1970: 50)

        let kill = BankItem(name: "Kill", isSave: false)

        let result = [recent, noTouchOlder, pinned, kill, older, noTouchNewer]
            .filteredAndSorted(isSave: true)

        #expect(result.map(\.name) == ["Pinned", "Recent", "Older", "NoTouchNewer", "NoTouchOlder"])
    }

    @Test
    func totalsAndBalanceRespectRateToggle() {
        let save = BankItem(name: "Save", isSave: true, rate: 2)
        save.logs = [ItemLog(bankItem: save, begin: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 120))]

        let kill = BankItem(name: "Kill", isSave: false, rate: 1.5)
        kill.logs = [ItemLog(bankItem: kill, begin: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 60))]

        let items = [save, kill]

        #expect(items.totalValue(isSave: true, useRate: false) == 2)
        #expect(items.totalValue(isSave: false, useRate: false) == 1)
        #expect(items.balanceValue(useRate: false) == 1)

        #expect(items.totalValue(isSave: true, useRate: true) == 4)
        #expect(items.totalValue(isSave: false, useRate: true) == 1.5)
        #expect(items.balanceValue(useRate: true) == 2.5)
    }

    @Test
    func stopTimerSkipsShortDurations() {
        let item = BankItem(name: "Short", isSave: true)
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 59)

        let result = item.stopTimer(start: start, end: end)

        #expect(result.shouldRecord == false)
        #expect(result.recordedLog == nil)
        #expect(item.logs?.isEmpty == true)
        #expect(item.lastTouch == nil)
    }

    @Test
    func stopTimerRecordsLogAndUpdatesLastTouch() {
        let item = BankItem(name: "Recorded", isSave: true, rate: 1.2)
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 120)

        let result = item.stopTimer(start: start, end: end)

        #expect(result.shouldRecord)
        #expect(result.recordedLog != nil)
        #expect(item.logs?.count == 1)
        #expect(item.logs?.first?.saveMin == 2)
        #expect(item.lastTouch == end)
    }
}
