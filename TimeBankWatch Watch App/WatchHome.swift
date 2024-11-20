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
    @EnvironmentObject var settings: AppSetting
    
    @State private var pageType = PageType.home
    @State private var isShowNew = false
        
    @Query(sort: \BankItem.lastTouch ,order: .reverse) private var items: [BankItem]
    
    @State private var isShow = false
    @State private var isShowEditSheet = false
    @State private var isEdit = false
    @State private var isDelete = false
    @State private var isShowSetting = false
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
            .sheet(isPresented: $isShowSetting, content: {
                SettingView()
                    .presentationDetents([.medium])
            })

            .animation(.default, value: pageType)
            .toolbar{
                ToolbarItem(placement: .topBarLeading, content: {
                    switch pageType {
                    case .home:
                        Text("TimeBank").monospaced().bold()
                    case .save:
                        VStack{
                            Text("SaveTime")
                                .font(.caption2.monospaced())
//                                .monospaced().bold()
                            Text(saveMinString)
                                .font(.caption.bold())
                        }
//                        Text("SaveTime \(saveMin)").monospaced().bold()
                    case .kill:
                        VStack{
                            Text("KillTime")
                                .font(.caption2.monospaced())
                            Text(killMinString)
                                .font(.caption.bold())
                        }
//                        Text("KillTime \(killMin)").monospaced().bold()
                    }
                    
                })
                
                ToolbarItem(placement: .topBarTrailing){
                    Button("Edit", systemImage: "ellipsis"){
                        isShowSetting = true
                    }
                    
                }

            }

        }                    
    }
    
    
    @ViewBuilder
    func homeView() -> some View{
        TabView{
            numberView(title: String(localized: "Your Balance"),value: balanceString)
            numberView(title: "SaveTime",value: saveMinString)
            numberView(title: "KillTime",value: killMinString)
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
                .monospaced()
        }
    }
    
    
    @ViewBuilder
    func listView(type: PageType) -> some View{
        TabView{
            ForEach(list(type: type)){ item in
                VStack{
                    Text(item.name)
                        .font(.title)
                    Text(settings.isEnableRate ? "$ \(item.exchangeString)" : "\(item.saveMin) MIN")
                        .font(.body)
                    Group{
                        Text("Last Execute:")
                        if let lastTouch = item.lastTouch {
                            Text(lastTouch,style: .date)
                        } else{
                            Text("-")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                                    item.isPin.toggle()
                                    isShowEditSheet = false
                                }label:{
                                    Label("Pin",systemImage: item.isPin ? "pin.circle.fill" : "pin.circle")
                                }
                                
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
        }.sorted(by: { item1,item2 in
            // 首先根据 isPin 状态进行排序
                if item1.isPin && !item2.isPin {
                    return true
                } else if !item1.isPin && item2.isPin {
                    return false
                } else {
                    // 如果 isPin 状态相同，再根据 lastTouch 和 createTime 进行排序
                    // 如果 lastTouch 都不为 nil，按照 lastTouch 降序排序
                    if let lastTouch1 = item1.lastTouch, let lastTouch2 = item2.lastTouch {
                        return lastTouch1 > lastTouch2
                    } else if item1.lastTouch != nil {
                        // 如果 item1 的 lastTouch 不为 nil，而 item2 的为 nil
                        return true
                    } else if item2.lastTouch != nil {
                        // 如果 item2 的 lastTouch 不为 nil，而 item1 的为 nil
                        return false
                    } else {
                        // 如果 lastTouch 都为 nil，按照 createTime 降序排序
                        return item1.createTime > item2.createTime
                    }
                }
        })

    }
    
    
    var saveMin:Float{
        return items.reduce(0) { sum, item in
            if (item.isSave){
                return sum + (settings.isEnableRate ? item.exchange : Float(item.saveMin))
            } else {
                return sum
            }
        }
    }
    
    var killMin:Float{
        return items.reduce(0) { sum, item in
            if (!item.isSave){
                return sum + (settings.isEnableRate ? item.exchange : Float(item.saveMin))
            } else {
                return sum
            }
        }
    }
    
    var saveMinString:String{
        if settings.isEnableRate {
            return String(format: "%.2f",self.saveMin)
        }else{
            return String(format: "%.0f",self.saveMin)
        }
    }
    
    var killMinString:String{
        if settings.isEnableRate {
            return String(format: "%.2f",self.killMin)
        }else{
            return String(format: "%.0f",self.killMin)
        }
    }
    
    var balanceString:String{
        if settings.isEnableRate {
            return String(format: "%.2f",self.saveMin - self.killMin)
        }else{
            return String(format: "%.0f",self.saveMin - self.killMin)
        }
        
    }
    
}

#Preview {
    WatchHome()
}
