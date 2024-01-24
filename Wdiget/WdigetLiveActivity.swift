//
//  WdigetLiveActivity.swift
//  Wdiget
//
//  Created by 牧云踏歌 on 2024/1/19.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WdigetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WdigetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WdigetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WdigetAttributes {
    fileprivate static var preview: WdigetAttributes {
        WdigetAttributes(name: "World")
    }
}

extension WdigetAttributes.ContentState {
    fileprivate static var smiley: WdigetAttributes.ContentState {
        WdigetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WdigetAttributes.ContentState {
         WdigetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WdigetAttributes.preview) {
   WdigetLiveActivity()
} contentStates: {
    WdigetAttributes.ContentState.smiley
    WdigetAttributes.ContentState.starEyes
}
