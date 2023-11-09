//
//  Item.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
