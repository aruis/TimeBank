//
//  StepListView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI

struct LogView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var logs:[ItemLog]?
    
    var body: some View {
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                    Button(role: .destructive, action: {
                        modelContext.delete(item)
                    })  {
                        Image(systemName: "trash")
                    }

                })
                .contextMenu{
                    Button(role:.destructive){
                        modelContext.delete(item)
                    }label: {
                        Label("Delete", systemImage:  "trash")
                    }
                }
                .transition(.slide)
                
            }
        }
        .animation(.default,value: logs)

    }
    
    var sortedLog : [ItemLog] {
        if let logs {
            return logs.sorted{ $0.begin > $1.begin }
        }else{
            return []
        }
    }
}

#Preview {
    LogView(logs:.constant( [
        ItemLog(bankItem: BankItem(), begin: Date(),end: Date())
    ]))
}
