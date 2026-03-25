//
//  TimeBankWidget.swift
//  TimeBankWidget
//
//  Created by Rui Liu on 2024/11/30.
//

import WidgetKit
import ActivityKit
import SwiftUI

private func activityURL(for context: ActivityViewContext<TimerActivityAttributes>) -> URL? {
    URL(string: "timebank://item/\(context.attributes.itemID)")
}

private func sessionAccentColor(_ sessionState: TimerActivityAttributes.ContentState.SessionState) -> Color {
    sessionState == .running ? .pig : .orange
}

private func activityBackgroundColor(
    sessionState: TimerActivityAttributes.ContentState.SessionState,
    isStale: Bool
) -> Color {
    if isStale {
        return Color.black.opacity(0.88)
    }

    return sessionState == .running ? Color.pig.opacity(0.88) : Color(red: 0.23, green: 0.16, blue: 0.08)
}

private func formattedDuration(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60

    if hours > 0 {
        return String(format: "%dh %02dm", hours, minutes)
    }

    return String(format: "%dm", minutes)
}

private func activityStatusText(
    sessionState: TimerActivityAttributes.ContentState.SessionState,
    isStale: Bool
) -> LocalizedStringResource {
    if isStale {
        return "Needs Review"
    }

    return sessionState == .running ? "Running" : "Interrupted"
}

private struct RunningTimerText: View {
    let start: Date

    var body: some View {
        Text(start, style: .timer)
            .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
            .multilineTextAlignment(.trailing)
            .invalidatableContent()
    }
}

private struct ActivityPrimaryValueView: View {
    let start: Date
    let seconds: Int
    let sessionState: TimerActivityAttributes.ContentState.SessionState

    var body: some View {
        if sessionState == .running {
            RunningTimerText(start: start)
        } else {
            Text(formattedDuration(seconds))
                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
        }
    }
}

private struct ExpandedActivityValueView: View {
    let start: Date
    let seconds: Int
    let sessionState: TimerActivityAttributes.ContentState.SessionState
    let accent: Color

    var body: some View {
        if sessionState == .running {
            Text(start, style: .timer)
                .font(.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(accent)
                .multilineTextAlignment(.trailing)
                .invalidatableContent()
        } else {
            Text(formattedDuration(seconds))
                .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(accent)
        }
    }
}

private struct CompactGlyphView: View {
    let accent: Color
    let sessionState: TimerActivityAttributes.ContentState.SessionState

    var body: some View {
        Image(systemName: sessionState == .running ? "timer" : "pause.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .frame(width: 25, height: 25)
            .background(
                Circle()
                    .fill(accent.opacity(0.14))
            )
    }
}

private struct CompactTimerText: View {
    let start: Date

    var body: some View {
        Text(start, style: .timer)
            .font(.caption.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(.pig)
            .multilineTextAlignment(.trailing)
            .frame(minWidth: 28, alignment: .trailing)
            .invalidatableContent()
    }
}

private struct CompactSummaryText: View {
    let seconds: Int

    var body: some View {
        Text(formattedDuration(seconds))
            .font(.caption2.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(.orange)
            .frame(minWidth: 28, alignment: .trailing)
    }
}

struct TimerActivityView: View {
    var context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.name)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                HStack{
                    Text("TimeBank")
                    if context.isStale || context.state.sessionState != .running {
                        Text("/")
                        Text(activityStatusText(
                            sessionState: context.state.sessionState,
                            isStale: context.isStale
                        ))
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ActivityPrimaryValueView(
                start: context.attributes.start,
                seconds: context.state.recordedSeconds,
                sessionState: context.state.sessionState
            )
            .frame(minWidth: 112, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .foregroundStyle(.white)
        .activityBackgroundTint(
            activityBackgroundColor(
                sessionState: context.state.sessionState,
                isStale: context.isStale
            )
        )
        .widgetURL(activityURL(for: context))
    }
}

struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerActivityView(context: context)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let accent = sessionAccentColor(context.state.sessionState)

            return DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.leading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(context.attributes.name)
                                .font(.headline.weight(.semibold))
                                .lineLimit(1)

                            if context.isStale || context.state.sessionState != .running {
                                Text(activityStatusText(
                                    sessionState: context.state.sessionState,
                                    isStale: context.isStale
                                ))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .leading)
                    }

                    DynamicIslandExpandedRegion(.trailing) {
                        ExpandedActivityValueView(
                            start: context.attributes.start,
                            seconds: context.state.recordedSeconds,
                            sessionState: context.state.sessionState,
                            accent: accent
                        )
                        .frame(maxHeight: .infinity, alignment: .trailing)
                    }

                    DynamicIslandExpandedRegion(.bottom) { EmptyView() }
                },
                compactLeading: {
                    CompactGlyphView(accent: accent, sessionState: context.state.sessionState)
                },
                compactTrailing: {
                    if context.state.sessionState == .running {
                        CompactTimerText(start: context.attributes.start)
                    } else {
                        CompactSummaryText(seconds: context.state.recordedSeconds)
                    }
                },
                minimal: {
                    CompactGlyphView(accent: accent, sessionState: context.state.sessionState)
                }
            )
            .widgetURL(activityURL(for: context))
            .keylineTint(context.isStale ? .yellow : accent)
        }
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview("Live Activity", as: .content, using: TimerActivityAttributes(
    itemID: UUID().uuidString,
    name: "Design Review",
    start: .now.addingTimeInterval(-1540)
)) {
    TimerActivityWidget()
} contentStates: {
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .running)
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .interrupted)
}

#Preview("Live Activity ZH", as: .content, using: TimerActivityAttributes(
    itemID: UUID().uuidString,
    name: "整理年度时间账单",
    start: .now.addingTimeInterval(-1540)
)) {
    TimerActivityWidget()
} contentStates: {
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .running)
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .interrupted)
}

#Preview("Expanded Island", as: .dynamicIsland(.expanded), using: TimerActivityAttributes(
    itemID: UUID().uuidString,
    name: "Design Review",
    start: .now.addingTimeInterval(-1540)
)) {
    TimerActivityWidget()
} contentStates: {
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .running)
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .interrupted)
}

#Preview("Expanded Island Long", as: .dynamicIsland(.expanded), using: TimerActivityAttributes(
    itemID: UUID().uuidString,
    name: "Quarterly Product Strategy Alignment Review",
    start: .now.addingTimeInterval(-1540)
)) {
    TimerActivityWidget()
} contentStates: {
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .running)
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .interrupted)
}

#Preview("Compact Island", as: .dynamicIsland(.compact), using: TimerActivityAttributes(
    itemID: UUID().uuidString,
    name: "Design Review",
    start: .now.addingTimeInterval(-1540)
)) {
    TimerActivityWidget()
} contentStates: {
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .running)
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .interrupted)
}

#Preview("Minimal Island", as: .dynamicIsland(.minimal), using: TimerActivityAttributes(
    itemID: UUID().uuidString,
    name: "Design Review",
    start: .now.addingTimeInterval(-1540)
)) {
    TimerActivityWidget()
} contentStates: {
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .running)
    TimerActivityAttributes.ContentState(recordedSeconds: 1540, sessionState: .interrupted)
}
