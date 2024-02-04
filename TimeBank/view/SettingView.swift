//
//  SettingView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/1/25.
//

import SwiftUI
import UserNotifications

struct SettingView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var settings: AppSetting
    
    @State var text:String = ""
    @State var showingAlert = false
    
    @FocusState private var sliderFocused: Bool
    
    let keyStore = NSUbiquitousKeyValueStore.default
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle(isOn: $settings.isTimerEnabled) {
                    Text("Enable Timer Notification")
                }
                .onChange(of: settings.isTimerEnabled){
                    if settings.isTimerEnabled{
                        
                        Task {
                            let result = await settings.requestNotificationPermission()
                            switch result {
                            case .success(let granted):
                                if !granted {
                                    // 用户拒绝授权，可以在这里更新 UI 或状态
                                    showingAlert = true
                                }
                            case .failure(let error):
                                // 处理错误
                                print(error)
                                showingAlert = true
                            }
                        }
                        
                    }
                    
                }
                
                if settings.isTimerEnabled {
                    
                    HStack{
                        Text("Timer Duration")
                        Spacer()
                        Text("\(Int( settings.timerDuration)) Min")
                            .fontWeight(.bold)
                        
                    }
                    
                    Slider(
                        value: $settings.timerDuration,
                        in: 0...60,
                        step: 5
                    ) {
                        
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("60")
                    }
                    .focused($sliderFocused)
                    .contentShape(.capsule)
                    .overlay{
                        RoundedRectangle(cornerRadius: 5) // 你可以根据需要调整圆角大小
                            .stroke(sliderFocused ? Color.green : Color.clear, lineWidth: 2)
                    }
                    
                }
                
                
            }
            .alert("You need to manually enable notification permissions", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { 
                    
                }
            }
#if os(macOS)
            .padding()
            .frame(minWidth: 300)
#endif
            .toolbar{
#if os(macOS)
                ToolbarItem(placement: .cancellationAction, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Close")
                    }
                })
#elseif !os(watchOS)
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Close")
                    }
                })
#endif
            }
            .navigationTitle("Setting")
#if os(iOS)
            .sensoryFeedback(.decrease, trigger: settings.timerDuration)
#endif
            
        }
        
    }
}

#Preview {
    
    SettingView()
        .environmentObject(AppSetting())
    
}
