//
//  WatchHome.swift
//  TimeBankWatch Watch App
//
//  Created by 牧云踏歌 on 2024/1/9.
//

import SwiftUI
import SwiftData

struct WatchHome: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var pageType = PageType.home
    @State private var isShowNew = false
    
    @Query private var items: [BankItem]
    
    @State private var isShow = false
    @State private var isShowEditSheet = false
    @State private var isEdit = false
    @State private var isDelete = false
    @State private var selectItem:BankItem = BankItem()

    
    var body: some View {
        NavigationStack{
            TabView(selection: $pageType){
                homeView()
                    .tag(PageType.home)
                listView(type: .save)
                    .tag(PageType.save)
                listView(type: .kill)
                    .tag(PageType.kill)
            }
            .sheet(isPresented: $isShowNew){
                NewBankItem(pageType: $pageType, bankItem: .constant(BankItem()))
                    .onDisappear(perform: {
                        isShowNew = false
                    })
            }
            .animation(.default, value: pageType)
            .toolbar{
                ToolbarItem(placement: .topBarLeading, content: {
                    switch pageType {
                    case .home:
                        Text("TimeBank").monospaced().bold()
                    case .save:
                        Text("SaveTime \(saveMin)").monospaced().bold()
                    case .kill:
                        Text("KillTime \(killMin)").monospaced().bold()
                    }
                    
                })
            }

        }                    
    }
    
    
    @ViewBuilder
    func homeView() -> some View{
        TabView{
            numberView(title: "Your Balance",value: "\(saveMin-killMin)")
            numberView(title: "SaveTime",value: "\(saveMin)")
            numberView(title: "KillTime",value: "\(killMin)")
        }
        .tabViewStyle(.verticalPage)
    }
    
    @ViewBuilder
    func numberView(title:String,value:String) -> some View{
        VStack{
            Text(value)
                .font(.largeTitle)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.subheadline)
        }
    }
    
    
    @ViewBuilder
    func listView(type: PageType) -> some View{
        TabView{
            ForEach(list(type: type)){ item in
                VStack{
                    Text(item.name)
                        .font(.title)
                    Text("\(item.saveMin) MIN")
                        .font(.callout)
                    VStack{
                        Text("Last Execute:")
                        if let lastTouch = item.lastTouch {
                            Text(lastTouch,style: .date)
                        } else{
                            Text("-")
                        }
                    }
                    .font(.caption2)
                }
                .toolbar{
                    ToolbarItem(placement: .topBarTrailing){
                        Button{
                            isShowEditSheet = true
                        }label: {
                            Label("edit",systemImage: "slider.horizontal.3")
                        }
                        .sheet(isPresented: $isShowEditSheet, content: {
                            VStack(spacing: 10){
                                Button{
                                    selectItem = item
                                    isShowEditSheet = false
                                    isEdit = true
                                }label: {
                                    Label("Edit",systemImage: "pencil.circle")
                                }

                                
                                Button(role:.destructive){
                                    modelContext.delete(item)
                                    isShowEditSheet = false
                                }label: {
                                    Label("Delete", systemImage:  "trash")
                                }
                            }
                        })
                        .sheet(isPresented: $isEdit,content: {
                            NewBankItem(pageType:.constant(pageType),bankItem: $selectItem)
                                    .presentationDetents([.medium])
                        })

                        
                    }
                    
                    ToolbarItem(placement: .bottomBar, content: {
                        Button{
                            selectItem = item
                            isShow = true
                        }label: {
                            Label("Play",systemImage: "play")
                        }
                        .controlSize(.large)
                                                                        
                    })
                }

                
            }
            .sheet(isPresented: $isShow,content: {
                ShowItemWatch(bankItem: $selectItem)
            })

            Button("Add", systemImage: "plus", action: {
                isShowNew  = true
            })
            .padding(.horizontal,15)

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
