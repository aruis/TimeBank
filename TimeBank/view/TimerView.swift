//
//  TimerView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/15.
//

import SwiftUI

struct TimerView: View {
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    
    @Binding var bankItem:BankItem
    
    @State private var thisLog:ItemLog?
    @State private var start:Date?

    var body: some View {
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

        
//        VStack {
//            Text("\(formatTime(seconds: timeRemaining))")
//                .font(.largeTitle.monospacedDigit())
//
//            HStack {
//                Button(action: startTimer) {
//                    Text("启动")
//                }
//                .disabled(isTimerRunning)
//
//                Button(action: pauseTimer) {
//                    Text("暂停")
//                }
//                .disabled(!isTimerRunning)
//
//                Button(action: resetTimer) {
//                    Text("结束")
//                }
//            }
//        }
    }

    private func startTimer() {
        
        
        withAnimation{
            isTimerRunning = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timeRemaining += 1
            }

            
            if bankItem.logs == nil{
                bankItem.logs = []
            }

            start = Date()
            
        }
        


    }

    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
    }

    private func resetTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timeRemaining = 0
        
        if let start {
            thisLog = ItemLog(bankItem: bankItem, begin: start)
            thisLog?.end = Date()
        }
        
        
//        if let thisLog {
//            thisLog.end = Date()
//            if var logs = bankItem.logs{
//                logs.append(thisLog)
//                print("add")
//            }
//        }
        
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
    TimerView(bankItem: .constant(BankItem()))
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
