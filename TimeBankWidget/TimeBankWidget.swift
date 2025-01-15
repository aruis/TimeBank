//
//  TimeBankWidget.swift
//  TimeBankWidget
//
//  Created by Rui Liu on 2024/11/30.
//

import WidgetKit
import ActivityKit
import SwiftUI

struct TimerActivityView: View {
    var context: ActivityViewContext<TimerActivityAttributes>
    @State private var timeRemaining:Int = 0

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

            Text(context.attributes.start,style: .timer)
                .font(.largeTitle.monospacedDigit())
                .fontWeight(.regular)
                .multilineTextAlignment(.trailing)
                .contentTransition(.numericText(value: Double( timeRemaining)))


        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundStyle(Color.white)
        .activityBackgroundTint(.pig)

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
                            Text(context.attributes.start,style: .timer)
                                .font(.title.monospacedDigit())
                                .fontWeight(.regular)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.pig)

                        }
                        .frame(maxHeight: .infinity,alignment: .trailing)
                    }
                },
                compactLeading: {
                    Text(context.attributes.name)                },
                compactTrailing: {
                    Text(context.attributes.start,style: .timer)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.pig)
                },
                minimal: {
                    Image("icon")
                        .resizable()
//                        .frame(width: 50, height: 50)
                        .scaledToFill()
//                        .scaledToFit()
//                    Text(context.attributes.name.prefix(1))
//                        .foregroundStyle(.pig)
                }
            )
        }
        .supportedFamilies([.accessoryRectangular])


    }


}

@available(iOSApplicationExtension 16.2, *)
struct TimerActivityView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerActivityAttributes(name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(timeRemaining: 123),
                    viewKind: .content
                )

            TimerActivityAttributes(name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(timeRemaining:123),
                    viewKind: .dynamicIsland(.expanded)
                )

            TimerActivityAttributes(name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(timeRemaining: 123),
                    viewKind: .dynamicIsland(.compact)
                )

            TimerActivityAttributes(name: "Focus Timer",start: .now)
                .previewContext(
                    TimerActivityAttributes.ContentState(timeRemaining: 123),
                    viewKind: .dynamicIsland(.minimal)
                )
        }
    }
}

