//
//  EditLogItem.swift
//  TimeBank
//
//  Created by Rui Liu on 2024/12/11.
//
import SwiftUI

struct EditLogItem: View {
    private var log: ItemLog
    @Environment(\.dismiss) private var dismiss // 用于关闭页面

    @State private var begin:Date;
    @State private var end:Date;

    init(log: ItemLog) {
        self.log = log
        self.begin = log.begin
        self.end = log.end
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Time Range")) {
                    DatePicker(
                        "Begin",
                        selection: $begin,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(true)
                    DatePicker(
                        "End",
                        selection: $end,
                        in: begin.plus(1, component: .minute)...log.end, // 结束时间不能早于开始时间
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle("Edit Time")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button{
                        log.begin = begin
                        log.end = end
                        let duration = begin.elapsedMin(end)
                        log.saveMin = max(duration, 0) // 确保分钟数不为负数
                        dismiss()
                    } label:{
                        Text("Save")
                    }
                    .disabled(begin == log.begin && end == log.end)
                })
#if os(macOS) || os(visionOS)
                ToolbarItem(placement: .cancellationAction, content: {

                    Button{
                        dismiss()
                    }label: {
                        Text("Close")
                    }
                })
#endif
            })
        }

    }

}

#Preview {
    EditLogItem(log: ItemLog(bankItem: BankItem(name:"test"), begin: Date(), end: Date().addingTimeInterval(3600)))
}
