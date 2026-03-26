//
//  GlobalData.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import Foundation
import SwiftUI
import UserNotifications
#if os(iOS) || os(visionOS)
import UIKit
#endif

class AppSetting :ObservableObject {
    
    let store = NSUbiquitousKeyValueStore.default
    
    @Published var isTimerEnabled: Bool = false {
        didSet {
            store.set(isTimerEnabled, forKey: "isTimerEnabled")
            DispatchQueue.main.async {
                self.store.synchronize()
            }
            
        }
    }
    
    @Published var timerDuration: Double = 0 { // 以分钟为单位
        didSet {
            store.set(timerDuration, forKey: "timerDuration")
            DispatchQueue.main.async {
                self.store.synchronize()
            }
        }
    }
    
    @Published var isEnableRate: Bool = false {
        didSet {
            store.set(isEnableRate, forKey: "isEnableRate")
            DispatchQueue.main.async {
                self.store.synchronize()
            }
        }
    }

    @Published var swapThemeColors: Bool = false {
        didSet {
            store.set(swapThemeColors, forKey: "swapThemeColors")
            DispatchQueue.main.async {
                self.store.synchronize()
            }
        }
    }
    
    init() {
        loadSettings()
        
        // 添加 NotificationCenter 观察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeyValueStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }
    
    deinit {
        // 移除 NotificationCenter 观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadSettings() {
        //        let store = NSUbiquitousKeyValueStore.default
        
        isTimerEnabled = store.bool(forKey: "isTimerEnabled")
        isEnableRate = store.bool(forKey: "isEnableRate")
        swapThemeColors = store.bool(forKey: "swapThemeColors")
        timerDuration = store.object(forKey: "timerDuration") as? Double ?? 0.0
    }
    
    @objc func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        // 当 iCloud Key-Value Store 的数据发生外部变化时，重新加载设置
        DispatchQueue.main.async {
            self.loadSettings()
        }
        
        
        // 如果你需要根据具体的变化做出响应，你可以从 notification 中获取更多信息
        // 例如，你可以检查 notification.userInfo 中的 NSUbiquitousKeyValueStoreChangeReasonKey 和 NSUbiquitousKeyValueStoreChangedKeysKey
    }
    
    func requestNotificationPermission() async -> Result<Bool, NotificationPermissionError> {
        do {
            let success = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if success {
                return .success(true)
            }

            await MainActor.run {
                isTimerEnabled = false
            }
            return .failure(.denied)
        } catch {
            await MainActor.run {
                isTimerEnabled = false
            }
            return .failure(.error(error))
        }
    }
        
    #if os(iOS) || os(visionOS)
    func openAppSettings() {
        DispatchQueue.main.async {
            if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
    #endif

    func themeColor(isSave: Bool) -> Color {
        let defaultColor = isSave ? Color.red : Color.green
        let swappedColor = isSave ? Color.green : Color.red
        return swapThemeColors ? swappedColor : defaultColor
    }
}

enum NotificationPermissionError: Error {
    case denied
    case error(Error)
}

enum HapticFeedback {
    static func tap() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
    }

    static func selection() {
#if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
    }

    static func success() {
#if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }

    static func warning() {
#if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
#endif
    }
}
