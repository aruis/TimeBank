//
//  GlobalStatsView.swift
//  TimeBank
//
//  Created by Codex on 2026/4/26.
//

import Charts
import SwiftUI

struct GlobalStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSetting

    @State private var selectedRange: AnalyticsDateRange = .all
    @State private var showCustomRange = false
    @State private var customDays = 30
    @State private var customDaysText = "30"

    let items: [BankItem]

    private var summary: AnalyticsSummary {
        AnalyticsAggregator.globalSummary(
            items: items,
            useRate: settings.isEnableRate,
            range: selectedRange
        )
    }

    private var presetRanges: [AnalyticsDateRange] {
        [.all, .currentYear, .currentMonth, .recentDays(7), .recentDays(30)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    rangeSection()
                    totalsSection()
                    ratioSection()
                    topItemsSection(
                        title: "SaveTime 排名",
                        items: summary.topSaveItems,
                        color: settings.themeColor(isSave: true)
                    )
                    topItemsSection(
                        title: "KillTime 排名",
                        items: summary.topKillItems,
                        color: settings.themeColor(isSave: false)
                    )
                }
                .padding()
            }
            .navigationTitle("统计")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showCustomRange) {
                customRangeView()
            }
        }
#if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
#endif
    }

    @ViewBuilder
    private func rangeSection() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(presetRanges) { range in
                    rangeButton(title: range.title, isSelected: selectedRange == range) {
                        selectedRange = range
                    }
                }

                rangeButton(
                    title: selectedRange.isCustomRecentDays ? selectedRange.title : "自定义",
                    isSelected: selectedRange.isCustomRecentDays
                ) {
                    customDaysText = "\(customDays)"
                    showCustomRange = true
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func rangeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? settings.themeColor(isSave: true) : Color.secondary.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func totalsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedRange.title)
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StatTile(
                        title: "SaveTime",
                        value: valueText(summary.saveTotal),
                        color: settings.themeColor(isSave: true)
                    )
                    StatTile(
                        title: "KillTime",
                        value: valueText(summary.killTotal),
                        color: settings.themeColor(isSave: false)
                    )
                }

                StatTile(
                    title: "结余",
                    value: valueText(summary.balance),
                    color: summary.balance >= 0 ? settings.themeColor(isSave: true) : settings.themeColor(isSave: false)
                )
            }
        }
    }

    @ViewBuilder
    private func ratioSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("占比")
                .font(.headline)

            if summary.saveTotal <= 0 && summary.killTotal <= 0 {
                Text("暂无记录")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 14) {
                    Chart(ratioSlices) { slice in
                        SectorMark(
                            angle: .value("数值", slice.value),
                            innerRadius: .ratio(0.58),
                            angularInset: 2
                        )
                        .foregroundStyle(slice.color)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 136, height: 136)
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(ratioSlices) { slice in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(slice.color)
                                    .frame(width: 10, height: 10)
                                Text(slice.title)
                                    .lineLimit(1)
                                Spacer()
                                Text(valueText(slice.value))
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func topItemsSection(title: LocalizedStringKey, items: [ItemTotal], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if items.isEmpty {
                Text("暂无记录")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        HStack {
                            Text(item.name)
                                .lineLimit(1)
                            Spacer()
                            Text(itemValueText(item))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(color)
                        }
                        .padding(.vertical, 10)

                        if item.id != items.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func itemValueText(_ item: ItemTotal) -> String {
        valueText(item.primaryValue(useRate: settings.isEnableRate))
    }

    private func valueText(_ value: Float) -> String {
        if settings.isEnableRate {
            return "$ \(String(format: "%.2f", value))"
        }

        return "\(String(format: "%.0f", value)) MIN"
    }

    private var ratioSlices: [RatioSlice] {
        [
            RatioSlice(title: "SaveTime", value: max(summary.saveTotal, 0), color: settings.themeColor(isSave: true)),
            RatioSlice(title: "KillTime", value: max(summary.killTotal, 0), color: settings.themeColor(isSave: false))
        ].filter { $0.value > 0 }
    }

    @ViewBuilder
    private func customRangeView() -> some View {
        NavigationStack {
            Form {
                Section("最近天数") {
                    TextField("天数", text: $customDaysText)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                    Text("请输入 1 到 3650 之间的天数。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("自定义范围")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showCustomRange = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        applyCustomRange()
                    }
                    .disabled(parsedCustomDays == nil)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 320, minHeight: 180)
#endif
    }

    private var parsedCustomDays: Int? {
        guard let days = Int(customDaysText.trimmingCharacters(in: .whitespacesAndNewlines)),
              (1...3650).contains(days) else {
            return nil
        }
        return days
    }

    private func applyCustomRange() {
        guard let days = parsedCustomDays else {
            return
        }
        customDays = days
        selectedRange = .recentDays(days)
        showCustomRange = false
    }
}

private extension AnalyticsDateRange {
    var isCustomRecentDays: Bool {
        guard case let .recentDays(days) = self else {
            return false
        }
        return days != 7 && days != 30
    }
}

private struct RatioSlice: Identifiable {
    let title: String
    let value: Float
    let color: Color

    var id: String { title }
}

private struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    let save = BankItem(name: "Reading", isSave: true, rate: 1.2)
    save.logs = [
        ItemLog(bankItem: save, begin: Date().minus(2, component: .hour), end: Date().minus(1, component: .hour))
    ]
    let kill = BankItem(name: "Scrolling", isSave: false)
    kill.logs = [
        ItemLog(bankItem: kill, begin: Date().minus(4, component: .hour), end: Date().minus(3, component: .hour))
    ]

    return GlobalStatsView(items: [save, kill])
        .environmentObject(AppSetting())
}
