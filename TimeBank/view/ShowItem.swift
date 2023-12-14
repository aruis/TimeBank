//
//  ShowItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/12/14.
//

import SwiftUI

struct ShowItem: View {
    
    @Binding var bankItem:BankItem
    
    @State var inTimer = false
    
    var body: some View {
        NavigationStack{
            TabView{
                VStack{
                    Circle()
                        .frame(width: 240)
                        .foregroundColor(mainColor.opacity(0.85))
                        .overlay(content: {
                            if inTimer {
                                Text("00:00:00")
                                    .foregroundStyle(Color.white)
                                    .font(.largeTitle)
                                    .transition(.moveAndFadeTop)
                            } else {
                                Text( "\(bankItem.saveMin) MIN")
                                    .foregroundStyle(Color.white)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .shadow(radius: 3)
//                                    .opacity(inTimer ? 0 : 1)
                                    .transition(.moveAndFadeBottom)
//                                    .transition(.move(edge: .bottom))
//                                    .animation(.easeInOut, value: inTimer)

                            }
                            
                                
                        })
                        .overlay{
                            Button{
                                withAnimation{
                                    inTimer.toggle()
                                }
                                
                            }label: {
                                Image(systemName: inTimer ? "stop.fill" : "play.fill")
                                    .foregroundStyle(Color.white)
                                    .font(.largeTitle)
                                    .shadow(radius: 3)
                            }
                            .padding(.top,120)
                            
                        }
                    
                }
                
                Color.blue
                
            }
//            .tabViewStyle(.page)
            
            .navigationTitle(bankItem.name)
            
            
            
        }
        
    }
    
    var mainColor:Color{
        if bankItem.isSave {
            return Color.red
        }else{
            return Color.green
        }
    }

}

#Preview {
    ShowItem(bankItem: .constant(BankItem(name: "test")))
}

extension AnyTransition {
    static var moveAndFadeTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal:  .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var moveAndFadeBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:  .move(edge: .top).combined(with: .opacity)
        )
    }
}
