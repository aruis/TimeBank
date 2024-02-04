//
//  SettingView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/1/25.
//

import SwiftUI


struct SettingView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var settings: AppSetting
    
    @State var text:String = ""
    
    @FocusState private var sliderFocused: Bool
    
    let keyStore = NSUbiquitousKeyValueStore.default
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle(isOn: $settings.isTimerEnabled) {
                    Text("Enable Timer")
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
                        Text("Timer Duration")
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
            #if !os(watchOS)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button("Close"){
                        dismiss()
                    }
                }
            }
            #endif
            
            .navigationTitle("Setting")
        }
    }
}

#Preview {
    
    SettingView()
        .environmentObject(AppSetting())
    
}
