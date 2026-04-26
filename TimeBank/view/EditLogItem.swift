//
//  EditLogItem.swift
//  TimeBank
//
//  Created by Rui Liu on 2024/12/11.
//
import SwiftUI
import SwiftData

struct EditLogItem: View {
    enum Mode {
        case create(BankItem)
        case edit(ItemLog)
    }

    private let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var begin: Date
    @State private var end: Date
    @State private var errorMessage: String?

    init(log: ItemLog) {
        self.mode = .edit(log)
        self._begin = State(initialValue: log.begin)
        self._end = State(initialValue: log.end)
    }

    init(bankItem: BankItem, begin: Date? = nil, end: Date? = nil) {
        let defaultRange = Self.defaultRange(for: bankItem, begin: begin, end: end)
        self.mode = .create(bankItem)
        self._begin = State(initialValue: defaultRange.begin)
        self._end = State(initialValue: defaultRange.end)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Time Range")) {
                    DatePicker(
                        "Begin",
                        selection: $begin,
                        in: ...end.minus(1, component: .minute),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    DatePicker(
                        "End",
                        selection: $end,
                        in: begin.plus(1, component: .minute)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                errorSection
            }
            .navigationTitle(title)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                    }
                    .disabled(!canSave)
                })
#if os(macOS) || os(visionOS)
                ToolbarItem(placement: .cancellationAction, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                })
#else
                ToolbarItem(placement: .cancellationAction, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                })
#endif
            })
            .onChange(of: begin) {
                errorMessage = nil
            }
            .onChange(of: end) {
                errorMessage = nil
            }
        }
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .create:
            "Add Log"
        case .edit:
            "Edit Time"
        }
    }

    private var minimumDurationMessage: String {
        String(
            format: String(localized: "The record must be at least %lld minute long."),
            locale: Locale.current,
            BankItem.minimumLogDurationMinutes
        )
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private var canSave: Bool {
        switch mode {
        case .create:
            return begin < end && begin.elapsedMin(end) >= BankItem.minimumLogDurationMinutes
        case let .edit(log):
            guard begin < end, begin.elapsedMin(end) >= BankItem.minimumLogDurationMinutes else {
                return false
            }

            return begin != log.begin || end != log.end
        }
    }

    private func save() {
        do {
            switch mode {
            case let .create(bankItem):
                _ = try bankItem.recordLog(begin: begin, end: end)
            case let .edit(log):
                guard let bankItem = log.bankItem else {
                    errorMessage = String(localized: "Failed to save this log.")
                    return
                }
                try bankItem.updateLog(log, begin: begin, end: end)
            }

            try modelContext.save()
            dismiss()
        } catch BankItem.LogRecordError.invalidRange {
            errorMessage = String(localized: "End time must be later than begin time.")
        } catch BankItem.LogRecordError.futureRange {
            errorMessage = String(localized: "The record cannot be in the future.")
        } catch BankItem.LogRecordError.durationTooShort {
            errorMessage = minimumDurationMessage
        } catch BankItem.LogRecordError.overlappingLog {
            errorMessage = String(localized: "This log overlaps an existing record.")
        } catch {
            errorMessage = String(localized: "Failed to save this log.")
        }
    }

    private static func defaultRange(for bankItem: BankItem, begin: Date?, end: Date?) -> (begin: Date, end: Date) {
        if let begin, let end {
            return normalizedRange(begin: begin, end: end)
        }

        let defaultRange = bankItem.latestAvailableRangeEndingNow()
        return normalizedRange(begin: begin ?? defaultRange.begin, end: end ?? defaultRange.end)
    }

    private static func normalizedRange(begin: Date, end: Date) -> (begin: Date, end: Date) {
        let normalizedEnd = max(end, begin.plus(1, component: .minute))
        return (begin, normalizedEnd)
    }
}

#Preview("Edit") {
    EditLogItem(log: ItemLog(bankItem: BankItem(name: "test"), begin: Date(), end: Date().addingTimeInterval(3600)))
}

#Preview("Create") {
    EditLogItem(bankItem: BankItem(name: "test"))
}
