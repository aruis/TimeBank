//
//  ShowItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI

struct ShowItem: View {
    
    @Binding var bankItem:BankItem
    
    @State var inTimer = false
    
    var body: some View {
        NavigationStack{
            
            GeometryReader{
                let size  = $0.size
                let isLarge = size.height > 600
                VStack(alignment: .center,spacing: 0){
                    
                    TimerView(bankItem: $bankItem)
                    
                    Spacer()
                        .frame(height: isLarge ? 20 : 120 )
                                            
                    LogView(logs: $bankItem.logs )
                        .transition(.opacity)
                                        
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(bankItem.name)
            .ignoresSafeArea(edges:.bottom)
            
        }
    }
}

#Preview {
    ShowItem(bankItem: .constant(BankItem(name: "test")))
}

