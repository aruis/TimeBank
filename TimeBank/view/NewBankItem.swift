//
//  NewBankItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import SwiftUI

struct NewBankItem: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var pageType:PageType
        
    @State var name:String = ""
    
    @State var isShaking = false
    @FocusState private var nameFocused: Bool
    
    @Binding var bankItem:BankItem
    
    var body: some View {

        NavigationStack{
            VStack(alignment: .center,spacing: 0){
                Spacer()
                    .frame(height: 30)
                TextField("", text: $name)
                #if !os(watchOS)
                    .font(.system(size: 80))
                #endif
                    .autocorrectionDisabled()
                    .padding()
                    .focused($nameFocused)
                    
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.center)
                    #endif
//                    .background(Color.red)
                
                Spacer()
                #if os(watchOS)
                    .frame(height: 10)
                #else
                    .frame(height: 30)
                #endif
                Button{
                    if name.isEmpty {
                        withAnimation(Animation.easeIn(duration: 0.12).repeatCount(3, autoreverses: true), {
                            isShaking = true
                        })
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        #endif
                        isShaking = false
                    } else {
                        if !bankItem.name.isEmpty{
                            bankItem.name = name
                        } else {
                            let newItem = BankItem(name:name,sort: 0)                            
                            newItem.isSave = pageType == .save
                            modelContext.insert(newItem)
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        dismiss()
                    }
                }label: {
                    Text("Save")
                        .padding()
                }
                #if !os(visionOS)
                .buttonStyle(MyButtonStyle(color: mainColor))
                #endif
//                .scaleEffect(isShaking ? 1.12 : 1.0)
                .rotation3DEffect(Angle(degrees: isShaking ? 10 : 0), axis: (x:0,y:1,z:0))
//                .rotationEffect(Angle(degrees: isShaking ? 1 : 0), anchor: .center)
                Spacer()
            }
            #if os(macOS)
            .frame(width: 400,height: 300)
            #endif
            #if os(watchOS)
            .padding(.horizontal,5)
            #else
            .padding(.horizontal,20)
            #endif
            .navigationTitle(bankItem.name.isEmpty ?  "Add Item" :"Edit Item")
            .toolbar(content: {
                #if os(macOS)
                ToolbarItem(placement: .cancellationAction, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Cancel")
                    }
                })
                #else
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Cancel")
                    }
                })
                #endif

            })
        }
//        .defaultFocus($nameFocused,true)
        .onAppear{
            nameFocused = true
            self.name = bankItem.name
        }
        
        
        
    }
    
    var mainColor:Color{
        if pageType == .save {
            return Color.red
        }else{
            return Color.green
        }
    }

}

struct MyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 5).stroke(Color.red, lineWidth: 2))
    }
}

struct MyButtonStyle: ButtonStyle {
    
    var color:Color
    
    init(color:Color){
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
        #if os(watchOS)
            .font(.callout)
        #else
            .font(.title2)
        #endif
            .fontWeight(.bold)
            .background(color.gradient.opacity(0.75))
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(radius: 3)            
    }
}

//#Preview {
//    NewBankItem(pageType:.constant(PageType.kill))
//}
