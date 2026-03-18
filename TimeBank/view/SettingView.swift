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

                Section("SaveTime / KillTime 颜色") {
                    HStack(spacing: 12) {
                        colorThemeOption(
                            saveColor: .red,
                            killColor: .green,
                            isSelected: !settings.swapThemeColors
                        ) {
                            settings.swapThemeColors = false
                        }

                        colorThemeOption(
                            saveColor: .green,
                            killColor: .red,
                            isSelected: settings.swapThemeColors
                        ) {
                            settings.swapThemeColors = true
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
            .frame(width: 450,height:  360,alignment: .topLeading)
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

    @ViewBuilder
    func colorThemeOption(
        saveColor: Color,
        killColor: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(saveColor.gradient)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(killColor.gradient)
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 0.8)
                    }
            }
            .saturation(isSelected ? 1 : 0.35)
            .opacity(isSelected ? 1 : 0.72)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    
    SettingView()
        .environmentObject(AppSetting())
    
}
