//
//  ContentView.swift
//  TimeBank
//
//  Created by 牧云踏歌 on 2023/11/9.
//

import SwiftUI
import SwiftData

struct ContentView3: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [BankItem]

    @State var isShowAdd = false
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text(item.name)
                    } label: {
                        Text(item.name)
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: move)
            }
            
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $isShowAdd, content: {
//            NewBankItem()
        })
    }

    func move(from source: IndexSet, to destination: Int) {
//         items.move(fromOffsets: source, toOffset: destination)
     }
    
    private func addItem() {
        isShowAdd = true
//        withAnimation {
//            let newItem = BankItem(name:"test",sort: 0)
//            modelContext.insert(newItem)
//        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BankItem.self, inMemory: true)
}
