//
//  ContentView2.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/16.
//

import SwiftUI

struct ContentView2: View {
    @State private var items: [ListItem] = [
        ListItem(title: "章节 1", children: [
            ListItem(title: "小节 1.1"),
            ListItem(title: "小节 1.2"),
            ListItem(title: "小节 1.3")
        ]),
        ListItem(title: "章节 2", children: [
            ListItem(title: "小节 2.1"),
            ListItem(title: "小节 2.2"),
            ListItem(title: "小节 2.3")
        ]),
        ListItem(title: "章节 3", children: [
            ListItem(title: "小节 3.1"),
            ListItem(title: "小节 3.2", children: [
                ListItem(title: "详细 3.2.1"),
                ListItem(title: "详细 3.2.2")
            ]),
            ListItem(title: "小节 3.3")
        ])
    ]

    var body: some View {
        HierarchicalListView(items: $items)
//            .environment(\.editMode, .constant(.active)) // 激活编辑模式以支持排序
    }
}

#Preview {
    ContentView2()
}
