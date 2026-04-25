import Foundation
import SwiftData
import Testing
@testable import TimeBank

struct BankItemLogicTests {
    private let sessionStore: TimerSessionStore

    init() {
        let suiteName = "TimeBankTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        sessionStore = TimerSessionStore(defaults: defaults)
        TimerSessionCoordinator.clearSession(store: sessionStore)
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
    func recordLogStoresManualLogAndUpdatesLastTouch() throws {
        let item = BankItem(name: "Manual", isSave: true, rate: 1.2)
        let begin = Date(timeIntervalSince1970: 60)
        let end = Date(timeIntervalSince1970: 240)

        let log = try item.recordLog(begin: begin, end: end)

        #expect(item.logs?.count == 1)
        #expect(item.logs?.first === log)
        #expect(log.saveMin == 3)
        #expect(item.lastTouch == end)
    }

    @Test
    func recordLogDoesNotRegressLastTouchWhenBackfillingOlderLog() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 600),
            end: Date(timeIntervalSince1970: 900)
        )

        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 60),
            end: Date(timeIntervalSince1970: 240)
        )

        #expect(item.lastTouch == Date(timeIntervalSince1970: 900))
    }

    @Test
    func recordLogRejectsShortDuration() {
        let item = BankItem(name: "Manual", isSave: true)
        let begin = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 59)

        #expect(throws: BankItem.LogRecordError.durationTooShort) {
            try item.recordLog(begin: begin, end: end)
        }

        #expect(item.logs?.isEmpty == true)
        #expect(item.lastTouch == nil)
    }

    @Test
    func recordLogRejectsFutureRange() {
        let item = BankItem(name: "Manual", isSave: true)
        let now = Date()
        let begin = now.minus(5, component: .minute)
        let end = now.plus(5, component: .minute)

        #expect(throws: BankItem.LogRecordError.futureRange) {
            try item.recordLog(begin: begin, end: end)
        }
    }

    @Test
    func updateLogRefreshesLastTouchFromAllLogs() throws {
        let item = BankItem(name: "Manual", isSave: true)
        let olderLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 60),
            end: Date(timeIntervalSince1970: 240)
        )
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 600),
            end: Date(timeIntervalSince1970: 900)
        )

        try item.updateLog(
            olderLog,
            begin: Date(timeIntervalSince1970: 120),
            end: Date(timeIntervalSince1970: 300)
        )

        #expect(item.lastTouch == Date(timeIntervalSince1970: 900))
        #expect(olderLog.saveMin == 3)
    }

    @Test
    func updateLogCanMoveLatestLogEarlierAndRecomputeLastTouch() throws {
        let item = BankItem(name: "Interrupted", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 720),
            end: Date(timeIntervalSince1970: 900)
        )
        let latestLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 960),
            end: Date(timeIntervalSince1970: 1200)
        )

        try item.updateLog(
            latestLog,
            begin: Date(timeIntervalSince1970: 300),
            end: Date(timeIntervalSince1970: 600)
        )

        #expect(item.lastTouch == Date(timeIntervalSince1970: 900))
        #expect(latestLog.saveMin == 5)
    }

    @Test
    func updateLogRejectsMovingLatestLogIntoExistingLogRange() throws {
        let item = BankItem(name: "Interrupted", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 60),
            end: Date(timeIntervalSince1970: 900)
        )
        let latestLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 960),
            end: Date(timeIntervalSince1970: 1200)
        )

        #expect(throws: BankItem.LogRecordError.overlappingLog) {
            try item.updateLog(
                latestLog,
                begin: Date(timeIntervalSince1970: 600),
                end: Date(timeIntervalSince1970: 840)
            )
        }

        #expect(item.lastTouch == Date(timeIntervalSince1970: 1200))
        #expect(latestLog.begin == Date(timeIntervalSince1970: 960))
        #expect(latestLog.end == Date(timeIntervalSince1970: 1200))
    }

    @Test
    func recordLogRejectsOverlappingRange() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 600),
            end: Date(timeIntervalSince1970: 900)
        )

        #expect(throws: BankItem.LogRecordError.overlappingLog) {
            try item.recordLog(
                begin: Date(timeIntervalSince1970: 840),
                end: Date(timeIntervalSince1970: 1200)
            )
        }
    }

    @Test
    func recordLogAllowsAdjacentRangesWithoutOverlap() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 600),
            end: Date(timeIntervalSince1970: 900)
        )

        let nextLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 900),
            end: Date(timeIntervalSince1970: 1200)
        )

        #expect(nextLog.begin == Date(timeIntervalSince1970: 900))
        #expect(item.logs?.count == 2)
    }

    @Test
    func updateLogRejectsOverlappingRange() throws {
        let item = BankItem(name: "Manual", isSave: true)
        let firstLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 60),
            end: Date(timeIntervalSince1970: 300)
        )
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 600),
            end: Date(timeIntervalSince1970: 900)
        )

        #expect(throws: BankItem.LogRecordError.overlappingLog) {
            try item.updateLog(
                firstLog,
                begin: Date(timeIntervalSince1970: 120),
                end: Date(timeIntervalSince1970: 660)
            )
        }
    }

    @Test
    func updateLogRejectsFutureRange() throws {
        let item = BankItem(name: "Manual", isSave: true)
        let log = try item.recordLog(
            begin: Date().minus(20, component: .minute),
            end: Date().minus(10, component: .minute)
        )

        #expect(throws: BankItem.LogRecordError.futureRange) {
            try item.updateLog(
                log,
                begin: log.begin,
                end: Date().plus(5, component: .minute)
            )
        }
    }

    @Test
    func removeLogRefreshesLastTouchToRemainingLatestLog() throws {
        let item = BankItem(name: "Manual", isSave: true)
        let olderLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 60),
            end: Date(timeIntervalSince1970: 300)
        )
        let latestLog = try item.recordLog(
            begin: Date(timeIntervalSince1970: 600),
            end: Date(timeIntervalSince1970: 900)
        )

        item.removeLog(latestLog)

        #expect(item.logs?.count == 1)
        #expect(item.logs?.first === olderLog)
        #expect(item.lastTouch == Date(timeIntervalSince1970: 300))
    }

    @Test
    func latestAvailableRangeEndingNowUsesLastThirtyMinutesWhenNoConflicts() {
        let item = BankItem(name: "Manual", isSave: true)
        let now = Date(timeIntervalSince1970: 3600)

        let range = item.latestAvailableRangeEndingNow(now: now)

        #expect(range.begin == Date(timeIntervalSince1970: 1800))
        #expect(range.end == now)
    }

    @Test
    func latestAvailableRangeEndingNowShrinksToNearestGapWhenRecentLogConflicts() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 3300),
            end: Date(timeIntervalSince1970: 3540)
        )
        let now = Date(timeIntervalSince1970: 3600)

        let range = item.latestAvailableRangeEndingNow(now: now)

        #expect(range.begin == Date(timeIntervalSince1970: 3540))
        #expect(range.end == now)
    }

    @Test
    func latestAvailableRangeEndingNowFallsBackToOneMinuteWhenNowIsInsideConflict() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 3300),
            end: Date(timeIntervalSince1970: 3600)
        )
        let now = Date(timeIntervalSince1970: 3600)

        let range = item.latestAvailableRangeEndingNow(now: now)

        #expect(range.begin == Date(timeIntervalSince1970: 1500))
        #expect(range.end == Date(timeIntervalSince1970: 3300))
        #expect(range.begin.elapsedMin(range.end) == 30)
    }

    @Test
    func latestAvailableRangeEndingNowSkipsBackAcrossContinuousRecentLogs() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 3000),
            end: Date(timeIntervalSince1970: 3300)
        )
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 3300),
            end: Date(timeIntervalSince1970: 3600)
        )
        let now = Date(timeIntervalSince1970: 3600)

        let range = item.latestAvailableRangeEndingNow(now: now)

        #expect(range.begin == Date(timeIntervalSince1970: 1200))
        #expect(range.end == Date(timeIntervalSince1970: 3000))
        #expect(range.begin.elapsedMin(range.end) == 30)
    }

    @Test
    func latestAvailableRangeEndingNowReturnsShortNearestGapInsteadOfJumpingFurtherBack() throws {
        let item = BankItem(name: "Manual", isSave: true)
        _ = try item.recordLog(
            begin: Date(timeIntervalSince1970: 3300),
            end: Date(timeIntervalSince1970: 3540)
        )
        let now = Date(timeIntervalSince1970: 3600)

        let range = item.latestAvailableRangeEndingNow(now: now, preferredDurationMinutes: 10)

        #expect(range.begin == Date(timeIntervalSince1970: 3540))
        #expect(range.end == Date(timeIntervalSince1970: 3600))
        #expect(range.begin.elapsedMin(range.end) == 1)
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
        sessionStore.save(snapshot)

        let result = TimerSessionCoordinator.reconcileInterruptedSession(items: [item], store: sessionStore)

        #expect(result == nil)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore) == nil)
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
        sessionStore.save(snapshot)

        let result = TimerSessionCoordinator.reconcileInterruptedSession(items: [item], store: sessionStore)

        #expect(result != nil)
        #expect(result?.snapshot.phase == .interrupted)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore)?.phase == .interrupted)
        #expect(item.logs?.count == 1)
        #expect(item.logs?.first?.saveMin == 2)
    }

    @Test
    func deepLinkDecisionOpensWhenNoRunningSession() {
        let requestedID = UUID()

        let decision = TimerSessionCoordinator.deepLinkDecision(for: requestedID, store: sessionStore)

        #expect(decision == .openRequestedItem)
    }

    @Test
    func deepLinkDecisionIgnoresCurrentRunningItem() {
        let itemID = UUID()
        TimerSessionCoordinator.persistRunningSession(
            bankItemID: itemID,
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60),
            store: sessionStore
        )

        let decision = TimerSessionCoordinator.deepLinkDecision(for: itemID, store: sessionStore)

        #expect(decision == .ignoreRunningItem)
    }

    @Test
    func deepLinkDecisionBlocksDifferentItemWhileRunning() {
        let runningItemID = UUID()
        let requestedID = UUID()
        TimerSessionCoordinator.persistRunningSession(
            bankItemID: runningItemID,
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60),
            store: sessionStore
        )

        let decision = TimerSessionCoordinator.deepLinkDecision(for: requestedID, store: sessionStore)

        #expect(decision == .blockWhileRunning(runningItemID: runningItemID))
    }

    @Test
    func timerSessionControllerPersistsAndResumesMatchingRunningSession() {
        let itemID = UUID()
        let controller = TimerSessionController(bankItemID: itemID, store: sessionStore)
        let start = Date(timeIntervalSince1970: 30)

        controller.persistRunning(
            start: start,
            verifiedAt: Date(timeIntervalSince1970: 90)
        )

        #expect(controller.resumeStartCandidate(explicitStart: nil) == start)
    }

    @Test
    func timerSessionControllerPrefersExplicitResumeStart() {
        let itemID = UUID()
        let controller = TimerSessionController(bankItemID: itemID, store: sessionStore)
        let storedStart = Date(timeIntervalSince1970: 30)
        let explicitStart = Date(timeIntervalSince1970: 60)
        controller.persistRunning(
            start: storedStart,
            verifiedAt: Date(timeIntervalSince1970: 90)
        )

        #expect(controller.resumeStartCandidate(explicitStart: explicitStart) == explicitStart)
    }

    @Test
    func timerSessionControllerStopClearsSessionAndRecordsEligibleDuration() {
        let item = BankItem(name: "Focus", isSave: true)
        let controller = TimerSessionController(bankItemID: item.id, store: sessionStore)
        controller.persistRunning(
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60)
        )

        let result = controller.stop(
            item: item,
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 120)
        )

        #expect(result?.shouldRecord == true)
        #expect(item.logs?.count == 1)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore) == nil)
    }

    @Test
    func watchTimerStartPayloadParsesRequiredFields() throws {
        let itemID = UUID()
        let sessionID = UUID()
        let start = Date(timeIntervalSince1970: 120)
        let payload = WatchTimerSyncMessage.startPayload(
            itemID: itemID,
            itemName: "Focus",
            isSave: true,
            sessionID: sessionID,
            start: start
        )

        let message = try #require(WatchTimerSyncMessage(payload))

        #expect(message.action == .startTimer)
        #expect(message.itemID == itemID)
        #expect(message.itemName == "Focus")
        #expect(message.isSave == true)
        #expect(message.sessionID == sessionID)
        #expect(message.start == start)
    }

    @Test
    func watchTimerStartDecisionFallsBackToNameAndTypeWhenItemIDDiffers() throws {
        let watchItemID = UUID()
        let item = BankItem(name: "Focus", isSave: true)
        let other = BankItem(name: "Focus", isSave: false)
        let sessionID = UUID()
        let payload = WatchTimerSyncMessage.startPayload(
            itemID: watchItemID,
            itemName: item.name,
            isSave: item.isSave,
            sessionID: sessionID,
            start: Date(timeIntervalSince1970: 60)
        )
        let message = try #require(WatchTimerSyncMessage(payload))

        let decision = WatchTimerSyncCoordinator.startDecision(
            for: message,
            items: [other, item],
            now: Date(timeIntervalSince1970: 180)
        )

        #expect(decision?.bankItemID == item.id)
        #expect(decision?.sessionID == sessionID)
        #expect(decision?.recordedSeconds == 120)
    }

    @Test
    func watchTimerStopDecisionIgnoresOldSessionID() throws {
        let item = BankItem(name: "Focus", isSave: true)
        let currentSessionID = UUID()
        TimerSessionCoordinator.persistRunningSession(
            bankItemID: item.id,
            sessionID: currentSessionID,
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60),
            store: sessionStore
        )
        let payload = WatchTimerSyncMessage.stopPayload(
            itemID: item.id,
            itemName: item.name,
            isSave: item.isSave,
            sessionID: UUID(),
            end: Date(timeIntervalSince1970: 90)
        )
        let message = try #require(WatchTimerSyncMessage(payload))

        let decision = WatchTimerSyncCoordinator.stopDecision(
            for: message,
            items: [item],
            store: sessionStore
        )

        #expect(decision == nil)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore)?.sessionID == currentSessionID)
    }

    @Test
    func watchTimerStopDecisionFallsBackToNameAndTypeBeforeSessionMatch() throws {
        let watchItemID = UUID()
        let item = BankItem(name: "Focus", isSave: true)
        let sessionID = UUID()
        TimerSessionCoordinator.persistRunningSession(
            bankItemID: item.id,
            sessionID: sessionID,
            start: Date(timeIntervalSince1970: 0),
            verifiedAt: Date(timeIntervalSince1970: 60),
            store: sessionStore
        )
        let payload = WatchTimerSyncMessage.stopPayload(
            itemID: watchItemID,
            itemName: item.name,
            isSave: item.isSave,
            sessionID: sessionID,
            end: Date(timeIntervalSince1970: 90)
        )
        let message = try #require(WatchTimerSyncMessage(payload))

        let decision = WatchTimerSyncCoordinator.stopDecision(
            for: message,
            items: [item],
            store: sessionStore
        )

        #expect(decision?.bankItemID == item.id)
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
        sessionStore.save(snapshot)

        let promptSnapshot = TimerSessionCoordinator.interruptedSessionForPrompt(items: [item], store: sessionStore)

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
        sessionStore.save(snapshot)

        let promptSnapshot = TimerSessionCoordinator.interruptedSessionForPrompt(items: [item], store: sessionStore)

        #expect(promptSnapshot == nil)
    }

    @Test
    func discardInterruptedSessionDeletesMatchingLogAndClearsSnapshot() throws {
        let container = try TimeBankModelContainer.make(isStoredInMemoryOnly: true)
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
        sessionStore.save(snapshot)

        try TimerSessionCoordinator.discardInterruptedSession(
            snapshot,
            items: [item],
            modelContext: context,
            store: sessionStore
        )

        #expect(TimerSessionCoordinator.currentSession(store: sessionStore) == nil)
        #expect(item.logs?.isEmpty == true)
    }

    @Test
    func runningSessionConflictMessageIncludesRunningItemName() {
        let item = BankItem(name: "Focus", isSave: true)

        let message = TimerSessionCoordinator.runningSessionConflictMessage(for: item.id, items: [item])

        #expect(message.contains("Focus"))
    }

    @Test
    func prepareResumeFromLiveActivityRemovesInterruptedLogAndRestoresRunningSession() throws {
        let container = try TimeBankModelContainer.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)

        let item = BankItem(name: "Resume", isSave: true)
        let interruptedSnapshot = TimerSessionSnapshot(
            bankItemID: item.id,
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 120),
            phase: .interrupted
        )
        let log = ItemLog(bankItem: item, begin: interruptedSnapshot.start, end: interruptedSnapshot.lastVerifiedAt)
        item.logs = [log]
        context.insert(item)
        sessionStore.save(interruptedSnapshot)

        let resumedStart = Date(timeIntervalSince1970: 0)
        try TimerSessionCoordinator.prepareResumeFromLiveActivity(
            itemID: item.id,
            start: resumedStart,
            items: [item],
            modelContext: context,
            store: sessionStore
        )

        #expect(item.logs?.isEmpty == true)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore)?.phase == .running)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore)?.start == resumedStart)
    }

    @Test
    func prepareResumeFromLiveActivityDoesNothingWhenItemIsMissing() throws {
        let container = try TimeBankModelContainer.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)

        let snapshot = TimerSessionSnapshot(
            bankItemID: UUID(),
            start: Date(timeIntervalSince1970: 0),
            lastVerifiedAt: Date(timeIntervalSince1970: 120),
            phase: .interrupted
        )
        sessionStore.save(snapshot)

        try TimerSessionCoordinator.prepareResumeFromLiveActivity(
            itemID: snapshot.bankItemID,
            start: snapshot.start,
            items: [],
            modelContext: context,
            store: sessionStore
        )

        #expect(TimerSessionCoordinator.currentSession(store: sessionStore)?.phase == .interrupted)
        #expect(TimerSessionCoordinator.currentSession(store: sessionStore)?.bankItemID == snapshot.bankItemID)
    }
}
