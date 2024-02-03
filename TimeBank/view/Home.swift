//
//  Home.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI
import SwiftData
import OSLog

struct Home: View {
    
    @Environment(AppData.self) private var appData: AppData
    @Environment(\.modelContext) private var modelContext
    
    @State private var pageType = PageType.save
    @State var isShowAdd = false
    @State var isShowBalanceTitle = false
    
    @Query private var items: [BankItem]
    
    let logger:Logger = Logger.init()
    
    
    
    var body: some View {
        
        TabView(selection: $pageType) {
            ListView(pageType: .save)
                .tag(PageType.save)
#if os(macOS) || os(visionOS)
                .tabItem {Label("SaveTime", systemImage: "tray.and.arrow.down.fill")}
#endif
            
            ListView(pageType: .kill)
                .tag(PageType.kill)
#if os(macOS) || os(visionOS)
                .tabItem {Label("KillTime", systemImage: "tray.and.arrow.up.fill")}
#endif
        }
        #if os(macOS) || os(visionOS)
        .padding(.top,60)
        .overlay(alignment: .top, content: {
            HStack{
                title()
                Spacer()
                #if os(macOS)
                balance()
                #endif
            }
            .padding()
//            .padding(.top,20)
        })
        #endif
        #if !os(macOS)
        .ignoresSafeArea()
        .toolbar{
            ToolbarItem(placement: .topBarLeading){
                title()
            }
            
            ToolbarItem(placement: .topBarTrailing){
//                balance()
            }
            ToolbarItem(placement: .bottomBar){
                HStack{
                    HStack(spacing: 3){
                        if(isShowBalanceTitle){
                            Text("Your Balance")
                                .font(.title3)
                        }else{
                            Image(systemName: "clock")
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                                              
                        Text("\(saveMin-killMin)")
                            .font(.title3)
                    }
                    .animation(.default,value:isShowBalanceTitle)
                    .onTapGesture {
                        isShowBalanceTitle.toggle()
                    }
                    .onHover(perform: { hovering in
                        isShowBalanceTitle.toggle()
                    })
                    
                    Spacer()
                    addButton()
                }
                
            }
        }
        #endif
#if os(iOS)
        .tabViewStyle(.page)
#endif
        .background(
            Rectangle()
                .fill(.black.opacity(0.05))
                .ignoresSafeArea()
            
        )
#if os(macOS)
        .overlay(alignment: .bottomTrailing, content: {
            addButton()
        })
#endif
        .sheet(isPresented: $isShowAdd, content: {
            NewBankItem(pageType:$pageType,bankItem: .constant(BankItem()))
                .presentationDetents([.medium])
        })
        #if os(iOS)
        .sensoryFeedback(.decrease, trigger: pageType)
        #endif
    }
    
    @ViewBuilder
    func title() -> some View{
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
    }
    
    @ViewBuilder
    func balance() -> some View {
        VStack(alignment: .trailing, spacing: 0){
            Text("Your Balance")
                .font(.caption)
            
            HStack(spacing: 3){
                Image(systemName: "clock")
                    .fontWeight(.medium)
                    .font(.caption)
                Text("\(saveMin-killMin)")
                    .font(.title3)
            }
            
        }
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
        .buttonStyle(CircularButtonStyle(color:mainColor.opacity(0.85)))
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

