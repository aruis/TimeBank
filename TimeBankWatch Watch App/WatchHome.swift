//
//  WatchHome.swift
//  TimeBankWatch Watch App
//
//  Created by 牧云踏歌 on 2024/1/9.
//

import SwiftUI
import SwiftData

struct WatchHome: View {
    @State private var pageType = PageType.home
    @State private var isShowNew = false
    
    @Query private var items: [BankItem]

    
    var body: some View {
        NavigationSplitView(sidebar: {
            TabView(selection: $pageType){
                homeView()
                    .tag(PageType.home)
                listView(type: .save)
                    .tag(PageType.save)
                listView(type: .kill)
                    .tag(PageType.kill)
            }
            .navigationDestination(isPresented: $isShowNew){
                NewBankItem(pageType: $pageType, bankItem: .constant(BankItem()))
                    .onDisappear(perform: {
                        isShowNew = false
                    })
            }
            .animation(.default, value: pageType)
            .toolbar{
                ToolbarItem(placement: .topBarLeading, content: {
                    Button{
                        
                    }label: {
                        Image(systemName: "house")
                    }
                })
            }

        }, detail: {
            
        })
            
        
        


        
    }
    
    
    @ViewBuilder
    func homeView() -> some View{
        VStack{
            Text("\(saveMin-killMin)")
                .font(.title)
                .foregroundStyle(.primary)
            
            Text("Your Balance")
                .font(.subheadline)
         
        }
        

    }
    
    @ViewBuilder
    func listView(type: PageType) -> some View{
        TabView{
            ForEach(list(type: type)){ item in
                Text(item.name)
            }
            Button("Add", systemImage: "plus", action: {
                isShowNew  = true
            })

        }
        .tabViewStyle(.verticalPage)
        .containerBackground( type == .save ? Color.red.gradient : Color.green.gradient, for: .navigation)

    }
    
    func list(type:PageType) -> [BankItem]{
        return items.filter{
            $0.isSave == (type == .save )
        }
    }
    
    
    var saveMin:Int{
        return items.reduce(0) { sum, item in
            if (item.isSave){
              return  sum + item.saveMin
            } else {
                return sum
            }
        }
    }
    
    var killMin:Int{
        return items.reduce(0) { sum, item in
            if (!item.isSave){
               return sum + item.saveMin
            } else {
                return sum
            }
        }
    }
    
}

#Preview {
    WatchHome()
}
