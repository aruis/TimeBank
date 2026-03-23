//
//  ListView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI
import SwiftData

struct ListView: View {
    private enum ActiveSheet: Identifiable {
        case show
        case edit

        var id: Int {
            switch self {
            case .show:
                return 0
            case .edit:
                return 1
            }
        }
    }
    
    var pageType:PageType

    @EnvironmentObject var settings: AppSetting
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BankItem.lastTouch ,order: .reverse) private var items: [BankItem]
    
    @State private var selectedItem: BankItem?
    @State private var activeSheet: ActiveSheet?
    
    @ViewBuilder
    func itemInList(_ item:BankItem) -> some View {
        
        Button( action: {
            selectedItem = item
            activeSheet = .show
            HapticFeedback.selection()
        }, label: {
            VStack(spacing:0){
                Spacer()
                    .frame(height: 30)
                
                Text(item.name)
                    .font(.largeTitle)
                
                Spacer()
                    .frame(height: 10)
                
                
                Text(settings.isEnableRate ? "$ \(item.exchangeString)" : "\(item.saveMin) MIN")
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
            .overlay(alignment: .topTrailing, content: {
                if (item.isPin){
                    Button("Pin", systemImage: "mappin.circle"){
                        item.isPin.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .contentShape(.circle)
                    .buttonStyle(.borderless)
                    #if !os(visionOS)
                    .padding(10)
                    #endif
                }
                
            })
            
        })
        .buttonStyle(RectButtonStyle(color:mainColor))
        #if !os(visionOS)
        .sensoryFeedback(.selection, trigger: item.isPin)
        #endif

        
        
        
        
        //        .shadow(radius: 1)
        
        //        .frame(width: 300,height: 100)
    }
    
    init(pageType: PageType) {
        self.pageType = pageType
//        let isIncome = pageType == .save
//        
//        _items = Query(filter: #Predicate {
//            isIncome ? $0.isSave : !$0.isSave
//        },sort: \.lastTouch,order: .reverse)
    }
    
    var list:[BankItem] {
        return items.filter{
            $0.isSave == (pageType == .save )
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
    
//    func list() -> [BankItem]{
//            }
    
    
    var mainColor:Color{
        settings.themeColor(isSave: pageType == .save)
    }
    
    
    
    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 165),spacing: 12),],spacing: 12) {
                ForEach(list) { item in
                    
                    itemInList(item)
                        .id(item.id)
                        .contextMenu{
                            Button{
                                selectedItem = item
                                activeSheet = .edit
                            }label: {
                                Label("Edit",systemImage: "pencil.circle")
                            }
                            
                            Button(role:.destructive){
                                modelContext.delete(item)
                            }label: {
                                Label("Delete", systemImage:  "trash")
                            }
                        }
                    
                }

            }
            .animation(.default,value: items)
            .padding(.top,10)
            .padding(.horizontal,15)
            #if os(iOS)
            .padding(.bottom, 110)
            #endif
        }
        .overlay(content: {
            if items.count == 0 {
                Text("No Data.")
                    .font(.title)
                    .opacity(0.7)
            }
            
        })
        .sheet(item: $activeSheet, content: { sheet in
            switch sheet {
            case .edit:
                if let selectedItem {
                    NewBankItem(pageType: .constant(pageType), bankItem: binding(for: selectedItem))
                        .presentationDetents([.medium])
                }
            case .show:
                if let selectedItem {
                    ShowItem(bankItem: binding(for: selectedItem))
                        .presentationDetents([.height(400), .large])
                }
            }
        })

        
        
    }

    private func binding(for item: BankItem) -> Binding<BankItem> {
        Binding(
            get: { item },
            set: { _ in }
        )
    }
}
