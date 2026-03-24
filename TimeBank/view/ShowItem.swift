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

    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = false

    @State private var start:Date?

    @State private var selectedLog: ItemLog?
    @State private var itemToDelete: ItemLog?

    @State private var showConfirmDelete = false
    @State private var showTip = false
    @State private var pendingNotificationID: String?

#if canImport(ActivityKit) && !os(macOS)
    @State private var activity:Activity<TimerActivityAttributes>?
#endif

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

                    Button("Pin", systemImage: bankItem.isPin ? "mappin.slash.circle" :  "mappin.circle"){
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
        .animation(.default,value: bankItem.logs)
        .sheet(item: $selectedLog) {log in
            EditLogItem(log: log)
                .presentationDetents([.medium, .large])
        }
        .alert("Delete Item", isPresented: $showConfirmDelete, presenting: itemToDelete) { item in
            Button("Delete", role: .destructive) {
                bankItem.logs?.removeAll(where: { $0 == item })
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
        HapticFeedback.tap()

        withAnimation{
            isTimerRunning = true
        }

        timeRemaining = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation(.default, {
                self.timeRemaining += 1
            })
            persistTimerSession(at: Date())

        }


        if bankItem.logs == nil{
            bankItem.logs = []
        }

        start = Date()
        persistTimerSession(at: start!)

#if canImport(ActivityKit) && !os(macOS)
        Task {
            // 启动新的之前关闭残留的
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil,dismissalPolicy: .immediate)
            }

            // 启动 ActivityKit
            let activityAttributes = TimerActivityAttributes(
                itemID: bankItem.id.uuidString,
                name: bankItem.name,
                start: start!
            )
            let initialContentState = TimerActivityAttributes.ContentState(
                recordedSeconds: timeRemaining,
                sessionState: .running
            )

            do {
                activity = try Activity.request(
                    attributes: activityAttributes,
                    content: .init(state: initialContentState, staleDate: nil),
                    pushType: nil
                )

                print("Live Activity started with ID: \(String(describing: activity?.id))")
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
#endif
        if settings.isTimerEnabled && settings.timerDuration > 0 {
            let notificationID = "\(notificationIDPrefix)-\(UUID().uuidString)"
            pendingNotificationID = notificationID
            UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
                guard isAuthorizedNotificationStatus(notificationSettings.authorizationStatus) else {
                    DispatchQueue.main.async {
                        pendingNotificationID = nil
                    }
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = bankItem.isSave ? NSLocalizedString("SaveTime Complete", comment: ""):NSLocalizedString("KillTime Complete", comment: "")

                let actionWordKey = bankItem.isSave ? "Invested" : "Spent"
                let actionWord = NSLocalizedString(actionWordKey, comment: "Action word based on bank item saving or spending")
                content.subtitle = String(format: NSLocalizedString("YouHaveJustInvested", comment: ""), String(Int(settings.timerDuration)), "[\(bankItem.name)]", actionWord)
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: settings.timerDuration * 60, repeats: false)
                let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func resetTimer() {
        TimerSessionCoordinator.clearSession()

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

        if let start {
            let now = Date()

            let stopResult = bankItem.stopTimer(start: start, end: now)

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

        TimerSessionCoordinator.persistRunningSession(
            bankItemID: bankItem.id,
            start: start,
            verifiedAt: date
        )
    }

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
