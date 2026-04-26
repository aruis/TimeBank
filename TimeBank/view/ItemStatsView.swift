//
//  ItemStatsView.swift
//  TimeBank
//
//  Created by Codex on 2026/4/26.
//

import SwiftUI

struct ItemStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSetting

    let item: BankItem

    private var summary: ItemAnalyticsSummary {
        AnalyticsAggregator.itemSummary(item: item)
    }

    private var heatmapDays: [HeatmapDay] {
        AnalyticsAggregator.yearHeatmap(item: item)
    }

    private var itemColor: Color {
        settings.themeColor(isSave: item.isSave)
    }

    private let heatmapCellSize: CGFloat = 12
    private let heatmapCellSpacing: CGFloat = 4

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summarySection()
                    heatmapSection()
                }
                .padding()
            }
            .navigationTitle(item.name)
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 520, minHeight: 540)
#endif
    }

    @ViewBuilder
    private func summarySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("概览")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                ItemStatTile(title: "总计", value: "\(summary.totalMinutes) MIN", color: itemColor)
                ItemStatTile(title: "记录数", value: "\(summary.logCount)", color: itemColor)
                ItemStatTile(title: "活跃天数", value: "\(summary.activeDays)", color: itemColor)
                ItemStatTile(title: "最近记录", value: lastActivityText, color: itemColor)
            }
        }
    }

    @ViewBuilder
    private func heatmapSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("过去一年")
                    .font(.headline)
                Spacer()
                heatmapLegend()
            }

            ScrollViewReader { proxy in
                HStack(alignment: .top, spacing: 8) {
                    weekdayLabels()

                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            monthLabels()
                            heatmapGrid()
                        }
                        .padding(.vertical, 2)
                    }
                    .onAppear {
                        scrollToLatestDay(proxy)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    @ViewBuilder
    private func monthLabels(calendar: Calendar = .current) -> some View {
        let weeks = heatmapWeeks(calendar: calendar)
        let labels = monthLabelEntries(in: weeks, calendar: calendar)

        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: heatmapContentWidth(forWeekCount: weeks.count), height: 14)

            ForEach(labels) { label in
                Text(label.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: heatmapColumnOffset(forWeekAt: label.weekIndex))
            }
        }
    }

    @ViewBuilder
    private func weekdayLabels(calendar: Calendar = .current) -> some View {
        VStack(alignment: .trailing, spacing: heatmapCellSpacing) {
            Color.clear
                .frame(width: 16, height: 18)

            ForEach(0..<7, id: \.self) { index in
                Text(weekdayLabel(forRow: index, calendar: calendar))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: heatmapCellSize, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private func heatmapGrid(calendar: Calendar = .current) -> some View {
        let weeks = heatmapWeeks(calendar: calendar)

        HStack(alignment: .top, spacing: heatmapCellSpacing) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                VStack(spacing: heatmapCellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let day = weeks[weekIndex][dayIndex]
                        heatmapCell(day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func heatmapCell(_ day: HeatmapDay?) -> some View {
        if let day {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(heatmapColor(level: day.level))
                .frame(width: heatmapCellSize, height: heatmapCellSize)
                .id(day.id)
                .accessibilityLabel(Text(accessibilityText(for: day)))
        } else {
            Color.clear
                .frame(width: heatmapCellSize, height: heatmapCellSize)
        }
    }

    @ViewBuilder
    private func heatmapLegend() -> some View {
        HStack(spacing: 4) {
            ForEach(0..<AnalyticsAggregator.heatmapLevelCount, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(heatmapColor(level: level))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var lastActivityText: String {
        guard let lastActivity = summary.lastActivity else {
            return "-"
        }

        return lastActivity.formatted(date: .abbreviated, time: .omitted)
    }

    private func paddedHeatmapDays(calendar: Calendar = .current) -> [HeatmapDay?] {
        let days = heatmapDays
        guard let firstDay = days.first?.date else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leadingEmptyDays) + days.map(Optional.some)
    }

    private func heatmapWeeks(calendar: Calendar = .current) -> [[HeatmapDay?]] {
        let paddedDays = paddedHeatmapDays(calendar: calendar)
        guard !paddedDays.isEmpty else {
            return []
        }

        var weeks: [[HeatmapDay?]] = []
        var index = 0
        while index < paddedDays.count {
            var week = Array(paddedDays[index..<min(index + 7, paddedDays.count)])
            if week.count < 7 {
                week += Array(repeating: nil, count: 7 - week.count)
            }
            weeks.append(week)
            index += 7
        }
        return weeks
    }

    private func heatmapContentWidth(forWeekCount weekCount: Int) -> CGFloat {
        guard weekCount > 0 else {
            return 0
        }

        return CGFloat(weekCount) * heatmapCellSize + CGFloat(weekCount - 1) * heatmapCellSpacing
    }

    private func heatmapColumnOffset(forWeekAt index: Int) -> CGFloat {
        CGFloat(index) * (heatmapCellSize + heatmapCellSpacing)
    }

    private func monthLabelEntries(in weeks: [[HeatmapDay?]], calendar: Calendar) -> [HeatmapMonthLabel] {
        let minimumLabelGapInWeeks = 3
        var entries: [HeatmapMonthLabel] = []

        for index in weeks.indices {
            guard let firstDateInWeek = weeks[index].compactMap(\.?.date).first else {
                continue
            }

            if index > 0,
               let previousDate = weeks[index - 1].compactMap(\.?.date).first,
               calendar.component(.month, from: previousDate) == calendar.component(.month, from: firstDateInWeek) {
                continue
            }

            let entry = HeatmapMonthLabel(
                weekIndex: index,
                title: "\(calendar.component(.month, from: firstDateInWeek))月"
            )

            if let previousEntry = entries.last,
               entry.weekIndex - previousEntry.weekIndex < minimumLabelGapInWeeks {
                entries[entries.count - 1] = entry
            } else {
                entries.append(entry)
            }
        }

        return entries
    }

    private func weekdayLabel(forRow row: Int, calendar: Calendar) -> String {
        let weekday = ((calendar.firstWeekday - 1 + row) % 7) + 1
        switch weekday {
        case 2:
            return "一"
        case 4:
            return "三"
        case 6:
            return "五"
        default:
            return ""
        }
    }

    private func heatmapColor(level: Int) -> Color {
        guard level > 0 else {
            return Color.secondary.opacity(0.16)
        }

        let opacity = 0.22 + (Double(level) / Double(AnalyticsAggregator.heatmapLevelCount - 1)) * 0.68
        return itemColor.opacity(opacity)
    }

    private func accessibilityText(for day: HeatmapDay) -> String {
        let date = day.date.formatted(date: .abbreviated, time: .omitted)
        return "\(date)，\(day.minutes) 分钟"
    }

    private func scrollToLatestDay(_ proxy: ScrollViewProxy) {
        guard let latestDay = heatmapDays.last else {
            return
        }

        DispatchQueue.main.async {
            proxy.scrollTo(latestDay.id, anchor: .trailing)
        }
    }
}

private struct HeatmapMonthLabel: Identifiable {
    let weekIndex: Int
    let title: String

    var id: Int {
        weekIndex
    }
}

private struct ItemStatTile: View {
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
    let item = BankItem(name: "Reading", isSave: true)
    item.logs = [
        ItemLog(bankItem: item, begin: Date().minus(2, component: .day), end: Date().minus(2, component: .day).plus(45, component: .minute)),
        ItemLog(bankItem: item, begin: Date().minus(7, component: .day), end: Date().minus(7, component: .day).plus(25, component: .minute))
    ]

    return ItemStatsView(item: item)
        .environmentObject(AppSetting())
}
