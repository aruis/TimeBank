//
//  ListItem.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/16.
//

import Foundation

struct ListItem: Identifiable {
    var id = UUID()
    var title: String
    var children: [ListItem]? // 子项列表
    var isExpanded: Bool = false // 展开/折叠状态
}
