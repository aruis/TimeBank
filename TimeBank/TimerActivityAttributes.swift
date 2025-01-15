//
//  TimerAttributes.swift
//  TimeBank
//
//  Created by Rui Liu on 2024/12/12.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct TimerActivityAttributes:ActivityAttributes{

    struct ContentState: Codable, Hashable {
        var timeRemaining: Int        
    }

    var name: String
    var start: Date

}
#endif
