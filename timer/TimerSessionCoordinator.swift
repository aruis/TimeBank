import Foundation
import SwiftData

enum TimeBankModelContainer {
    static let shared: ModelContainer = {
        do {
            return try make()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            BankItem.self,
            ItemLog.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

enum TimerSessionPhase: String, Codable {
    case running
    case interrupted
}

struct TimerSessionSnapshot: Codable {
    var bankItemID: UUID
    var sessionID: UUID? = nil
    var start: Date
    var lastVerifiedAt: Date
    var phase: TimerSessionPhase

    var recordedSeconds: Int {
        max(Int(lastVerifiedAt.timeIntervalSince(start)), 0)
    }
}

enum TimerSessionDeepLinkDecision: Equatable {
    case openRequestedItem
    case ignoreRunningItem
    case blockWhileRunning(runningItemID: UUID)
}

struct TimerSessionReconcileResult {
    let snapshot: TimerSessionSnapshot
}

enum TimerSessionStore {
    private static let key = "activeTimerSession"
    private static let defaults = UserDefaults.standard

    static func load() -> TimerSessionSnapshot? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(TimerSessionSnapshot.self, from: data)
    }

    static func save(_ snapshot: TimerSessionSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    static func clear() {
        defaults.removeObject(forKey: key)
    }
}

enum TimerSessionCoordinator {
    static func currentSession() -> TimerSessionSnapshot? {
        TimerSessionStore.load()
    }

    static func persistRunningSession(bankItemID: UUID, sessionID: UUID? = nil, start: Date, verifiedAt: Date) {
        TimerSessionStore.save(
            TimerSessionSnapshot(
                bankItemID: bankItemID,
                sessionID: sessionID,
                start: start,
                lastVerifiedAt: verifiedAt,
                phase: .running
            )
        )
    }

    static func clearSession() {
        TimerSessionStore.clear()
    }

    static func deepLinkDecision(for requestedItemID: UUID) -> TimerSessionDeepLinkDecision {
        guard let runningSession = TimerSessionStore.load(), runningSession.phase == .running else {
            return .openRequestedItem
        }

        if runningSession.bankItemID == requestedItemID {
            return .ignoreRunningItem
        }

        return .blockWhileRunning(runningItemID: runningSession.bankItemID)
    }

    static func runningSessionConflictMessage(for runningItemID: UUID, items: [BankItem]) -> String {
        let itemName = items.first(where: { $0.id == runningItemID })?.name ?? "another item"
        return "A timer is already running for \(itemName). Stop or resolve it before opening a different item from the widget."
    }

    static func reconcileInterruptedSession(items: [BankItem]) -> TimerSessionReconcileResult? {
        guard var snapshot = TimerSessionStore.load(), snapshot.phase == .running else {
            return nil
        }

        guard let item = items.first(where: { $0.id == snapshot.bankItemID }) else {
            TimerSessionStore.clear()
            return nil
        }

        let stopResult = item.stopTimer(start: snapshot.start, end: snapshot.lastVerifiedAt)
        guard stopResult.shouldRecord else {
            TimerSessionStore.clear()
            return nil
        }

        snapshot.phase = .interrupted
        TimerSessionStore.save(snapshot)
        return TimerSessionReconcileResult(snapshot: snapshot)
    }

    static func interruptedSessionForPrompt(items: [BankItem]) -> TimerSessionSnapshot? {
        guard let snapshot = TimerSessionStore.load(),
              snapshot.phase == .interrupted,
              matchingInterruptedLog(for: snapshot, items: items) != nil else {
            return nil
        }

        return snapshot
    }

    static func interruptedMessage(for snapshot: TimerSessionSnapshot) -> String {
        let recordedMinutes = max(snapshot.recordedSeconds / 60, 1)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "Recorded \(recordedMinutes) min until \(formatter.string(from: snapshot.lastVerifiedAt)). You can keep it, adjust it, or discard it."
    }

    static func matchingInterruptedLog(for snapshot: TimerSessionSnapshot, items: [BankItem]) -> ItemLog? {
        guard let item = items.first(where: { $0.id == snapshot.bankItemID }),
              let logs = item.logs else {
            return nil
        }

        return logs.first {
            abs($0.begin.timeIntervalSince(snapshot.start)) < 1 &&
            abs($0.end.timeIntervalSince(snapshot.lastVerifiedAt)) < 1
        }
    }

    static func discardInterruptedSession(
        _ snapshot: TimerSessionSnapshot,
        items: [BankItem],
        modelContext: ModelContext
    ) throws {
        if let log = matchingInterruptedLog(for: snapshot, items: items) {
            log.bankItem?.removeLog(log)
            modelContext.delete(log)
            try modelContext.save()
        }

        TimerSessionStore.clear()
    }

    static func prepareResumeFromLiveActivity(
        itemID: UUID,
        start: Date,
        items: [BankItem],
        modelContext: ModelContext
    ) throws {
        guard items.contains(where: { $0.id == itemID }) else {
            return
        }

        if let snapshot = TimerSessionStore.load(),
           snapshot.phase == .interrupted,
           snapshot.bankItemID == itemID,
           let log = matchingInterruptedLog(for: snapshot, items: items) {
            log.bankItem?.removeLog(log)
            modelContext.delete(log)
            try modelContext.save()
        }

        persistRunningSession(bankItemID: itemID, sessionID: snapshotSessionID(for: itemID), start: start, verifiedAt: Date())
    }

    static func currentSessionMatches(bankItemID: UUID, sessionID: UUID?) -> Bool {
        guard let snapshot = currentSession(),
              snapshot.bankItemID == bankItemID else {
            return false
        }

        guard let sessionID else {
            return true
        }

        return snapshot.sessionID == sessionID
    }

    private static func snapshotSessionID(for bankItemID: UUID) -> UUID? {
        guard let snapshot = currentSession(), snapshot.bankItemID == bankItemID else {
            return nil
        }

        return snapshot.sessionID
    }
}
