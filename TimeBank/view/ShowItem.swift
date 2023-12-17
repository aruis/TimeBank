//
//  ShowItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI

struct ShowItem: View {
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var bankItem:BankItem
    
    
    
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @State private var lastBackgroundTime: Date?
    
    @State private var start:Date?

    
    var body: some View {
        NavigationStack{
            
            GeometryReader{
                let size  = $0.size
                let isLarge = size.height > 600
                VStack(alignment: .center,spacing: 0){
                    
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
                    
                    Spacer()
                        .frame(height: isLarge ? 25 : 130 )                        
                                            
                    LogView(logs: $bankItem.logs )
                        .transition(.opacity)
                                        
                }
                #if os(macOS)
                .padding(.top,30)
                #endif
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(bankItem.name)
            .ignoresSafeArea(edges:.bottom)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                lastBackgroundTime = Date()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if let lastBackgroundTime = lastBackgroundTime {
                    let backgroundDuration = Date().timeIntervalSince(lastBackgroundTime)
                    timeRemaining += Int(backgroundDuration)
                }
            }
            #if os(macOS)
            .frame(width: 450,height: 650)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Cancel")
                    }
                })
            })
            #endif

            
        }
    }
    
    private func startTimer() {
        
        
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
        
        if let start {
            let now = Date()
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

    
    var mainColor:Color{
        if bankItem.isSave {
            return Color.red
        }else{
            return Color.green
        }
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
