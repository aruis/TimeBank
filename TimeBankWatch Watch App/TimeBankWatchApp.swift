//
//  TimeBankWatchApp.swift
//  TimeBankWatch Watch App
//
//  Created by 牧云踏歌 on 2024/1/9.
//

import SwiftUI
import SwiftData
import WatchConnectivity

final class WatchLiveActivityMessenger: NSObject, WCSessionDelegate {
    static let shared = WatchLiveActivityMessenger()

    func activate() {
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sendStart(itemID: UUID, itemName: String, isSave: Bool, sessionID: UUID, start: Date) {
        send(WatchTimerSyncMessage.startPayload(
            itemID: itemID,
            itemName: itemName,
            isSave: isSave,
            sessionID: sessionID,
            start: start
        ))
    }

    func sendStop(itemID: UUID, itemName: String, isSave: Bool, sessionID: UUID, end: Date) {
        send(WatchTimerSyncMessage.stopPayload(
            itemID: itemID,
            itemName: itemName,
            isSave: isSave,
            sessionID: sessionID,
            end: end
        ))
    }

    private func send(_ payload: [String: Any]) {
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        if session.activationState != .activated {
            session.activate()
        }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(payload)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
    }
}

@main
struct TimeBankWatch_Watch_AppApp: App {
    @StateObject var appSetting = AppSetting()
    
    var sharedModelContainer: ModelContainer = TimeBankModelContainer.shared
    
    var body: some Scene {
        WindowGroup {
                WatchHome()
                    .task {
                        WatchLiveActivityMessenger.shared.activate()
                        await reconcileInterruptedTimerSessionIfNeeded()
                    }
        }        
        .environmentObject(appSetting)
        //        .modelContainer(for: BankItem.self, isAutosaveEnabled: true ,isUndoEnabled: true)
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func reconcileInterruptedTimerSessionIfNeeded() async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()

        guard let items = try? context.fetch(fetchDescriptor) else {
            return
        }

        _ = TimerSessionCoordinator.reconcileInterruptedSession(items: items)
        try? context.save()
    }
}
