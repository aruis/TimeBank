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

    var body: some View {
        VStack(spacing: 8) {
            // Name Title
            Text(context.attributes.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(8)

            // Timer Text
            Text(context.state.start, style: .timer)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
        )
        .padding()
    }
}

struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.bottom) {
                        HStack(spacing: 8) {
                            // App Logo
                            Image("AppIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())

                            // Expanded View Text
                            VStack(alignment: .leading) {
                                Text("Timer Active")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Elapsed time:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Timer
                            Text(context.state.start, style: .timer)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                },
                compactLeading: {
                    // Compact Leading with Logo
                    Image("AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                },
                compactTrailing: {
                    // Timer in Compact Trailing
                    Text(context.state.start, style: .timer)
                        .font(.caption2)
                        .foregroundColor(.green)
                },
                minimal: {
                    // Minimal View with Logo
                    Image("AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                }
            )
        }
    }
}
