//
//  ListItemView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/16.
//

import SwiftUI

struct ListItemView: View {
    @Binding var item: ListItem

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text(item.title)
                    Spacer()
                    if item.children != nil {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .onTapGesture {
                                item.isExpanded.toggle()
                            }
                    }
                }
                if item.isExpanded, let children = item.children {
                    HierarchicalListView(items: .constant(children))
                        .frame(width: geometry.size.width)
                        .padding(.leading)
                }
            }
        }
    }
}


//#Preview {
//    ListItemView()
//}
