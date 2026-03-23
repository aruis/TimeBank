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
        
    @EnvironmentObject var settings: AppSetting
    
    @State private var pageType = PageType.save
    @State private var isShowAdd = false
    @State private var isShowSetting = false
    @State private var isShowBalanceTitle = false
    
    @Query private var items: [BankItem]
    
    private let floatingButtonDiameter: CGFloat = 58
    private let balanceBadgeHeight: CGFloat = 42
    
    var body: some View {
        ZStack(alignment: .bottom) {
            pageContent()
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
        #elseif os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                title()
                Spacer()
                settingsButton()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(alignment: .center) {
                balanceBadge()
                Spacer()
                addButton()
            }
            .frame(minHeight: floatingButtonDiameter, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
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
        .sensoryFeedback(.selection, trigger: pageType)
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
    func pageContent() -> some View {
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
        .ignoresSafeArea(edges: .bottom)
#if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
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
                
                Text(pageType == PageType.save ? "\(saveMinString)":"\(killMinString)")
                    .font(.subheadline)
                
            }
            //                    .background(.thinMaterial)
        })
#if os(iOS)
        .buttonStyle(.plain)
#else
        .buttonStyle(.borderless)
#endif
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
            HapticFeedback.tap()
            withAnimation(.default){
                isShowAdd = true
            }
        }label: {
            Image(systemName: "plus")
                .font(.title.weight(.bold))
        }
        .buttonStyle(CircularButtonStyle(color:mainColor.opacity(0.9), diameter: floatingButtonDiameter))
        .animation(.default, value: pageType)
        #if os(macOS)
        .padding(.trailing,25)
        .padding(.bottom,25)
        #elseif os(iOS)
        // iPhone uses a custom safe-area bar instead of the system toolbar.
        #else
        .padding(.bottom,25)
        #endif
    }

    @ViewBuilder
    func settingsButton() -> some View {
        Button {
            HapticFeedback.tap()
            isShowSetting = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.35), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .frame(width: 52, height: 52)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func balanceBadge() -> some View {
        HStack(spacing: 6){
            if(isShowBalanceTitle){
                Text("Your Balance")
                    .font(.subheadline.weight(.medium))
            }else{
                Image(systemName: settings.isEnableRate ? "banknote" : "clock")
                    .font(.subheadline.weight(.medium))
            }

            Text(balanceBadgeString)
                .font(.title3.monospacedDigit())
        }
        .animation(.default,value:isShowBalanceTitle)
        .onTapGesture {
            isShowBalanceTitle.toggle()
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: balanceBadgeHeight, alignment: .center)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 0.8)
                }
        }
        .contentShape(Rectangle())
    }

    var mainColor:Color{
        settings.themeColor(isSave: pageType == .save)
    }
    
    var saveMin:Float{
        items.totalValue(isSave: true, useRate: settings.isEnableRate)
    }
    
    var killMin:Float{
        items.totalValue(isSave: false, useRate: settings.isEnableRate)
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
            return String(format: "%.2f", items.balanceValue(useRate: true))
        }else{
            return String(format: "%.0f", items.balanceValue(useRate: false))
        }
        
    }

    var balanceBadgeString:String{
        if settings.isEnableRate {
            return "$ \(String(format: "%.0f", items.balanceValue(useRate: true)))"
        } else {
            return String(format: "%.0f", items.balanceValue(useRate: false))
        }
    }
    
}
