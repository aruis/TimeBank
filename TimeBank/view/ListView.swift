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
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [BankItem]
    
    @State private var isShowAdd = false
    @State private var selectItem:BankItem = BankItem()
    
    @ViewBuilder
    func itemInList(_ item:BankItem) -> some View {
        
        Button( action: {
            
        }, label: {
            VStack(spacing:0){
                Spacer()
                    .frame(height: 30)
                
                Text(item.name)
                    .font(.largeTitle)
                
                Spacer()
                    .frame(height: 10)
                
                Text("\(item.saveMin) MIN")
                    .font(.callout)
                
                Spacer()
                
                VStack{
                    Text("Last Execute:")
                    if let lastTouch = item.lastTouch {
                        Text(lastTouch,style: .date)
                    } else{
                        Text("-")
                    }
                }
                .font(.caption)
                
            }
            .padding()
            .frame(maxWidth:.infinity,minHeight:  195)
            .background(
                mainColor
                    .gradient.opacity(0.15)
                    .shadow(.drop(radius: 5, y: 5))
                //                .shadow(.drop(radius: 15))
            )
            .clipShape(
                RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
            )
            
            
        })
        .buttonStyle(.plain)
        
        
        //        .shadow(radius: 1)
        
        //        .frame(width: 300,height: 100)
    }
    
    init(pageType: PageType) {
        self.pageType = pageType
        let isIncome = pageType == .save
        
        _items = Query(filter: #Predicate {
            isIncome ? $0.isSave : !$0.isSave
        },sort: \.createTime,order: .reverse)
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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 165),spacing: 12),],spacing: 12) {
                ForEach(items) { item in
                    itemInList(item)
                        .id(item.id)
                        .contextMenu{
                            Button{
                                selectItem = item
                                print(selectItem.name)
                                isShowAdd = true
                            }label: {
                                Label("Edit",systemImage: "pencil.circle")
                            }
                            
                            Button(role:.destructive){
                                modelContext.delete(item)
                            }label: {
                                Label("Delete", systemImage:  "trash")
                                //                                Text("Delete")
                            }
                        }
                    
                    
                    //                    NavigationLink(value: item, label: {
                    //
                    //
                    //                    })
                    
                    
                }

            }
            .animation(.default,value: items)
            .padding(.top,10)
            .padding(.horizontal,15)
        }
        .overlay(content: {
            if items.count == 0 {
                Text("No Data.")
                    .font(.title)
                    .opacity(0.7)
            }
            
        })
        .sheet(isPresented: $isShowAdd,content: {
            NewBankItem(pageType:.constant(pageType),bankItem: $selectItem)
        })
        
        
        
    }
}

#Preview {
    ContentView()
        .environment(AppData())
        .modelContainer(for: BankItem.self, inMemory: true)
    
}
