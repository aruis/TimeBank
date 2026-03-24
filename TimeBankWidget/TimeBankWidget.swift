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

private func formattedDuration(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60

    if hours > 0 {
        return String(format: "%dh %02dm", hours, minutes)
    }

    return String(format: "%dm", minutes)
}

private func activityStatusText(isStale: Bool) -> LocalizedStringResource {
    isStale ? "Needs Review" : "Interrupted"
}

private struct RunningTimerText: View {
    let start: Date

    var body: some View {
        Text(start, style: .timer)
            .font(.system(size: 34, weight: .medium, design: .rounded).monospacedDigit())
            .multilineTextAlignment(.trailing)
            .invalidatableContent()
    }
}

private struct InterruptedSummaryView: View {
    let seconds: Int
    let isStale: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formattedDuration(seconds))
                .font(.headline.monospacedDigit())
            Text(activityStatusText(isStale: isStale))
                .font(.caption)
                .opacity(0.78)
        }
    }
}

struct TimerActivityView: View {
    var context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TimeBank")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                Text(context.attributes.name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if context.isStale {
                    Text(activityStatusText(isStale: true))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 10)

            Group {
                if context.state.sessionState == .running {
                    RunningTimerText(start: context.attributes.start)
                } else {
                    InterruptedSummaryView(seconds: context.state.recordedSeconds, isStale: context.isStale)
                }
            }
            .frame(minWidth: 108, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundStyle(Color.white)
        .activityBackgroundTint(Color.pig.opacity(0.78))
        .widgetURL(activityURL(for: context))

    }
}

struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerActivityView(context: context)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.leading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.attributes.name)
                                .font(.headline)
                                .lineLimit(2)
                        }
                        .frame(maxHeight: .infinity)
                    }

                    DynamicIslandExpandedRegion(.trailing) {
                        VStack(alignment: .trailing, spacing: 4) {
                            if context.state.sessionState == .running {
                                Text(context.attributes.start, style: .timer)
                                    .font(.title2.monospacedDigit())
                                    .fontWeight(.medium)
                                    .foregroundStyle(.pig)
                            } else {
                                InterruptedSummaryView(seconds: context.state.recordedSeconds, isStale: context.isStale)
                                    .foregroundStyle(.pig)
                            }

                            if context.isStale {
                                Text(activityStatusText(isStale: true))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minWidth: 92)
                        .frame(maxHeight: .infinity,alignment: .trailing)
                    }
                },
                compactLeading: {
                    if context.state.sessionState == .running {
                        Image(systemName: "timer")
                            .foregroundStyle(.pig)
                    } else {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.orange)
                    }
                },
                compactTrailing: {
                    if context.state.sessionState == .running {
                        Text(context.attributes.start, style: .timer)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 45)
                            .foregroundStyle(.pig)
                    } else {
                        Text(formattedDuration(context.state.recordedSeconds))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                },
                minimal: {
                    if context.state.sessionState == .running {
                        Image(systemName: "timer")
                            .foregroundStyle(.pig)
                    } else {
                        Image(systemName: "pause.fill")
                            .foregroundStyle(.orange)
                    }
                }
            )
            .widgetURL(activityURL(for: context))
            .keylineTint(context.state.sessionState == .running ? .pig : .orange)
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
