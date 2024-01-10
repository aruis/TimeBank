//
//  Home.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI
import SwiftData

struct Home: View {
    
    @Environment(AppData.self) private var appData: AppData
    @Environment(\.modelContext) private var modelContext
    @State private var pageType = PageType.save
    @State var isShowAdd = false
            
    @Query private var items: [BankItem]
    
    var body: some View {
        VStack{
            #if !os(watchOS)
            HStack{
                
                Button(action: {
                    withAnimation(.easeInOut, {
                        pageType = (pageType == .save ? .kill : .save)
                    })
                }, label: {
                    HStack(alignment: .firstTextBaseline,spacing: 4){
                        Text(pageType == PageType.save ? "SAVETIME":"KILLTIME")
                            .font(.title.monospaced())
                        
                        Text(pageType == PageType.save ? "\(saveMin)":"\(killMin)")
                            .font(.subheadline)
                        
                    }
                    //                    .background(.thinMaterial)
                })
                .buttonStyle(.borderless)
                .foregroundStyle(mainColor)
                .animation(.default, value: pageType)
                
                
                Spacer()
                VStack(alignment: .trailing, spacing: 0){
                    Text("Your Balance")
                        .font(.caption)
                    //                        .foregroundColor(.black)
                    
                    HStack(spacing: 4){
                        Image(systemName: "clock")
                            .fontWeight(.medium)
                        Text("\(saveMin-killMin)")
                            .font(.title3)
                        
                    }
                    
                    
                }
            }
            .padding([.top,.horizontal],15)
            #endif
            //            Spacer()
            
            TabView(selection: $pageType) {
                ListView(pageType: .save)
                    .tag(PageType.save)
#if os(macOS)
                    .tabItem {Label("SaveTime", systemImage: "tray.and.arrow.down.fill")}
#endif
                
                ListView(pageType: .kill)
                    .tag(PageType.kill)
#if os(macOS)
                    .tabItem {Label("KillTime", systemImage: "tray.and.arrow.down.fill")}
#endif
            }
            .ignoresSafeArea()
            #if os(watchOS)
            .toolbar{
                ToolbarItem(placement: .topBarLeading){
                    HStack(alignment: .firstTextBaseline,spacing: 4){
                        Text(pageType == PageType.save ? "SAVETIME":"KILLTIME").monospaced()
                           
                        
                        Text(pageType == PageType.save ? "\(saveMin)":"\(killMin)")
                            .font(.caption2)
                        
                    }
                }
            }
            
            
//            .navigationTitle(Text("\(saveMin-killMin)"))
            
            #endif
#if os(iOS)
            .tabViewStyle(.page)
#endif
            
            
            
        }
        #if os(watchOS)
        .containerBackground(for: .navigation, content: {
            Rectangle()
                .fill(.black.opacity(0.05))
                .ignoresSafeArea()
        })
        #else
        .background(
            Rectangle()
                .fill(.black.opacity(0.05))
                .ignoresSafeArea()

        )
        #endif
        #if !os(watchOS)
        .overlay(alignment: .bottomTrailing, content: {
            addButton()
        })
        #endif
        .sheet(isPresented: $isShowAdd, content: {
            NewBankItem(pageType:$pageType,bankItem: .constant(BankItem()))
                .presentationDetents([.medium])
        })
    }
        
    @ViewBuilder
    func addButton() -> some View{
        Button{
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            withAnimation(.default){
                isShowAdd = true
            }
        }label: {
            Image(systemName: "plus")
                .font(.title)
        }
        #if !os(visionOS)
        .buttonStyle(CircularButtonStyle(color:mainColor.opacity(0.75)))
        #endif
        .shadow(radius: 5,x: 3,y: 3)
        .animation(.default, value: pageType)
        .ignoresSafeArea()
        .padding(.trailing,25)
        .padding(.bottom,25)
        .controlSize(.extraLarge)
    }
    
    var mainColor:Color{
        if pageType == .save {
            return Color.red
        }else{
            return Color.green
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

