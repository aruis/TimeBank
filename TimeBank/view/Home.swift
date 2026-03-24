//
//  Home.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI
import SwiftData
import OSLog

struct Home: View {
        
    @EnvironmentObject var settings: AppSetting
    @Environment(\.modelContext) private var modelContext
    
    @State private var pageType = PageType.save
    @State private var isShowAdd = false
    @State private var isShowSetting = false
    @State private var isShowBalanceTitle = false
    @State private var routedItemID: UUID?
    @State private var routedItem: BankItem?
    @State private var interruptedSession: TimerSessionSnapshot?
    @State private var interruptedLog: ItemLog?
    @State private var isShowingInterruptedPrompt = false
    @State private var runningSessionConflictItemName: String?
    
    @Query private var items: [BankItem]
    
    private let floatingButtonDiameter: CGFloat = 58
    private let balanceBadgeHeight: CGFloat = 42
    
    var body: some View {
        ZStack(alignment: .bottom) {
            pageContent()
        }
        #if os(macOS)
        .padding(.top,60)
        .overlay(alignment: .top, content: {
            HStack{
                title()
                    .focusable(false)
                Spacer()
                balance()
            }
            .padding()
//            .padding(.top,20)
        })
        #elseif os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                title()
                Spacer()
                settingsButton()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
        .sheet(item: $routedItem) { item in
            ShowItem(bankItem: binding(for: item))
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
            Text(interruptedMessage(for: snapshot))
        }
        .alert("Timer Already Running", isPresented: Binding(
            get: { runningSessionConflictItemName != nil },
            set: { if !$0 { runningSessionConflictItemName = nil } }
        )) {
            Button("OK", role: .cancel) {
                runningSessionConflictItemName = nil
            }
        } message: {
            Text(runningSessionConflictMessage)
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: items) {
            resolveRoutedItemIfNeeded()
            resolveInterruptedSessionIfNeeded()
        }
        .task {
            resolveInterruptedSessionIfNeeded()
        }

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

        if let runningSession = TimerSessionStore.load(), runningSession.phase == .running {
            if runningSession.bankItemID == itemID {
                return
            }

            if let item = items.first(where: { $0.id == runningSession.bankItemID }) {
                runningSessionConflictItemName = item.name
            } else {
                runningSessionConflictItemName = "another item"
            }
            return
        }

        routedItemID = itemID
        resolveRoutedItemIfNeeded()
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
              let snapshot = TimerSessionStore.load(),
              snapshot.phase == .interrupted,
              matchingInterruptedLog(for: snapshot) != nil else {
            return
        }

        interruptedSession = snapshot
        isShowingInterruptedPrompt = true
    }

    private func matchingInterruptedLog(for snapshot: TimerSessionSnapshot) -> ItemLog? {
        guard let item = items.first(where: { $0.id == snapshot.bankItemID }),
              let logs = item.logs else {
            return nil
        }

        return logs.first {
            abs($0.begin.timeIntervalSince(snapshot.start)) < 1 &&
            abs($0.end.timeIntervalSince(snapshot.lastVerifiedAt)) < 1
        }
    }

    private func discardInterruptedSession(_ snapshot: TimerSessionSnapshot) {
        if let log = matchingInterruptedLog(for: snapshot) {
            log.bankItem?.logs?.removeAll(where: { $0.id == log.id })
            modelContext.delete(log)
            try? modelContext.save()
        }

        clearInterruptedSessionPrompt()
    }

    private func clearInterruptedSessionPrompt() {
        TimerSessionStore.clear()
        interruptedSession = nil
        interruptedLog = nil
        isShowingInterruptedPrompt = false
    }

    private func interruptedMessage(for snapshot: TimerSessionSnapshot) -> String {
        let recordedMinutes = max(snapshot.recordedSeconds / 60, 1)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        return "Recorded \(recordedMinutes) min until \(formatter.string(from: snapshot.lastVerifiedAt)). You can keep it, adjust it, or discard it."
    }

    private var runningSessionConflictMessage: String {
        guard let runningSessionConflictItemName else {
            return ""
        }

        return "A timer is already running for \(runningSessionConflictItemName). Stop or resolve it before opening a different item from the widget."
    }
    
}

private struct InterruptedSessionReview: View {
    @Environment(\.dismiss) private var dismiss

    let log: ItemLog
    let onComplete: () -> Void

    @State private var end: Date

    init(log: ItemLog, onComplete: @escaping () -> Void) {
        self.log = log
        self.onComplete = onComplete
        _end = State(initialValue: log.end)
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
            }
            .navigationTitle("Adjust Time")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        log.end = end
                        log.saveMin = max(log.begin.elapsedMin(end), 0)
                        onComplete()
                        dismiss()
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
}
