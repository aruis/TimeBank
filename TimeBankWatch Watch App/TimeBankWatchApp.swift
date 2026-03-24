//
//  TimeBankWatchApp.swift
//  TimeBankWatch Watch App
//
//  Created by 牧云踏歌 on 2024/1/9.
//

import SwiftUI
import SwiftData

@main
struct TimeBankWatch_Watch_AppApp: App {
    @StateObject var appSetting = AppSetting()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BankItem.self,
            ItemLog.self,
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
                WatchHome()
                    .task {
                        await reconcileInterruptedTimerSessionIfNeeded()
                    }
        }        
        .environmentObject(appSetting)
        //        .modelContainer(for: BankItem.self, isAutosaveEnabled: true ,isUndoEnabled: true)
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func reconcileInterruptedTimerSessionIfNeeded() async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()

        guard let items = try? context.fetch(fetchDescriptor) else {
            return
        }

        _ = TimerSessionCoordinator.reconcileInterruptedSession(items: items)
        try? context.save()
    }
}
