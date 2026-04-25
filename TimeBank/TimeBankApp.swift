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
    @State private var activeReleaseNote: ReleaseNote?
    @State private var hasCheckedReleaseNote = false
    
    #if !os(macOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var sharedModelContainer: ModelContainer = TimeBankModelContainer.shared

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
                .sheet(item: $activeReleaseNote) { note in
                    ReleaseNoteView(note: note) {
                        ReleaseNotesManager.shared.markShown(version: note.version)
                        activeReleaseNote = nil
                    }
#if os(iOS) || os(visionOS)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
#endif
                    .interactiveDismissDisabled()
                }
                .task {
                    await reconcileInterruptedTimerSessionIfNeeded()
                    checkReleaseNoteIfNeeded()
                }

        }
        .commands{
            CommandGroup(replacing: .appSettings, addition: {
                Button("Settings"){
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
        #if canImport(ActivityKit) && !os(macOS)
        if let snapshot = TimerSessionCoordinator.currentSession(),
           snapshot.phase == .running,
           Activity<TimerActivityAttributes>.activities.contains(where: {
               $0.attributes.itemID == snapshot.bankItemID.uuidString
           }) {
            return
        }
        #endif

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

    @MainActor
    private func checkReleaseNoteIfNeeded() {
        guard !hasCheckedReleaseNote else { return }
        hasCheckedReleaseNote = true

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        if let note = ReleaseNotesManager.shared.noteToShow(for: currentVersion) {
            activeReleaseNote = note
        }
    }
}
