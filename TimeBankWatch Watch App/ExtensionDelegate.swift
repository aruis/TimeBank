//
//  ExtensionDelegate.swift
//  TimeBankWatch Watch App
//
//  Created by 牧云踏歌 on 2024/1/10.
//

import Foundation
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let lifecycleInfo = WatchLifecycleInfo()

    func applicationDidBecomeActive() {
        lifecycleInfo.lastActiveDate = Date()
    }

    // 处理其他生命周期事件
}
