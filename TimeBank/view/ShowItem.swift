//
//  ShowItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI

struct ShowItem: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Binding var bankItem:BankItem
    
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @State private var lastBackgroundTime: Date?
    
    @State private var start:Date?
    
    @State private var showTip = false
    
    
    var body: some View {
        NavigationStack{
            
            GeometryReader{
                let size  = $0.size
                let isLarge = size.height > 600
                VStack(alignment: .center,spacing: 0){
                    
                    circleView()
                    Spacer()
                        .frame(height: isLarge ? 25 : 130 )
                    
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
                            Color.orange
                                .blur(radius: 4)
                                .opacity(0.85)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                        
                        )
                        .padding(.bottom,40)
                }
            }
            .navigationTitle(bankItem.name)
            .ignoresSafeArea(edges:.bottom)
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if let start {
                    let backgroundDuration = Date().timeIntervalSince(start)
                    timeRemaining = Int(backgroundDuration)
                }
            }
            #endif
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if let start {
                    let backgroundDuration = Date().timeIntervalSince(start)
                    timeRemaining = Int(backgroundDuration)
                }
            }
            .frame(width: 450,height: 650)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Close")
                    }
                })
            })
            #endif
            
            
        }
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
                } else {
                    Text( "\(bankItem.saveMin) MIN")
                        .foregroundStyle(Color.white)
                        .font(.largeTitle)
                        .fontWeight(.regular)
                        .shadow(radius: 3)
                    //                                    .opacity(inTimer ? 0 : 1)
                        .transition(.moveAndFadeBottom)
                    //                                    .transition(.move(edge: .bottom))
                    //                                    .animation(.easeInOut, value: inTimer)
                    
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
                    Text("\(item.saveMin) MIN")
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                    Button(role: .destructive, action: {
                        bankItem.logs?.removeAll(where:{ $0 == item})
                        modelContext.delete(item)
                    })  {
                        Image(systemName: "trash")
                    }
                    
                })
                .contextMenu{
                    Button(role:.destructive){
                        bankItem.logs?.removeAll(where:{ $0 == item})
                        modelContext.delete(item)
                    }label: {
                        Label("Delete", systemImage:  "trash")
                    }
                }
                
                
            }
        }
        .animation(.default,value: bankItem.logs)
        
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
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        
        withAnimation{
            isTimerRunning = true
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.timeRemaining += 1
        }
        
        
        if bankItem.logs == nil{
            bankItem.logs = []
        }
        
        start = Date()
    }
    
    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
    }
    
    private func resetTimer() {
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
            
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            
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
