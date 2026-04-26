//
//  AnalyticsAggregator.swift
//  TimeBank
//
//  Created by Codex on 2026/4/26.
//

import Foundation

struct ItemTotal: Identifiable, Equatable {
    let itemID: UUID
    let name: String
    let isSave: Bool
    let minutes: Int
    let value: Float

    var id: UUID { itemID }

    func primaryValue(useRate: Bool) -> Float {
        useRate ? value : Float(minutes)
    }
}

struct AnalyticsSummary: Equatable {
    let saveTotal: Float
    let killTotal: Float
    let balance: Float
    let topSaveItems: [ItemTotal]
    let topKillItems: [ItemTotal]
}

struct ItemAnalyticsSummary: Equatable {
    let totalMinutes: Int
    let logCount: Int
    let activeDays: Int
    let lastActivity: Date?
}

struct HeatmapDay: Identifiable, Equatable {
    let date: Date
    let minutes: Int
    let level: Int

    var id: Date { date }
}

enum AnalyticsDateRange: Equatable, Identifiable {
    case all
    case currentYear
    case currentMonth
    case recentDays(Int)

    var id: String {
        switch self {
        case .all:
            return "all"
        case .currentYear:
            return "currentYear"
        case .currentMonth:
            return "currentMonth"
        case let .recentDays(days):
            return "recentDays-\(days)"
        }
    }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .currentYear:
            return "本年"
        case .currentMonth:
            return "本月"
        case let .recentDays(days):
            return "近\(days)天"
        }
    }

    func contains(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch self {
        case .all:
            return true
        case .currentYear:
            guard let interval = calendar.dateInterval(of: .year, for: now) else {
                return true
            }
            return date >= interval.start && date < interval.end
        case .currentMonth:
            guard let interval = calendar.dateInterval(of: .month, for: now) else {
                return true
            }
            return date >= interval.start && date < interval.end
        case let .recentDays(days):
            let safeDays = max(days, 1)
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
            let start = calendar.date(byAdding: .day, value: -(safeDays - 1), to: calendar.startOfDay(for: now)) ?? now
            return date >= start && date < end
        }
    }
}

enum AnalyticsAggregator {
    static let heatmapLevelCount = 5

    static func globalSummary(
        items: [BankItem],
        useRate: Bool,
        calendar: Calendar = .current,
        range: AnalyticsDateRange = .all,
        now: Date = Date()
    ) -> AnalyticsSummary {
        let totals = items.map { itemTotal($0, range: range, now: now, calendar: calendar) }
        let saveItems = sortedTopItems(
            totals.filter(\.isSave),
            useRate: useRate
        )
        let killItems = sortedTopItems(
            totals.filter { !$0.isSave },
            useRate: useRate
        )
        let saveTotal = saveItems.reduce(0) { $0 + $1.primaryValue(useRate: useRate) }
        let killTotal = killItems.reduce(0) { $0 + $1.primaryValue(useRate: useRate) }

        return AnalyticsSummary(
            saveTotal: saveTotal,
            killTotal: killTotal,
            balance: saveTotal - killTotal,
            topSaveItems: Array(saveItems.prefix(5)),
            topKillItems: Array(killItems.prefix(5))
        )
    }

    static func itemSummary(
        item: BankItem,
        calendar: Calendar = .current
    ) -> ItemAnalyticsSummary {
        let logs = item.logs ?? []
        let activeDays = Set(logs.map { calendar.startOfDay(for: $0.begin) }).count

        return ItemAnalyticsSummary(
            totalMinutes: logs.reduce(0) { $0 + $1.saveMin },
            logCount: logs.count,
            activeDays: activeDays,
            lastActivity: logs.map(\.end).max()
        )
    }

    static func yearHeatmap(
        item: BankItem,
        endingAt endDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [HeatmapDay] {
        let endDay = calendar.startOfDay(for: endDate)
        let startDay = calendar.date(byAdding: .day, value: -364, to: endDay) ?? endDay
        let dailyMinutes = dailyMinutesByBeginDay(item: item, calendar: calendar)
        let heatmapDates = (0..<365).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDay)
        }
        let maxMinutes = heatmapDates.map { dailyMinutes[$0] ?? 0 }.max() ?? 0

        return heatmapDates.map { date in
            let minutes = dailyMinutes[date] ?? 0
            return HeatmapDay(
                date: date,
                minutes: minutes,
                level: heatmapLevel(minutes: minutes, maxMinutes: maxMinutes)
            )
        }
    }

    static func dailyMinutesByBeginDay(
        item: BankItem,
        calendar: Calendar = .current
    ) -> [Date: Int] {
        (item.logs ?? []).reduce(into: [:]) { result, log in
            let day = calendar.startOfDay(for: log.begin)
            result[day, default: 0] += log.saveMin
        }
    }

    private static func itemTotal(
        _ item: BankItem,
        range: AnalyticsDateRange,
        now: Date,
        calendar: Calendar
    ) -> ItemTotal {
        let minutes = (item.logs ?? [])
            .filter { range.contains($0.begin, now: now, calendar: calendar) }
            .reduce(0) { $0 + $1.saveMin }

        return ItemTotal(
            itemID: item.id,
            name: item.name,
            isSave: item.isSave,
            minutes: minutes,
            value: Float(minutes) * item.rate
        )
    }

    private static func sortedTopItems(
        _ items: [ItemTotal],
        useRate: Bool
    ) -> [ItemTotal] {
        items
            .filter { $0.minutes > 0 }
            .sorted { lhs, rhs in
                let leftValue = lhs.primaryValue(useRate: useRate)
                let rightValue = rhs.primaryValue(useRate: useRate)

                if leftValue != rightValue {
                    return leftValue > rightValue
                }

                let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
                if nameOrder != .orderedSame {
                    return nameOrder == .orderedAscending
                }

                return lhs.itemID.uuidString < rhs.itemID.uuidString
            }
    }

    private static func heatmapLevel(minutes: Int, maxMinutes: Int) -> Int {
        guard minutes > 0, maxMinutes > 0 else {
            return 0
        }

        let ratio = Double(minutes) / Double(maxMinutes)
        return min(max(Int(ceil(ratio * Double(heatmapLevelCount - 1))), 1), heatmapLevelCount - 1)
    }
}
