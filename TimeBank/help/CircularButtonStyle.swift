//
//  CircularButtonStyle.swift
//  moodbox
//
//  Created by 牧云踏歌 on 2023/4/10.
//

import SwiftUI

struct CircularButtonStyle: ButtonStyle {
    
    var color = Color.blue
    var diameter: CGFloat = 52
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: diameter, height: diameter)
            .background(
                Circle()
                    .fill(color)
            )
            .foregroundColor(.white)
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.26), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .contentShape(.circle)
            #if os(visionOS)
            .hoverEffect(.highlight)
            #endif
        
    }
}
