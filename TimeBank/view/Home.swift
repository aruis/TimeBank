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
        
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: AppSetting
    
    @State private var pageType = PageType.save
    @State private var isShowAdd = false
    @State private var isShowSetting = false
    @State private var isShowBalanceTitle = false
    
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
        #if os(macOS)
        .padding(.top,60)
        .overlay(alignment: .top, content: {
            HStack{
                title()
                    .focusable(false)
                Spacer()
                balance()
            }
            .padding()
//            .padding(.top,20)
        })
        #else
        .ignoresSafeArea()
        .toolbar{
            ToolbarItem(placement: .topBarLeading){
                title()
            }
            
            ToolbarItem(placement: .topBarTrailing){
                Button("Edit", systemImage: "ellipsis"){
                    isShowSetting = true
                }
                
            }
            ToolbarItem(placement: .bottomBar){
                HStack{
                    HStack(spacing: 3){
                        if(isShowBalanceTitle){
                            Text("Your Balance")
                                .font(.title3)
                        }else{
                            Image(systemName: settings.isEnableRate ? "banknote" : "clock")
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                                              
                        Text("\(balanceString)")
                            .font(.title3)
                    }
                    .animation(.default,value:isShowBalanceTitle)
                    .onTapGesture {
                        isShowBalanceTitle.toggle()
                    }
                    #if os(visionOS)
                    .padding()
                    #endif
                    .contentShape(.capsule)
                    .hoverEffect(.highlight)
                    
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
        #if !os(visionOS) 
        .sensoryFeedback(.decrease, trigger: pageType)
        #endif
        .sheet(isPresented: $isShowAdd, content: {
            NewBankItem(pageType:$pageType,bankItem: .constant(BankItem()))
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isShowSetting, content: {
            SettingView()
        })

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
                
                Text(pageType == PageType.save ? "\(saveMinString)":"\(killMinString)")
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
                Image(systemName: settings.isEnableRate ? "banknote" : "clock")
                    .fontWeight(.medium)
                    .font(.caption)
                Text("\(balanceString)")
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
        .animation(.default, value: pageType)
        #if os(macOS)
        .padding(.trailing,25)
        #endif
        .padding(.bottom,25)
    }
    
    var mainColor:Color{
        if pageType == .save {
            return Color.red
        }else{
            return Color.green
        }
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

