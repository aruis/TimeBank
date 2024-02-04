//
//  CircularButtonStyle.swift
//  moodbox
//
//  Created by 牧云踏歌 on 2023/4/10.
//

import SwiftUI

struct CircularButtonStyle: ButtonStyle {
    
    var color = Color.blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(20)
            .background(color)
            .foregroundColor(.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
            )
            .shadow(radius: 5,x: 3,y: 3)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .contentShape(.circle)
            .hoverEffect(.highlight)
            
        
    }
}
