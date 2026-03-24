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

struct TimerActivityView: View {
    var context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading,spacing: 0){
                HStack{
                    Text("TimeBank")
                       .font(.footnote)
                }
                Text(context.attributes.name)
                    .font(.headline)
                    .fixedSize()
            }


            Spacer().frame(maxWidth: .infinity)

            if context.state.sessionState == .running {
                Text(context.attributes.start, style: .timer)
                    .font(.largeTitle.monospacedDigit())
                    .fontWeight(.regular)
                    .multilineTextAlignment(.trailing)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDuration(context.state.recordedSeconds))
                        .font(.headline.monospacedDigit())
                    Text("Interrupted")
                        .font(.caption)
                        .opacity(0.85)
                }
            }


        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundStyle(Color.white)
        .activityBackgroundTint(.pig)
        .widgetURL(activityURL(for: context))

    }
}

struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerActivityView(context: context)
//                .tint(.pig)
//                .activityBackgroundTint(.pig.opacity(0))
        } dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.leading) {
                        VStack(alignment: .leading,spacing: 0){
                            Text("TimeBank")
                                .font(.caption2)
                                .fixedSize()
                            Text(context.attributes.name)
                                .font(.title3)
                                .fixedSize()
                        }
                        .frame(maxHeight: .infinity)
                    }

                    DynamicIslandExpandedRegion(.trailing) {
                        VStack(alignment: .center){
                            if context.state.sessionState == .running {
                                Text(context.attributes.start, style: .timer)
                                    .font(.title.monospacedDigit())
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(.pig)
                            } else {
                                Text(formattedDuration(context.state.recordedSeconds))
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(.pig)
                                Text("Interrupted")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                        }
                        .frame(maxHeight: .infinity,alignment: .trailing)
                    }
                },
                compactLeading: {
//                    Text(context.attributes.name)
                    Image("icon_a")
                        .resizable()
                        .scaledToFit()
//                        .padding(.leading,4)
                },
                compactTrailing: {
                    if context.state.sessionState == .running {
                        Text(context.attributes.start, style: .timer)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 45)
                            .foregroundStyle(.pig)
                    } else {
                        Image(systemName: "pause.fill")
                            .foregroundStyle(.pig)
                    }
                },
                minimal: {
                    if context.state.sessionState == .running {
                        Image("icon_a")
                            .resizable()
                            .scaledToFill()
                            .padding(2)
                    } else {
                        Image(systemName: "pause.fill")
                            .foregroundStyle(.pig)
                    }
                }
            )
            .widgetURL(activityURL(for: context))
        }
        .supportedFamilies([.accessoryRectangular])


    }


}

@available(iOSApplicationExtension 16.2, *)
struct TimerActivityView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerActivityAttributes(itemID: UUID().uuidString, name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(recordedSeconds: 123, sessionState: .running),
                    viewKind: .content
                )

            TimerActivityAttributes(itemID: UUID().uuidString, name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(recordedSeconds: 123, sessionState: .running),
                    viewKind: .dynamicIsland(.expanded)
                )

            TimerActivityAttributes(itemID: UUID().uuidString, name: "Focus Timer",start: .now.addingTimeInterval(-10000))
                .previewContext(
                    TimerActivityAttributes.ContentState(recordedSeconds: 123, sessionState: .running),
                    viewKind: .dynamicIsland(.compact)
                )

            TimerActivityAttributes(itemID: UUID().uuidString, name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(recordedSeconds: 123, sessionState: .interrupted),
                    viewKind: .dynamicIsland(.minimal)
                )
        }
    }
}
