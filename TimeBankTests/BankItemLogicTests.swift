import Foundation
import SwiftData
import Testing
@testable import TimeBank

struct BankItemLogicTests {
    init() {
        TimerSessionCoordinator.clearSession()
    }

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

    @Test
    func reconcileInterruptedSessionClearsShortRunningSnapshot() {
        let item = BankItem(name: "Short", isSave: true)
        let snapshot = TimerSessionSnapshot(
            bankItemID: item.id,
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 59),
            phase: .running
        )
        TimerSessionStore.save(snapshot)

        let result = TimerSessionCoordinator.reconcileInterruptedSession(items: [item])

        #expect(result == nil)
        #expect(TimerSessionCoordinator.currentSession() == nil)
        #expect(item.logs?.isEmpty == true)
    }

    @Test
    func reconcileInterruptedSessionRecordsLogAndStoresInterruptedSnapshot() {
        let item = BankItem(name: "Recorded", isSave: true)
        let snapshot = TimerSessionSnapshot(
            bankItemID: item.id,
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 120),
            phase: .running
        )
        TimerSessionStore.save(snapshot)

        let result = TimerSessionCoordinator.reconcileInterruptedSession(items: [item])

        #expect(result != nil)
        #expect(result?.snapshot.phase == .interrupted)
        #expect(TimerSessionCoordinator.currentSession()?.phase == .interrupted)
        #expect(item.logs?.count == 1)
        #expect(item.logs?.first?.saveMin == 2)
    }

    @Test
    func deepLinkDecisionOpensWhenNoRunningSession() {
        let requestedID = UUID()

        let decision = TimerSessionCoordinator.deepLinkDecision(for: requestedID)

        #expect(decision == .openRequestedItem)
    }

    @Test
    func deepLinkDecisionIgnoresCurrentRunningItem() {
        let itemID = UUID()
        TimerSessionCoordinator.persistRunningSession(
            bankItemID: itemID,
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60)
        )

        let decision = TimerSessionCoordinator.deepLinkDecision(for: itemID)

        #expect(decision == .ignoreRunningItem)
    }

    @Test
    func deepLinkDecisionBlocksDifferentItemWhileRunning() {
        let runningItemID = UUID()
        let requestedID = UUID()
        TimerSessionCoordinator.persistRunningSession(
            bankItemID: runningItemID,
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60)
        )

        let decision = TimerSessionCoordinator.deepLinkDecision(for: requestedID)

        #expect(decision == .blockWhileRunning(runningItemID: runningItemID))
    }

    @Test
    func interruptedSessionForPromptReturnsSnapshotWithMatchingLog() {
        let item = BankItem(name: "Recorded", isSave: true)
        let snapshot = TimerSessionSnapshot(
            bankItemID: item.id,
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 120),
            phase: .interrupted
        )
        item.logs = [
            ItemLog(
                bankItem: item,
                begin: snapshot.start,
                end: snapshot.lastVerifiedAt
            )
        ]
        TimerSessionStore.save(snapshot)

        let promptSnapshot = TimerSessionCoordinator.interruptedSessionForPrompt(items: [item])

        #expect(promptSnapshot?.bankItemID == item.id)
        #expect(promptSnapshot?.phase == .interrupted)
    }

    @Test
    func interruptedSessionForPromptSkipsSnapshotWithoutMatchingLog() {
        let item = BankItem(name: "Recorded", isSave: true)
        let snapshot = TimerSessionSnapshot(
            bankItemID: item.id,
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 120),
            phase: .interrupted
        )
        TimerSessionStore.save(snapshot)

        let promptSnapshot = TimerSessionCoordinator.interruptedSessionForPrompt(items: [item])

        #expect(promptSnapshot == nil)
    }

    @Test
    func discardInterruptedSessionDeletesMatchingLogAndClearsSnapshot() throws {
        let schema = Schema([
            BankItem.self,
            ItemLog.self,
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        let context = ModelContext(container)

        let item = BankItem(name: "Recorded", isSave: true)
        let snapshot = TimerSessionSnapshot(
            bankItemID: item.id,
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 120),
            phase: .interrupted
        )
        let log = ItemLog(bankItem: item, begin: snapshot.start, end: snapshot.lastVerifiedAt)
        item.logs = [log]
        context.insert(item)
        TimerSessionStore.save(snapshot)

        try TimerSessionCoordinator.discardInterruptedSession(snapshot, items: [item], modelContext: context)

        #expect(TimerSessionCoordinator.currentSession() == nil)
        #expect(item.logs?.isEmpty == true)
    }

    @Test
    func runningSessionConflictMessageIncludesRunningItemName() {
        let item = BankItem(name: "Focus", isSave: true)

        let message = TimerSessionCoordinator.runningSessionConflictMessage(for: item.id, items: [item])

        #expect(message.contains("Focus"))
    }
}
