//
//  AppDelegate.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/2/4.
//

#if !os(macOS)
import UIKit
import UserNotifications
import SwiftData
import WatchConnectivity
#if canImport(ActivityKit)
import ActivityKit
#endif

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, WCSessionDelegate {
    private enum WatchTimerMessage {
        static let action = "action"
        static let itemID = "itemID"
        static let itemName = "itemName"
        static let isSave = "isSave"
        static let sessionID = "sessionID"
        static let start = "start"
        static let end = "end"
        static let startTimer = "startTimer"
        static let stopTimer = "stopTimer"
    }

    private lazy var sharedModelContainer: ModelContainer = TimeBankModelContainer.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // 处理权限请求结果
        }
        
        // 设置通知中心的代理
        UNUserNotificationCenter.current().delegate = self

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 当应用处于前台接收到通知时，显示通知
        completionHandler([.banner, .sound,])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleWatchTimerMessage(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleWatchTimerMessage(userInfo)
    }

    private func handleWatchTimerMessage(_ payload: [String: Any]) {
        guard let action = payload[WatchTimerMessage.action] as? String,
              let itemIDString = payload[WatchTimerMessage.itemID] as? String,
              let itemID = UUID(uuidString: itemIDString) else {
            return
        }

        let itemName = payload[WatchTimerMessage.itemName] as? String
        let isSave = payload[WatchTimerMessage.isSave] as? Bool
        let sessionID = (payload[WatchTimerMessage.sessionID] as? String).flatMap(UUID.init(uuidString:))

        switch action {
        case WatchTimerMessage.startTimer:
            guard let startTimestamp = payload[WatchTimerMessage.start] as? TimeInterval else {
                return
            }

            Task { @MainActor in
                await handleWatchStart(
                    itemID: itemID,
                    itemName: itemName,
                    isSave: isSave,
                    sessionID: sessionID,
                    start: Date(timeIntervalSince1970: startTimestamp)
                )
            }
        case WatchTimerMessage.stopTimer:
            Task { @MainActor in
                await handleWatchStop(itemID: itemID, itemName: itemName, isSave: isSave, sessionID: sessionID)
            }
        default:
            break
        }
    }

    @MainActor
    private func handleWatchStart(itemID: UUID, itemName: String?, isSave: Bool?, sessionID: UUID?, start: Date) async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()

        guard let items = try? context.fetch(fetchDescriptor),
              let item = matchingItem(in: items, itemID: itemID, itemName: itemName, isSave: isSave) else {
            return
        }

        TimerSessionCoordinator.persistRunningSession(
            bankItemID: item.id,
            sessionID: sessionID,
            start: start,
            verifiedAt: Date()
        )

#if canImport(ActivityKit)
        let runningState = TimerActivityAttributes.ContentState(
            recordedSeconds: max(Int(Date().timeIntervalSince(start)), 0),
            sessionState: .running
        )

        if let existing = Activity<TimerActivityAttributes>.activities.first(where: {
            $0.attributes.itemID == item.id.uuidString
        }) {
            await existing.update(.init(state: runningState, staleDate: nil))
            return
        }

        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let attributes = TimerActivityAttributes(
            itemID: item.id.uuidString,
            name: item.name,
            start: start
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: runningState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity from watch sync: \(error)")
        }
#endif
    }

    @MainActor
    private func handleWatchStop(itemID: UUID, itemName: String?, isSave: Bool?, sessionID: UUID?) async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()
        let items = try? context.fetch(fetchDescriptor)
        let matchedItem = items.flatMap { matchingItem(in: $0, itemID: itemID, itemName: itemName, isSave: isSave) }
        let matchedBankItemID = matchedItem?.id ?? itemID
        let matchesCurrentSession = TimerSessionCoordinator.currentSessionMatches(
            bankItemID: matchedBankItemID,
            sessionID: sessionID
        )

        guard matchesCurrentSession else {
            return
        }

        if TimerSessionCoordinator.currentSession() != nil {
            TimerSessionCoordinator.clearSession()
        }

#if canImport(ActivityKit)
        let activityItemID = matchedBankItemID.uuidString
        for activity in Activity<TimerActivityAttributes>.activities where activity.attributes.itemID == activityItemID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
#endif
    }

    private func matchingItem(in items: [BankItem], itemID: UUID, itemName: String?, isSave: Bool?) -> BankItem? {
        if let exact = items.first(where: { $0.id == itemID }) {
            return exact
        }

        guard let itemName else {
            return nil
        }

        if let isSave {
            return items.first(where: { $0.name == itemName && $0.isSave == isSave })
        }

        return items.first(where: { $0.name == itemName })
    }
}
#endif
