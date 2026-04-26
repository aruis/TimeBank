//
//  TimerNotificationScheduler.swift
//  TimeBank
//
//  Created by Codex on 2026/4/26.
//

import Foundation
import UserNotifications

struct TimerNotificationScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func scheduleCompletionNotification(
        identifier: String,
        itemName: String,
        isSave: Bool,
        timerDurationMinutes: Double,
        elapsedSeconds: Int,
        onUnavailable: @escaping () -> Void
    ) {
        let remainingSeconds = max((timerDurationMinutes * 60) - Double(elapsedSeconds), 0)
        guard remainingSeconds > 0 else {
            DispatchQueue.main.async(execute: onUnavailable)
            return
        }

        center.getNotificationSettings { notificationSettings in
            guard Self.isAuthorized(notificationSettings.authorizationStatus) else {
                DispatchQueue.main.async(execute: onUnavailable)
                return
            }

            let content = UNMutableNotificationContent()
            content.title = isSave ? String(localized: "SaveTime Complete") : String(localized: "KillTime Complete")

            let actionWord = isSave ? String(localized: "Invested") : String(localized: "Spent")
            content.subtitle = String(
                format: String(localized: "YouHaveJustInvested"),
                locale: Locale.current,
                String(Int(timerDurationMinutes)),
                "[\(itemName)]",
                actionWord
            )
            content.sound = UNNotificationSound.default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingSeconds, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional:
            return true
        #if !os(macOS)
        case .ephemeral:
            return true
        #endif
        default:
            return false
        }
    }
}
