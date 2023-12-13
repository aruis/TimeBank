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
                        isShaking = false
                    } else {
                        let newItem = BankItem(name:name,sort: 0)
                        newItem.lastTouch = Date()
                        newItem.isSave = pageType == .save
                        modelContext.insert(newItem)
                        dismiss()
                    }
                }label: {
                    Text("Save")
                        .font(.title2)
                        .padding()
//                        .background(.pink)
//                        .fontWeight(.semibold)
//                        .padding(.horizontal,45)
//                        .padding(.vertical,12)
                        
                }
//                .buttonBorderShape(.capsule)
                .buttonStyle(MyButtonStyle(color: mainColor))
                .controlSize(.large)
//                .scaleEffect(isShaking ? 1.12 : 1.0)

                .rotation3DEffect(Angle(degrees: isShaking ? 10 : 0), axis: (x:0,y:1,z:0))
//                .rotationEffect(Angle(degrees: isShaking ? 1 : 0), anchor: .center)
                
//                Animation.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true),
                
                
                
                Spacer()
            }
            #if os(macOS)
            .frame(width: 400,height: 300)
            #endif
//            .background(Color.red)
            .padding(.horizontal,20)
            .navigationTitle("Add Item")
            #if os(macOS)
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
            .fontWeight(.bold)
            .padding()
            .background(color.gradient.opacity(0.75))
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(radius: 3)
    }
}

#Preview {
    NewBankItem(pageType:.constant(PageType.kill))
}
