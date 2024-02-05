//
//  AppDelegate.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/2/4.
//

#if !os(macOS)
import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // 处理权限请求结果
        }
        
        // 设置通知中心的代理
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 当应用处于前台接收到通知时，显示通知
        completionHandler([.banner, .sound,])
    }
}
#endif
