//
//  ShowItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI
#if canImport(ActivityKit) && !os(macOS)
import ActivityKit
#endif
import UserNotifications

struct ShowItem: View {
    @EnvironmentObject var settings: AppSetting

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Binding var bankItem:BankItem
    let resumeStart: Date?

    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = false

    @State private var start:Date?

    @State private var selectedLog: ItemLog?
    @State private var itemToDelete: ItemLog?
    @State private var showCreateLog = false

    @State private var showConfirmDelete = false
    @State private var showTip = false
    @State private var pendingNotificationID: String?
    @State private var hasResumedFromExternalActivity = false

#if canImport(ActivityKit) && !os(macOS)
    @State private var activity:Activity<TimerActivityAttributes>?
#endif

    init(bankItem: Binding<BankItem>, resumeStart: Date? = nil) {
        self._bankItem = bankItem
        self.resumeStart = resumeStart
    }

    var body: some View {
        NavigationStack{

            GeometryReader{
                let size  = $0.size
                let isLarge = size.height > 600
                VStack(alignment: .center,spacing: 10){

                    circleView()
#if os(iOS)
                    Spacer()
                        .frame(height: isLarge ? 15 : 110 )
#endif

                    logView()
                        .transition(.opacity)

                }
#if os(macOS)
                .padding(.top,30)
#endif
                .frame(maxWidth: .infinity)
            }
            .overlay(alignment: .bottom){
                if showTip {
                    Text("Execute in less than 1 minute, no record will be made.")
                        .opacity(0.9)
                        .font(.callout)
                        .padding(.horizontal,15)
                        .padding(.vertical,8)
                        .background(
                            Material.ultraThin,in: RoundedRectangle(cornerRadius:  14)
                        )
                        .padding(.bottom,40)
                }
            }
            .navigationTitle(bankItem.name)
            .ignoresSafeArea(edges:.bottom)
            .onChange(of: scenePhase, {
                switch scenePhase {
                case .active:
                    if isTimerRunning, let start {
                        let now = Date()
                        let backgroundDuration = now.timeIntervalSince(start)
                        timeRemaining = Int(backgroundDuration)
                        persistTimerSession(at: now)
                    }
                case .background:
                    persistTimerSession(at: Date())
                default:
                    break
                }
            })
#if os(macOS) || os(visionOS)
            .frame(minWidth: 420,minHeight:  350)
#endif
            .toolbar(content: {
#if os(macOS) || os(visionOS)
                ToolbarItem(placement: .cancellationAction, content: {

                    Button{
                        dismiss()
                    }label: {
                        Text("Close")
                    }
                    .opacity(isTimerRunning ? 0 : 1)
                })
#endif
                ToolbarItem(placement: .destructiveAction, content: {

                    Button(bankItem.isPin ? "Unpin" : "Pin", systemImage: bankItem.isPin ? "mappin.slash.circle" :  "mappin.circle"){
                        bankItem.isPin.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .contentShape(.circle)
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                    .padding(10)

                })
            })
        }
        .interactiveDismissDisabled(isTimerRunning)
        .task {
            resumeTimerIfNeeded()
        }
    }

    @ViewBuilder
    func circleView() -> some View{
        Circle()
            .frame(width: 200 ,height: 200)
            .foregroundColor(mainColor.opacity(0.85))
            .overlay(content: {
                if isTimerRunning {
                    Text(timeRemaining.formatTime())
                        .font(.largeTitle.monospacedDigit())
                        .fontWeight(.regular)
                        .foregroundStyle(Color.white)
                        .transition(.moveAndFadeTop)
                        .contentTransition(.numericText(value: Double( timeRemaining)))
                    //                        .﻿contentTransition(.numericText(value:timeRemaining))
                } else {
                    Text(settings.isEnableRate ? "$ \(bankItem.exchangeString)" : "\(bankItem.saveMin) MIN")
                        .foregroundStyle(Color.white)
                        .font(.largeTitle)
                        .fontWeight(.regular)
                        .shadow(radius: 3)
                        .transition(.moveAndFadeBottom)
                }
            })
            .overlay{
                if !isTimerRunning {
                    Button(action:startTimer) {
                        Image(systemName:  "play.fill")
                            .foregroundStyle(Color.white)
                            .font(.largeTitle)
                            .shadow(radius: 3)
                    }
                    .padding(.top,120)
                }

            }

            .overlay{
                if isTimerRunning {
                    Button(action:resetTimer) {
                        Image(systemName: "stop.fill" )
                            .foregroundStyle(Color.white)
                            .font(.largeTitle)
                            .shadow(radius: 3)
                    }
                    .padding(.top,120)
                }
            }

    }

    @ViewBuilder
    func logView() -> some View{
        List{
            Section {
                ForEach(sortedLog){ item in
                    HStack{
                        Text(settings.isEnableRate ? "\(item.saveMin) MIN / $\(item.exchangeString)" : "\(item.saveMin) MIN")
                            .font(.title3)
                            .fontWeight(.medium)

                        Spacer()

                        VStack(alignment: .trailing){
                            Text(item.begin.dayString())
                                .opacity(0.9)
                            HStack(spacing:1){
                                Text(item.begin.timeString())
                                Text("~")
                                Text(item.end.timeString())
                            }
                            .opacity(0.9)

                        }
                        .font(.caption.monospacedDigit())

                    }
                    .id(item.id)
                    .transition(.slide)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive, action: {
                            confirmDelete(item: item)
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                    .swipeActions(edge: .leading){
                        Button(action: {
                            selectedLog = item
                        }) {
                            Image(systemName:"clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                        .tint(.blue)

                    }
                    .contextMenu{
                        Button(){
                            selectedLog = item
                        }label: {
                            Label("Edit", systemImage:  "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                        Button(role:.destructive){
                            confirmDelete(item: item)
                        }label: {
                            Label("Delete", systemImage:  "trash")
                        }
                    }
                }
            }
        header: {
                HStack {
                    Spacer()
                    Button {
                        showCreateLog = true
                    } label: {
                        Label("Add Log", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .animation(.default,value: bankItem.logs)
        .sheet(isPresented: $showCreateLog) {
            EditLogItem(bankItem: bankItem)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedLog) {log in
            EditLogItem(log: log)
                .presentationDetents([.medium, .large])
        }
        .alert("Delete Item", isPresented: $showConfirmDelete, presenting: itemToDelete) { item in
            Button("Delete", role: .destructive) {
                bankItem.removeLog(item)
                modelContext.delete(item)
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: { _ in
            Text("Are you sure you want to delete this item?")
        }

    }

    var sortedLog : [ItemLog] {
        if let  logs = bankItem.logs{
            return logs.sorted{ $0.begin > $1.begin }
        }else{
            return []
        }
    }

    var mainColor:Color{
        settings.themeColor(isSave: bankItem.isSave)
    }

    private var notificationIDPrefix: String {
        "timer-\(bankItem.id.uuidString)"
    }

    private var timerSessionController: TimerSessionController {
        TimerSessionController(bankItemID: bankItem.id)
    }

    private func isAuthorizedNotificationStatus(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional:
            return true
        #if !os(macOS)
        case .ephemeral:
            return true
        #endif
        default:
            return false
        }
    }

    private func startTimer() {
        startTimer(from: nil)
    }

    private func startTimer(from resumedStart: Date?) {
        HapticFeedback.tap()

        withAnimation{
            isTimerRunning = true
        }

        let sessionStart = resumedStart ?? Date()
        timeRemaining = max(Int(Date().timeIntervalSince(sessionStart)), 0)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation(.default, {
                self.timeRemaining += 1
            })
            persistTimerSession(at: Date())

        }


        if bankItem.logs == nil{
            bankItem.logs = []
        }

        start = sessionStart
        persistTimerSession(at: Date())

#if canImport(ActivityKit) && !os(macOS)
        Task {
            await startOrResumeLiveActivity(start: sessionStart, endingExistingActivities: resumedStart == nil)
        }
#endif
        if settings.isTimerEnabled && settings.timerDuration > 0 {
            let notificationID = "\(notificationIDPrefix)-\(UUID().uuidString)"
            pendingNotificationID = notificationID
            let remainingSeconds = max((settings.timerDuration * 60) - Double(timeRemaining), 0)
            guard remainingSeconds > 0 else {
                pendingNotificationID = nil
                return
            }
            UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
                guard isAuthorizedNotificationStatus(notificationSettings.authorizationStatus) else {
                    DispatchQueue.main.async {
                        pendingNotificationID = nil
                    }
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = bankItem.isSave ? String(localized: "SaveTime Complete") : String(localized: "KillTime Complete")

                let actionWord = bankItem.isSave ? String(localized: "Invested") : String(localized: "Spent")
                content.subtitle = String(
                    format: String(localized: "YouHaveJustInvested"),
                    locale: Locale.current,
                    String(Int(settings.timerDuration)),
                    "[\(bankItem.name)]",
                    actionWord
                )
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingSeconds, repeats: false)
                let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func resetTimer() {
        if let pendingNotificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [pendingNotificationID])
            self.pendingNotificationID = nil
        }

        withAnimation{
            isTimerRunning = false
        }

        timer?.invalidate()
        timer = nil
        timeRemaining = 0

#if canImport(ActivityKit) && !os(macOS)
        Task {
            if let activity{
                await activity.end(nil,dismissalPolicy: .immediate)
            }
        }
#endif

        if let stopResult = timerSessionController.stop(item: bankItem, start: start, end: Date()) {
            if !stopResult.shouldRecord {
                print("时间不足1分钟")
                HapticFeedback.warning()

                withAnimation{
                    showTip = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    withAnimation{
                        showTip = false
                    }
                })

                self.start = nil

                return
            }

            HapticFeedback.success()
        }

        self.start = nil

    }

    private func confirmDelete(item: ItemLog) {
        itemToDelete = item
        showConfirmDelete = true
    }

    private func persistTimerSession(at date: Date) {
        guard let start, isTimerRunning else {
            return
        }

        timerSessionController.persistRunning(
            start: start,
            verifiedAt: date
        )
    }

    private func resumeTimerIfNeeded() {
        guard !hasResumedFromExternalActivity,
              !isTimerRunning,
              let resumeStart = resumeStartCandidate() else {
            return
        }

        hasResumedFromExternalActivity = true
        startTimer(from: resumeStart)
    }

    private func resumeStartCandidate() -> Date? {
        timerSessionController.resumeStartCandidate(explicitStart: resumeStart)
    }

#if canImport(ActivityKit) && !os(macOS)
    private func startOrResumeLiveActivity(start: Date, endingExistingActivities: Bool) async {
        let runningState = TimerActivityAttributes.ContentState(
            recordedSeconds: timeRemaining,
            sessionState: .running
        )

        if let existing = Activity<TimerActivityAttributes>.activities.first(where: {
            $0.attributes.itemID == bankItem.id.uuidString
        }) {
            await existing.update(.init(state: runningState, staleDate: nil))
            activity = existing
            return
        }

        if endingExistingActivities {
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        let activityAttributes = TimerActivityAttributes(
            itemID: bankItem.id.uuidString,
            name: bankItem.name,
            start: start
        )

        do {
            activity = try Activity.request(
                attributes: activityAttributes,
                content: .init(state: runningState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
#endif

}

#Preview {
    ShowItem(bankItem: .constant(BankItem(name: "test")))
        .environmentObject(AppSetting())
        .modelContainer(for: [BankItem.self, ItemLog.self], inMemory: true)
}

extension AnyTransition {
    static var moveAndFadeTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal:  .move(edge: .bottom).combined(with: .opacity)
        )
    }

    static var moveAndFadeBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:  .move(edge: .top).combined(with: .opacity)
        )
    }
}
