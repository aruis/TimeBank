//
//  TimeBankVisionApp.swift
//  TimeBankVision
//
//  Created by 牧云踏歌 on 2024/1/10.
//

import SwiftUI
import SwiftData

@main
struct TimeBankVisionApp: App {
    @StateObject var appSetting = AppSetting()
    
    var sharedModelContainer: ModelContainer = TimeBankModelContainer.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack{
                Home()
            }
            
            
            .frame(minWidth: 380,minHeight: 480)
            
        }
        .environmentObject(appSetting)
//        .modelContainer(for: BankItem.self, isAutosaveEnabled: true ,isUndoEnabled: true)
        .modelContainer(sharedModelContainer)
    }
}
