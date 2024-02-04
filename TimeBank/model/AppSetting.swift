//
//  GlobalData.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import Foundation
import SwiftUI

class AppSetting :ObservableObject {
    
    @Published var isTimerEnabled: Bool = false {
        didSet {
            NSUbiquitousKeyValueStore.default.set(isTimerEnabled, forKey: "isTimerEnabled")
            DispatchQueue.main.async {
                NSUbiquitousKeyValueStore.default.synchronize()
            }
            
        }
    }
    
    @Published var timerDuration: Double = 0 { // 以分钟为单位
        didSet {
            NSUbiquitousKeyValueStore.default.set(timerDuration, forKey: "timerDuration")
            DispatchQueue.main.async {
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        let store = NSUbiquitousKeyValueStore.default
                
        isTimerEnabled = store.bool(forKey: "isTimerEnabled")
        timerDuration = store.object(forKey: "timerDuration") as? Double ?? 0.0
    }
}
