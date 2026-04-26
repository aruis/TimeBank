//
//  Home.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI
import SwiftData
import OSLog
#if canImport(ActivityKit) && !os(macOS)
import ActivityKit
#endif

struct Home: View {
        
    @EnvironmentObject var settings: AppSetting
    @Environment(\.modelContext) private var modelContext
    
    @State private var pageType = PageType.save
    @State private var isShowAdd = false
    @State private var isShowSetting = false
    @State private var isShowGlobalStats = false
    @State private var isShowBalanceTitle = false
    @State private var routedItemID: UUID?
    @State private var routedItem: BankItem?
    @State private var routedResumeStart: Date?
    @State private var interruptedSession: TimerSessionSnapshot?
    @State private var interruptedLog: ItemLog?
    @State private var isShowingInterruptedPrompt = false
    @State private var runningSessionConflictItemName: String?
    
    @Query private var items: [BankItem]
    
    private let floatingButtonDiameter: CGFloat = 58
    private let balanceBadgeHeight: CGFloat = 42

    private var topBarExtraPaddingForPad: CGFloat {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0
        #else
        0
        #endif
    }
    
    var body: some View {
        homeSurface()
    }

    @ViewBuilder
    private func homeSurface() -> some View {
        homeScaffold()
        .background(
            Rectangle()
                .fill(.black.opacity(0.05))
                .ignoresSafeArea()
            
        )
        #if os(macOS)
        .overlay(alignment: .bottomTrailing, content: {
            addButton()
        })
        #endif
        #if !os(visionOS)
        .sensoryFeedback(.selection, trigger: pageType)
        #endif
        .sheet(isPresented: $isShowAdd, content: {
            NewBankItem(pageType:$pageType,bankItem: .constant(BankItem()))
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isShowSetting, content: {
            SettingView()
        })
#if os(iOS) || os(macOS)
        .sheet(isPresented: $isShowGlobalStats, content: {
            GlobalStatsView(items: items)
                .environmentObject(settings)
        })
#endif
        .sheet(item: $routedItem, onDismiss: {
            routedResumeStart = nil
        }) { item in
            ShowItem(bankItem: binding(for: item), resumeStart: routedResumeStart)
                .presentationDetents([.height(400), .large])
        }
        .sheet(item: $interruptedLog) { log in
            InterruptedSessionReview(log: log) {
                clearInterruptedSessionPrompt()
            }
        }
        .alert("Session Interrupted", isPresented: $isShowingInterruptedPrompt, presenting: interruptedSession) { snapshot in
            Button("Keep") {
                clearInterruptedSessionPrompt()
            }
            Button("Adjust") {
                interruptedLog = matchingInterruptedLog(for: snapshot)
            }
            Button("Discard", role: .destructive) {
                discardInterruptedSession(snapshot)
            }
        } message: { snapshot in
            Text(TimerSessionCoordinator.interruptedMessage(for: snapshot))
        }
        .alert("Timer Already Running", isPresented: Binding(
            get: { runningSessionConflictItemName != nil },
            set: { if !$0 { runningSessionConflictItemName = nil } }
        )) {
            Button("OK", role: .cancel) {
                runningSessionConflictItemName = nil
            }
        } message: {
            Text(runningSessionConflictItemName ?? "")
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: items) {
            resolveRoutedItemIfNeeded()
            resumeRunningSessionIfNeeded()
            resolveInterruptedSessionIfNeeded()
        }
        .task {
            resumeRunningSessionIfNeeded()
            resolveInterruptedSessionIfNeeded()
        }
    }

    @ViewBuilder
    private func homeScaffold() -> some View {
        ZStack(alignment: .bottom) {
            pageContent()
        }
        #if os(macOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack{
                title()
                    .focusable(false)
                Spacer()
                analyticsButton()
                balance()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        #elseif os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                title()
                Spacer()
                analyticsButton()
                settingsButton()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.top, topBarExtraPaddingForPad)
            .padding(.bottom, 10)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(alignment: .center) {
                balanceBadge()
                Spacer()
                addButton()
            }
            .frame(minHeight: floatingButtonDiameter, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        #else
        .ignoresSafeArea()
        .toolbar{
            ToolbarItem(placement: .topBarLeading){
                title()
            }
            
            ToolbarItem(placement: .topBarTrailing){
                Button("Edit", systemImage: "ellipsis"){
                    isShowSetting = true
                }
                
            }
            ToolbarItem(placement: .bottomBar){
                HStack{
                    HStack(spacing: 3){
                        if(isShowBalanceTitle){
                            Text("Your Balance")
                                .font(.title3)
                        }else{
                            Image(systemName: settings.isEnableRate ? "banknote" : "clock")
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                                              
                        Text("\(balanceString)")
                            .font(.title3)
                    }
                    .animation(.default,value:isShowBalanceTitle)
                    .onTapGesture {
                        isShowBalanceTitle.toggle()
                    }
                    #if os(visionOS)
                    .padding()
                    #endif
                    .contentShape(.capsule)
                    .hoverEffect(.highlight)
                    
                    Spacer()
                    addButton()
                }
                
            }
        }
        #endif
    }

    @ViewBuilder
    func pageContent() -> some View {
        TabView(selection: $pageType) {
            ListView(pageType: .save)
                .tag(PageType.save)
#if os(macOS) || os(visionOS)
                .tabItem {Label("SaveTime", systemImage: "tray.and.arrow.down.fill")}
#endif
            
            ListView(pageType: .kill)
                .tag(PageType.kill)
#if os(macOS) || os(visionOS)
                .tabItem {Label("KillTime", systemImage: "tray.and.arrow.up.fill")}
#endif
        }
        .ignoresSafeArea(edges: .bottom)
#if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
#endif
    }
    
    @ViewBuilder
    func title() -> some View{
        Button(action: {
            withAnimation(.easeInOut, {
                pageType = (pageType == .save ? .kill : .save)
            })
        }, label: {
            HStack(alignment: .firstTextBaseline,spacing: 4){
                Text(pageType == PageType.save ? "SAVETIME":"KILLTIME")
                    .font(.title.monospaced())
                
                Text(pageType == PageType.save ? "\(saveMinString)":"\(killMinString)")
                    .font(.subheadline)
                
            }
            //                    .background(.thinMaterial)
        })
#if os(iOS)
        .buttonStyle(.plain)
#else
        .buttonStyle(.borderless)
#endif
        .foregroundStyle(mainColor)
        .animation(.default, value: pageType)
    }
    
    @ViewBuilder
    func balance() -> some View {
        VStack(alignment: .trailing, spacing: 0){
            Text("Your Balance")
                .font(.caption)
            
            HStack(spacing: 3){
                Image(systemName: settings.isEnableRate ? "banknote" : "clock")
                    .fontWeight(.medium)
                    .font(.caption)
                Text("\(balanceString)")
                    .font(.title3)
            }
            
        }
    }
    
    @ViewBuilder
    func addButton() -> some View{
        Button{
            HapticFeedback.tap()
            withAnimation(.default){
                isShowAdd = true
            }
        }label: {
            Image(systemName: "plus")
                .font(.title.weight(.bold))
        }
        .buttonStyle(CircularButtonStyle(color:mainColor.opacity(0.9), diameter: floatingButtonDiameter))
        .animation(.default, value: pageType)
        #if os(macOS)
        .padding(.trailing,25)
        .padding(.bottom,25)
        #elseif os(iOS)
        // iPhone uses a custom safe-area bar instead of the system toolbar.
        #else
        .padding(.bottom,25)
        #endif
    }

    @ViewBuilder
    func settingsButton() -> some View {
        Button {
            HapticFeedback.tap()
            isShowSetting = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .frame(width: 52, height: 52)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func analyticsButton() -> some View {
#if os(iOS) || os(macOS)
        Button {
            HapticFeedback.tap()
            isShowGlobalStats = true
        } label: {
            Image(systemName: "chart.bar.xaxis")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .frame(width: 52, height: 52)
        .contentShape(Rectangle())
#endif
    }

    @ViewBuilder
    func balanceBadge() -> some View {
        HStack(spacing: 6){
            if(isShowBalanceTitle){
                Text("Your Balance")
                    .font(.subheadline.weight(.medium))
            }else{
                Image(systemName: settings.isEnableRate ? "banknote" : "clock")
                    .font(.subheadline.weight(.medium))
            }

            Text(balanceBadgeString)
                .font(.title3.monospacedDigit())
        }
        .animation(.default,value:isShowBalanceTitle)
        .onTapGesture {
            isShowBalanceTitle.toggle()
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: balanceBadgeHeight, alignment: .center)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 0.8)
                }
        }
        .contentShape(Rectangle())
    }

    var mainColor:Color{
        settings.themeColor(isSave: pageType == .save)
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

    var balanceBadgeString:String{
        if settings.isEnableRate {
            return "$ \(String(format: "%.0f", items.balanceValue(useRate: true)))"
        } else {
            return String(format: "%.0f", items.balanceValue(useRate: false))
        }
    }

    private func binding(for item: BankItem) -> Binding<BankItem> {
        Binding(
            get: { item },
            set: { _ in }
        )
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "timebank",
              url.host == "item" else {
            return
        }

        guard let itemID = UUID(uuidString: url.lastPathComponent) else {
            return
        }

        switch TimerSessionCoordinator.deepLinkDecision(for: itemID) {
        case .openRequestedItem:
            if let resumeStart = resumableLiveActivityStart(for: itemID) {
                try? TimerSessionCoordinator.prepareResumeFromLiveActivity(
                    itemID: itemID,
                    start: resumeStart,
                    items: items,
                    modelContext: modelContext
                )
                clearInterruptedPromptUI()
                routedResumeStart = resumeStart
            } else {
                routedResumeStart = nil
            }
            routedItemID = itemID
            resolveRoutedItemIfNeeded()
        case .ignoreRunningItem:
            return
        case let .blockWhileRunning(runningItemID):
            runningSessionConflictItemName = TimerSessionCoordinator.runningSessionConflictMessage(
                for: runningItemID,
                items: items
            )
            return
        }
    }

    private func resolveRoutedItemIfNeeded() {
        guard let routedItemID else {
            return
        }

        guard let item = items.first(where: { $0.id == routedItemID }) else {
            return
        }

        pageType = item.isSave ? .save : .kill
        routedItem = item
    }

    private func resolveInterruptedSessionIfNeeded() {
        guard interruptedSession == nil,
              let snapshot = TimerSessionCoordinator.interruptedSessionForPrompt(items: items) else {
            return
        }

        interruptedSession = snapshot
        isShowingInterruptedPrompt = true
    }

    private func resumeRunningSessionIfNeeded() {
        guard routedItem == nil,
              interruptedSession == nil,
              let snapshot = TimerSessionCoordinator.currentSession(),
              snapshot.phase == .running,
              let resumeStart = resumableLiveActivityStart(for: snapshot.bankItemID),
              items.contains(where: { $0.id == snapshot.bankItemID }) else {
            return
        }

        routedResumeStart = resumeStart
        routedItemID = snapshot.bankItemID
        resolveRoutedItemIfNeeded()
    }

    private func matchingInterruptedLog(for snapshot: TimerSessionSnapshot) -> ItemLog? {
        TimerSessionCoordinator.matchingInterruptedLog(for: snapshot, items: items)
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
        clearInterruptedPromptUI()
    }

    private func clearInterruptedPromptUI() {
        interruptedSession = nil
        interruptedLog = nil
        isShowingInterruptedPrompt = false
    }

    private func resumableLiveActivityStart(for itemID: UUID) -> Date? {
#if canImport(ActivityKit) && !os(macOS)
        if let activityStart = Activity<TimerActivityAttributes>.activities.first(where: {
            $0.attributes.itemID == itemID.uuidString
        })?.attributes.start {
            return activityStart
        }
#endif

        if let snapshot = TimerSessionCoordinator.currentSession(),
           snapshot.bankItemID == itemID {
            return snapshot.start
        }

        return nil
    }
    
}

private struct InterruptedSessionReview: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let log: ItemLog
    let onComplete: () -> Void

    @State private var end: Date
    @State private var errorMessage: String?

    init(log: ItemLog, onComplete: @escaping () -> Void) {
        self.log = log
        self.onComplete = onComplete
        _end = State(initialValue: log.end)
    }

    private var minimumDurationMessage: String {
        String(
            format: String(localized: "The record must be at least %lld minute long."),
            locale: Locale.current,
            BankItem.minimumLogDurationMinutes
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Interrupted Session") {
                    DatePicker(
                        "Begin",
                        selection: .constant(log.begin),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .disabled(true)

                    DatePicker(
                        "End",
                        selection: $end,
                        in: log.begin.plus(1, component: .minute)...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(String(localized: "Adjust Time"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        do {
            guard let bankItem = log.bankItem else {
                errorMessage = String(localized: "Failed to save this log.")
                return
            }

            try bankItem.updateLog(log, begin: log.begin, end: end)
            try modelContext.save()
            onComplete()
            dismiss()
        } catch BankItem.LogRecordError.invalidRange {
            errorMessage = String(localized: "End time must be later than begin time.")
        } catch BankItem.LogRecordError.futureRange {
            errorMessage = String(localized: "The record cannot be in the future.")
        } catch BankItem.LogRecordError.durationTooShort {
            errorMessage = minimumDurationMessage
        } catch BankItem.LogRecordError.overlappingLog {
            errorMessage = String(localized: "This log overlaps an existing record.")
        } catch {
            errorMessage = String(localized: "Failed to save this log.")
        }
    }
}
