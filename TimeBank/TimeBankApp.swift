//
//  TimeBankApp.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import SwiftUI
import SwiftData
#if canImport(ActivityKit) && !os(macOS)
import ActivityKit
#endif

@main
struct TimeBankApp: App {
    
    @StateObject var appSetting = AppSetting()
    @State private var isShowSetting = false
    
    #if !os(macOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
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
            Home()
            
            #if os(macOS)
                .frame(minWidth: 480,minHeight: 480)
            #endif
                .sheet(isPresented: $isShowSetting, content: {
                    SettingView()
                        .presentationDetents([.medium])
                })
                .task {
                    await reconcileInterruptedTimerSessionIfNeeded()
                }

        }
        .commands{
            CommandGroup(replacing: .appSettings, addition: {
                Button("Setting"){
                    isShowSetting = true
                }.keyboardShortcut(",", modifiers: [.command])
            })
        }
        
        .environmentObject(appSetting)
//        .modelContainer(for: BankItem.self, isAutosaveEnabled: true ,isUndoEnabled: true)
        .modelContainer(sharedModelContainer)
        
    }

    @MainActor
    private func reconcileInterruptedTimerSessionIfNeeded() async {
        let context = ModelContext(sharedModelContainer)
        let fetchDescriptor = FetchDescriptor<BankItem>()

        guard let items = try? context.fetch(fetchDescriptor),
              let reconcileResult = TimerSessionCoordinator.reconcileInterruptedSession(items: items) else {
            return
        }
        try? context.save()

#if canImport(ActivityKit) && !os(macOS)
        let interruptedState = TimerActivityAttributes.ContentState(
            recordedSeconds: reconcileResult.snapshot.recordedSeconds,
            sessionState: .interrupted
        )

        for activity in Activity<TimerActivityAttributes>.activities where activity.attributes.itemID == reconcileResult.snapshot.bankItemID.uuidString {
            await activity.update(
                .init(state: interruptedState, staleDate: nil)
            )
        }
#endif
    }
}
