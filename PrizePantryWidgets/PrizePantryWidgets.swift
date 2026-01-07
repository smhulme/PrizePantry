// PrizePantryWidgets.swift
import WidgetKit
import SwiftUI
import ActivityKit

struct PrizePantryActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrizePantryActivityAttributes.self) { context in
            // Lock Screen Appearance
            VStack {
                Text("Screen Time Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .font(.system(size: 32, weight: .bold).monospacedDigit())
                    .foregroundStyle(.blue)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.blue)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View (Long Press)
                DynamicIslandExpandedRegion(.leading) {
                    Label("Time", systemImage: "hourglass")
                        .foregroundStyle(.blue)
                        .padding(.leading)
                }
                DynamicIslandExpandedRegion(.trailing) {

                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar or status
                    ProgressView(timerInterval: Date.now...context.state.endTime, countsDown: true)
                        .tint(.blue)
                        .padding([.leading, .trailing, .bottom])
                }
            } compactLeading: {
                // LEAD (Left side) - Hourglass icon
                Image(systemName: "hourglass")
                    .foregroundStyle(.blue)
                    .padding(.leading, 4) // Tiny adjustment to bring it closer
            } compactTrailing: {
                // TRAIL (Right side) - Timer
                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.caption2) // Use caption2 to keep the height profile low
                    .foregroundStyle(.blue)
                    .padding(.trailing, 4) // Tiny adjustment to remove end gap
            } minimal: {
                // This is used when another app also has a live activity.
                // It's the smallest possible circular representation.
                Image(systemName: "hourglass")
                    .foregroundStyle(.blue)
            }
        }
    }
}

