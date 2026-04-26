//
//  WatchHome.swift
//  TimeBankWatch Watch App
//
//  Created by 牧云踏歌 on 2024/1/9.
//

import SwiftUI
import SwiftData

struct WatchHome: View {
    private enum ActiveSheet: Identifiable {
        case play
        case edit

        var id: Int {
            switch self {
            case .play:
                return 0
            case .edit:
                return 1
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: AppSetting
    
    @State private var pageType = PageType.home
    @State private var isShowNew = false
        
    @Query(sort: \BankItem.lastTouch ,order: .reverse) private var items: [BankItem]
    
    @State private var isShowSetting = false
    @State private var selectItem: BankItem?
    @State private var activeSheet: ActiveSheet?
    @State private var isShowingItemActions = false
    @State private var interruptedSession: TimerSessionSnapshot?
    @State private var isShowingInterruptedPrompt = false

    
    var body: some View {
        NavigationStack{
            TabView(selection: $pageType){
                homeView()
                    .tag(PageType.home)
                listView(type: .save)
                    .tag(PageType.save)
                listView(type: .kill)
                    .tag(PageType.kill)
            }
            .sheet(isPresented: $isShowNew){
                NewBankItem(pageType: $pageType, bankItem: .constant(BankItem()))
                    .onDisappear(perform: {
                        isShowNew = false
                    })
            }
            .sheet(isPresented: $isShowSetting, content: {
                SettingView()
                    .presentationDetents([.medium])
            })
            .confirmationDialog(
                "Item Actions",
                isPresented: $isShowingItemActions,
                titleVisibility: .visible
            ) {
                if let selectItem {
                    Button(selectItem.isPin ? "Unpin" : "Pin") {
                        selectItem.isPin.toggle()
                        try? modelContext.save()
                    }

                    Button("Edit") {
                        activeSheet = .edit
                    }

                    Button("Delete", role: .destructive) {
                        modelContext.delete(selectItem)
                        try? modelContext.save()
                        self.selectItem = nil
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .play:
                    if let selectItem {
                        ShowItemWatch(bankItem: binding(for: selectItem))
                    }
                case .edit:
                    if let selectItem {
                        NewBankItem(pageType: .constant(pageType), bankItem: binding(for: selectItem))
                            .presentationDetents([.medium])
                    }
                }
            }
            .alert("Session Interrupted", isPresented: $isShowingInterruptedPrompt, presenting: interruptedSession) { snapshot in
                Button("Keep") {
                    clearInterruptedSessionPrompt()
                }
                Button("Discard", role: .destructive) {
                    discardInterruptedSession(snapshot)
                }
            } message: { snapshot in
                Text(TimerSessionCoordinator.interruptedMessage(for: snapshot))
            }
            .navigationTitle(navigationTitle)
            .toolbarTitleDisplayMode(.inline)
            .animation(.default, value: pageType)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button("Edit", systemImage: "ellipsis"){
                        isShowSetting = true
                    }

                }

            }
            .onChange(of: items) {
                resolveInterruptedSessionIfNeeded()
            }
            .task {
                resolveInterruptedSessionIfNeeded()
            }

        }                    
    }
    
    
    @ViewBuilder
    func homeView() -> some View{
        TabView{
            numberView(title: String(localized: "Your Balance"),value: balanceString)
            numberView(title: "SaveTime",value: saveMinString)
            numberView(title: "KillTime",value: killMinString)
        }
#if os(watchOS)
        .tabViewStyle(.verticalPage)
#else
        .tabViewStyle(.page)
#endif
    }
    
    @ViewBuilder
    func numberView(title:String,value:String) -> some View{
        VStack{
            Text(value)
                .font(.largeTitle)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.subheadline)
                .monospaced()
        }
    }
    
    
    @ViewBuilder
    func listView(type: PageType) -> some View{
        TabView{
            ForEach(list(type: type)){ item in
                VStack{
                    Text(item.name)
                        .font(.title)
                    Text(settings.isEnableRate ? "$ \(item.exchangeString)" : "\(item.saveMin) MIN")
                        .font(.body)
                    Group{
                        Text("Last Execute:")
                        if let lastTouch = item.lastTouch {
                            Text(lastTouch,style: .date)
                        } else{
                            Text("-")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .toolbar{
                    ToolbarItem(placement: .topBarTrailing){
                        Button{
                            selectItem = item
                            isShowingItemActions = true
                        }label: {
                            Label("Edit", systemImage: "slider.horizontal.3")
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar, content: {
                        Button{
                            selectItem = item
                            activeSheet = .play
                        }label: {
                            Label("Play",systemImage: "play")
                        }
                        .controlSize(.large)
                                                                        
                    })
                }

                
            }

            Button("Add", systemImage: "plus", action: {
                isShowNew  = true
            })
            .padding(.horizontal,15)

        }
#if os(watchOS)
        .tabViewStyle(.verticalPage)
#else
        .tabViewStyle(.page)
#endif
        .containerBackground(settings.themeColor(isSave: type == .save).gradient, for: .navigation)

    }

    private func binding(for item: BankItem) -> Binding<BankItem> {
        Binding(
            get: { item },
            set: { _ in }
        )
    }

    private func resolveInterruptedSessionIfNeeded() {
        guard interruptedSession == nil,
              let snapshot = TimerSessionCoordinator.interruptedSessionForPrompt(items: items) else {
            return
        }

        interruptedSession = snapshot
        isShowingInterruptedPrompt = true
    }

    private func discardInterruptedSession(_ snapshot: TimerSessionSnapshot) {
        do {
            try TimerSessionCoordinator.discardInterruptedSession(snapshot, items: items, modelContext: modelContext)
        } catch {
            return
        }

        clearInterruptedSessionPrompt()
    }

    private func clearInterruptedSessionPrompt() {
        TimerSessionCoordinator.clearSession()
        interruptedSession = nil
        isShowingInterruptedPrompt = false
    }
    
    func list(type:PageType) -> [BankItem]{
        items.filteredAndSorted(isSave: type == .save)
    }

    var navigationTitle: LocalizedStringKey {
        switch pageType {
        case .home:
            return "TimeBank"
        case .save:
            return "SaveTime"
        case .kill:
            return "KillTime"
        }
    }
    
    
    var saveMin:Float{
        items.totalValue(isSave: true, useRate: settings.isEnableRate)
    }
    
    var killMin:Float{
        items.totalValue(isSave: false, useRate: settings.isEnableRate)
    }
    
    var saveMinString:String{
        if settings.isEnableRate {
            return String(format: "%.2f",self.saveMin)
        }else{
            return String(format: "%.0f",self.saveMin)
        }
    }
    
    var killMinString:String{
        if settings.isEnableRate {
            return String(format: "%.2f",self.killMin)
        }else{
            return String(format: "%.0f",self.killMin)
        }
    }
    
    var balanceString:String{
        if settings.isEnableRate {
            return String(format: "%.2f", items.balanceValue(useRate: true))
        }else{
            return String(format: "%.0f", items.balanceValue(useRate: false))
        }
        
    }
    
}

#Preview {
    WatchHome()
        .environmentObject(AppSetting())
        .modelContainer(for: [BankItem.self, ItemLog.self], inMemory: true)
}
