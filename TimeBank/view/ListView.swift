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
        case show(BankItem)
        case edit(BankItem)

        var id: String {
            switch self {
            case let .show(item):
                return "show-\(item.id)"
            case let .edit(item):
                return "edit-\(item.id)"
            }
        }
    }
    
    var pageType:PageType

    @EnvironmentObject var settings: AppSetting
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \BankItem.lastTouch ,order: .reverse) private var items: [BankItem]
    
    @State private var activeSheet: ActiveSheet?
    
    @ViewBuilder
    func itemInList(_ item:BankItem) -> some View {
        
        Button( action: {
            activeSheet = .show(item)
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
        items.filteredAndSorted(isSave: pageType == .save)
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
                                activeSheet = .edit(item)
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
            if list.isEmpty {
                Text("No Data.")
                    .font(.title)
                    .opacity(0.7)
            }
            
        })
        .sheet(item: $activeSheet, content: { sheet in
            switch sheet {
            case let .edit(item):
                NewBankItem(pageType: .constant(pageType), bankItem: binding(for: item))
                    .presentationDetents([.medium])
            case let .show(item):
                ShowItem(bankItem: binding(for: item))
                    .presentationDetents([.height(400), .large])
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
