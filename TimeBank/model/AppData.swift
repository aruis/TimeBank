//
//  GlobalData.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/17.
//

import Foundation

@Observable class AppData {
    
     var totalIn:Int
     var totalOut:Int
    
    init() {
        totalIn = 5
        totalOut = 10
    }
}
