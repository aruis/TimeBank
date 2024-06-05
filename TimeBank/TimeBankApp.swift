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
    
    @StateObject var appSetting = AppSetting()
    @State private var isShowSetting = false
    
    #if !os(macOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
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
            NavigationStack{
                Home()
            }
            
            #if os(macOS)
                .frame(minWidth: 480,minHeight: 480)
            #endif
                .sheet(isPresented: $isShowSetting, content: {
                    SettingView()
                        .presentationDetents([.medium])
                })

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
}
