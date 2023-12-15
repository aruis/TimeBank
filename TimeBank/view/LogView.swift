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
                    
                    VStack(alignment: .leading){
                        Text(item.begin.text())
                        if let end = item.end{
                            Text("\(end.text())")
                        } else {
                            Text("-")
                        }
                    }
                    .font(.caption.monospacedDigit())
                                                            
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false, content: {
                    Button(role: .destructive, action: {
                        DispatchQueue.main.async {
                            modelContext.delete(item)
                            do {
                                try modelContext.save()
                            } catch{
                                print(error)
                            }
                        }

                        
                        
                    })  {
                        Image(systemName: "trash")
                    }

                })
                .id(item.id)
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
        ItemLog(bankItem: BankItem(), begin: Date())
    ]))
}
