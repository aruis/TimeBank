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
                Section ("Scheduled Reminder"){
                    Toggle(isOn: $settings.isTimerEnabled) {
                        Text("Enable Timer Notification🍅")
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
                Section ("Rate Mode"){
                    Toggle(isOn: $settings.isEnableRate) {
                        Text("Enabling the Rate Mode will convert time based on the specified ratio.")
                    }
                }

                Section("My Apps"){
                    HStack(spacing: 10){
                        Image("booktime_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading){
                            Text("BookTime")
                                .font(.title3)
                            Text("Reading timing buddy")
                                .font(.caption)
                        }

                        Spacer()

                        Link(destination: URL(string: "https://apps.apple.com/us/app/booktime-%E6%82%A8%E7%9A%84%E9%98%85%E8%AF%BB%E8%AE%A1%E6%97%B6%E4%BC%B4%E4%BE%A3/id1600654269")!,label: {
                            Image(systemName: "arrow.right.circle.fill")
                        })

                    }
                }

                Text("苏ICP备2024057896号-3A")
                    .font(.callout)
            }
            .alert("You need to manually enable notification permissions", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    
                }
            }
#if os(macOS)
            .frame(width: 420,height:  260,alignment: .topLeading)
            .padding()
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
            #if !os(visionOS)
            .sensoryFeedback(.selection, trigger: settings.timerDuration)
#endif
            
        }
        
    }
}

#Preview {
    
    SettingView()
        .environmentObject(AppSetting())
    
}
