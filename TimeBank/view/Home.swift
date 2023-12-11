//
//  Home.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import SwiftUI

struct Home: View {
            
    @Environment(AppData.self) private var appData: AppData
    @Environment(\.modelContext) private var modelContext
    @State private var pageType = PageType.save
    @State var isShowAdd = false
    
//    var size:CGSize
    
    var total:Int{
        appData.totalIn - appData.totalOut
    }
    
    var body: some View {
        VStack{
            HStack{

                Button(action: {
                    withAnimation(.easeInOut, {
                        pageType = (pageType == .save ? .kill : .save)
                    })                    
                }, label: {
                    HStack(alignment: .firstTextBaseline,spacing: 4){
                        Text(pageType == PageType.save ? "SAVETIME":"KILLTIME")
                            .font(.title.monospaced())
                            
                        Text(pageType == PageType.save ? "\(appData.totalIn)":"\(appData.totalOut)")
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
                        Text("\(total)")
                            .font(.title3)
                            
                    }
                    
                    
                }
            }
            .padding([.top,.horizontal],15)
            
//            Spacer()
            
            TabView(selection: $pageType) {
                ListView(pageType: .save)
                    .tag(PageType.save)
                    
                ListView(pageType: .kill)
                    .tag(PageType.kill)
            }
            .tabViewStyle(.page)
            
            
            .ignoresSafeArea()
            

        }
        .background(
            Rectangle()
                .fill(.black.opacity(0.05))
                .ignoresSafeArea()
        )
        .overlay(alignment: .bottomTrailing, content: {
            addButton()
        })
        .sheet(isPresented: $isShowAdd, content: {
            NewBankItem()
        })

    }
    
    func addButton() -> some View{
        Button{
            withAnimation(.default){
                isShowAdd = true
            }
        }label: {
            Image(systemName: "plus")
                .font(.title)
        }
        .buttonStyle(CircularButtonStyle(color:mainColor.opacity(0.75)))
        .padding(.trailing,25)
        .shadow(radius: 5,x: 3,y: 3)
        .animation(.default, value: pageType)
    }
    
    var mainColor:Color{
        if pageType == .save {
            return Color.red
        }else{
            return Color.green
        }
    }
    
}

enum PageType{
    case save
    case kill
}

#Preview {
    ContentView()
        .environment(AppData())
}

