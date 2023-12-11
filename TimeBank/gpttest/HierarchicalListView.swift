//
//  HierarchicalListView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/16.
//

import SwiftUI

struct HierarchicalListView: View {
    @Binding var items: [ListItem]

    var body: some View {
        List {
            ForEach($items) { $item in
                ListItemView(item: $item)
            }
            .onMove(perform: move)
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}


//#Preview {
//    HierarchicalListView()
//}
