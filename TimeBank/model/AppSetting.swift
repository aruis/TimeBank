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
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: .success(true))
                    } else if let error = error {
                        continuation.resume(returning: .failure(.error(error)))
                        self.isTimerEnabled = false
                    } else {
                        continuation.resume(returning: .failure(.denied))
                        self.isTimerEnabled = false
                    }
                }
            }
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
}

enum NotificationPermissionError: Error {
    case denied
    case error(Error)
}
