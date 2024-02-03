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
    @State var appData = AppData()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BankItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema,  configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Home()
                .frame(minWidth: 380,minHeight: 480)        
        }
        .environment(appData)
        .modelContainer(sharedModelContainer)
    }
}
