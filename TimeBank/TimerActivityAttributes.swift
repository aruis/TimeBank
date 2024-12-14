//
//  TimerAttributes.swift
//  TimeBank
//
//  Created by Rui Liu on 2024/12/12.
//

import ActivityKit
import Foundation

struct TimerActivityAttributes:ActivityAttributes{

    struct ContentState: Codable, Hashable {
        var start: Date
    }

    var name: String

}

