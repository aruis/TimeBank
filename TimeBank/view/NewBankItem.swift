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
                    .font(.system(size: 80))
                    .autocorrectionDisabled()
                    .padding()
                    .focused($nameFocused)
                    
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.center)
                    #endif
//                    .background(Color.red)
                Spacer()
                    .frame(height: 30)
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
            .padding(.horizontal,20)
            .navigationTitle(bankItem.name.isEmpty ?  "Add Item" :"Edit Item")
            #if os(macOS) || os(visionOS)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button{
                        dismiss()
                    }label: {
                        Text("Cancel")
                    }
                })
            })
            #endif
        }
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
            .font(.title2)
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
