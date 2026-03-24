//
//  TimerAttributes.swift
//  TimeBank
//
//  Created by Rui Liu on 2024/12/12.
//

#if canImport(ActivityKit) && !os(macOS)
import ActivityKit
import Foundation

struct TimerActivityAttributes:ActivityAttributes{

    struct ContentState: Codable, Hashable {
        enum SessionState: String, Codable, Hashable {
            case running
            case interrupted
        }

        var recordedSeconds: Int
        var sessionState: SessionState
    }

    var itemID: String
    var name: String
    var start: Date

}
#endif
