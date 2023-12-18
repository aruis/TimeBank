//
//  TimeBankApp.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import SwiftUI
import SwiftData

@main
struct TimeBankApp: App {
    
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
            ContentView()
            #if os(macOS)
                .frame(minWidth: 800,minHeight: 580)
            #endif
        }
        .environment(appData)
//        .modelContainer(for: BankItem.self, isAutosaveEnabled: true ,isUndoEnabled: true)
        .modelContainer(sharedModelContainer)
    }
}
