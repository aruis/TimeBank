//
//  ListView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI
import SwiftData

struct ListView: View {
    
    var pageType:PageType
    
    @Environment(AppData.self) private var appData: AppData
    
    @Query private var items: [BankItem]
    
    @ViewBuilder
    func itemInList(_ item:BankItem) -> some View {
        
        
        VStack(spacing:0){
            Spacer()
                .frame(height: 70)
            
            Text(item.name)
                .font(.largeTitle)
            
            Spacer()
                .frame(height: 10)
            
            Text("\(item.saveMin) MIN")
                .font(.callout)
                        
            Spacer()
            
            VStack{
                Text("Last Touch:")
                if let lastTouch = item.lastTouch {
                    Text(lastTouch,style: .date)
                } else{
                    Text("-")
                }
            }
            .font(.caption)

            Spacer()
                .frame(height: 10)
            
            VStack{
                Text("Create Time:")
                Text(item.createTime,style: .date)
            }
            .font(.caption)

                                                    
        }
        .padding()
        .frame(maxWidth:.infinity,minHeight:  280)
        .background(
            mainColor.gradient.opacity(0.15)
        )
        .clipShape(
            RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
        )
//        .shadow(radius: 1)

//        .frame(width: 300,height: 100)
    }
    
    init(pageType: PageType) {
        self.pageType = pageType
        let isIncome = pageType == .save
        
        _items = Query(filter: #Predicate {
            isIncome ? $0.isSave : !$0.isSave
        })
    }
    
    var mainColor:Color{
        if pageType == .save {
            return Color.red
        }else{
            return Color.green
        }
    }
    
    
    var body: some View {
        
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 165),spacing: 15),],spacing: 15) {
                ForEach(items) { item in
                    itemInList(item)
                }
            }
            .padding(.horizontal,15)
        }
        .overlay(content: {
            if items.count == 0 {
                Text("No Data.")
                    .font(.title)
                    .opacity(0.7)
            }
            
        })
        
        
        
    }
}

#Preview {
    ContentView()
        .environment(AppData())
        .modelContainer(for: BankItem.self, inMemory: true)
    
}
