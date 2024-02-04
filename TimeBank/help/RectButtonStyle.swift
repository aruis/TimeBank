//
//  RectButtonStyle.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2024/2/4.
//

import SwiftUI

struct RectButtonStyle: ButtonStyle {
    
    var color = Color.blue
    
    func makeBody(configuration: Configuration) -> some View {
                        
        configuration.label
            .frame(maxWidth:.infinity,minHeight:  195)
            .background(
                color
                    .gradient.opacity(0.15)
                    .shadow(.drop(radius: 5, y: 5))
            )
            .clipShape(.rect(cornerSize: CGSize(width: 25, height: 25)))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .contentShape(.rect(cornerSize: CGSize(width: 25, height: 25)))
            .hoverEffect(.highlight)        
        
    }
}
