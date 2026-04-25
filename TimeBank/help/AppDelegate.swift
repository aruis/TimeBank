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
        guard let message = WatchTimerSyncMessage(payload) else { return }

        switch message.action {
        case .startTimer:
            Task { @MainActor in
                await handleWatchStart(message)
            }
        case .stopTimer:
            Task { @MainActor in
                await handleWatchStop(message)
            }
        }
    }

    @MainActor
    private func handleWatchStart(_ message: WatchTimerSyncMessage) async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()

        guard let items = try? context.fetch(fetchDescriptor),
              let decision = WatchTimerSyncCoordinator.startDecision(for: message, items: items),
              let item = items.first(where: { $0.id == decision.bankItemID }) else {
            return
        }

        TimerSessionCoordinator.persistRunningSession(
            bankItemID: decision.bankItemID,
            sessionID: decision.sessionID,
            start: decision.start,
            verifiedAt: Date()
        )

#if canImport(ActivityKit)
        let runningState = TimerActivityAttributes.ContentState(
            recordedSeconds: decision.recordedSeconds,
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
            itemID: decision.bankItemID.uuidString,
            name: decision.itemName,
            start: decision.start
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
    private func handleWatchStop(_ message: WatchTimerSyncMessage) async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()
        guard let items = try? context.fetch(fetchDescriptor),
              let decision = WatchTimerSyncCoordinator.stopDecision(for: message, items: items) else {
            return
        }

        if TimerSessionCoordinator.currentSession() != nil {
            TimerSessionCoordinator.clearSession()
        }

#if canImport(ActivityKit)
        let activityItemID = decision.bankItemID.uuidString
        for activity in Activity<TimerActivityAttributes>.activities where activity.attributes.itemID == activityItemID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
#endif
    }
}
#endif
