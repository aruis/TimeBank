//
//  NewBankItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import SwiftUI

struct NewBankItem: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.dismiss) var dismiss
    
    
    @State var name:String = ""
    
    var body: some View {

        VStack{
            TextField("Name", text: $name)
            Button{
                let newItem = BankItem(name:name,sort: 0)
                newItem.lastTouch = Date()
                modelContext.insert(newItem)
                dismiss()
            }label: {
                Text("add")
            }
        }
        
        
    }
}

#Preview {
    NewBankItem()
}
