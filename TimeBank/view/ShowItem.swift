//
//  ShowItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI
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
    @State private var lastBackgroundTime: Date?

    @State private var start:Date?

    @State private var selectedLog: ItemLog?
    @State private var itemToDelete: ItemLog?

    @State private var showConfirmDelete = false
    @State private var showTip = false


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
                    if let start {
                        let backgroundDuration = Date().timeIntervalSince(start)
                        timeRemaining = Int(backgroundDuration)
                    }
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
#if !os(visionOS)
            .sensoryFeedback(.decrease, trigger: isTimerRunning)
#endif


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
                    Text("\(formatTime(seconds: timeRemaining))")
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
                .alert(isPresented: $showConfirmDelete) {
                    Alert(
                        title: Text("Delete Item"),
                        message: Text("Are you sure you want to delete this item?"),
                        primaryButton: .destructive(Text("Delete")) {
                            if let itemToDelete = itemToDelete {
                                bankItem.logs?.removeAll(where: { $0 == itemToDelete })
                                modelContext.delete(itemToDelete)
                            }
                        },
                        secondaryButton: .cancel()
                    )
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

    }

    var sortedLog : [ItemLog] {
        if let  logs = bankItem.logs{
            return logs.sorted{ $0.begin > $1.begin }
        }else{
            return []
        }
    }

    var mainColor:Color{
        if bankItem.isSave {
            return Color.red
        }else{
            return Color.green
        }
    }

    private func startTimer() {
        withAnimation{
            isTimerRunning = true
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation(.default, {
                self.timeRemaining += 1
            })

        }


        if bankItem.logs == nil{
            bankItem.logs = []
        }

        start = Date()

        if settings.isTimerEnabled && settings.timerDuration > 0 {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {

                    let content = UNMutableNotificationContent()
                    content.title = bankItem.isSave ? NSLocalizedString("SaveTime Complete", comment: ""):NSLocalizedString("KillTime Complete", comment: "")
                    //                    content.subtitle = String(format: NSLocalizedString("YouHaveJustInvested", comment: ""), arguments: [String(Int( settings.timerDuration)), bankItem.name])


                    let actionWordKey = bankItem.isSave ? "Invested" : "Spent"
                    let actionWord = NSLocalizedString(actionWordKey, comment: "Action word based on bank item saving or spending")
                    content.subtitle = String(format: NSLocalizedString("YouHaveJustInvested", comment: ""), String(Int(settings.timerDuration)), "[\(bankItem.name)]", actionWord)
                    content.sound = UNNotificationSound.default

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: settings.timerDuration * 60, repeats: false)

                    let request = UNNotificationRequest(identifier: "meetingReminder", content: content, trigger: trigger)

                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
    }

    private func resetTimer() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        withAnimation{
            isTimerRunning = false
        }

        timer?.invalidate()
        timeRemaining = 0
        lastBackgroundTime = nil

        if let start {
            let now = Date()

            if start.elapsedMin(now) < 1 {
                print("时间不足1分钟")

#if os(iOS)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
#endif

                withAnimation{
                    showTip = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    withAnimation{
                        showTip = false
                    }
                })

                return
            }

            bankItem.lastTouch = now
            let thisLog = ItemLog(bankItem: bankItem, begin: start ,end: now)

            if var logs = bankItem.logs{
                logs.append(thisLog)
            }
        }

    }

    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func confirmDelete(item: ItemLog) {
        itemToDelete = item
        showConfirmDelete = true
    }

}

#Preview {
    ShowItem(bankItem: .constant(BankItem(name: "test")))
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
