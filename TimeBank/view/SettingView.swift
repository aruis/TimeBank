//
//  SettingView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/1/25.
//

import SwiftUI

struct SettingView: View {
    
    @State var text:String = ""
    
    var body: some View {
        List{
            Section{
                Text("test")
//                DatePicker("", selection: <#T##Binding<Date>#>)
            }
        }
        .navigationTitle("Setting")
    }
}

#Preview {
    NavigationStack{
        SettingView()
    }
    
}
