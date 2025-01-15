//
//  IntExt.swift
//  TimeBank
//
//  Created by Rui Liu on 2025/1/15.
//

import Foundation

extension Int{
    func formatTime() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
