// File: TokenTimeReport/TokenTimeReport. swift
import DeviceActivity
import SwiftUI
import FamilyControls

// 1. Define the custom model structure
extension DeviceActivityReport {
    struct ApplicationActivity: Identifiable {
        let id: String
        let displayName: String
        let appID:  String?
        let totalActivityDuration: TimeInterval
        let activities: [ApplicationActivity]
    }
}

// 2. The @main entry point for the extension
@main
struct TokenTimeReportExtension: DeviceActivityReportExtension {
    var body:  some DeviceActivityReportScene {
        // Scene 1: Token Time (Time Remaining)
        TokenTimeReport { activity in
            TimeRemainingView(activityReport: activity)
        }
        
        // Scene 2: Total Activity
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}

// 3. The Report Scene Configuration
struct TokenTimeReport:  DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .timeRemaining
    let content: (DeviceActivityReport.ApplicationActivity) -> TimeRemainingView
    
    // ✅ FIXED: Only count usage for the filtered apps
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> DeviceActivityReport.ApplicationActivity {
        var totalDuration:  TimeInterval = 0
        
        // The data is already filtered by the DeviceActivityFilter passed from ChildDashboardView
        // So we can safely sum all segments here
        for await activity in data {
            for await segment in activity.activitySegments {
                // Sum up all app activities in this segment
                for await appActivity in segment.categories {
                    totalDuration += appActivity.totalActivityDuration
                }
            }
        }
        
        return DeviceActivityReport.ApplicationActivity(
            id: "root",
            displayName: "Total",
            appID: nil,
            totalActivityDuration: totalDuration,
            activities: []
        )
    }
}

// 5. The SwiftUI View
struct TimeRemainingView: View {
    let appGroupID = "group.com.prizepantry.tokentime"
    var activityReport: DeviceActivityReport.ApplicationActivity
    
    var body: some View {
        // ✅ MOVED: Calculate everything outside the view builder
        let defaults = UserDefaults(suiteName: appGroupID)
        let limit = defaults?.integer(forKey: "cumulativeAllowance") ?? 0
        
        // Get total usage from the passed report (in seconds)
        let totalUsage = activityReport.totalActivityDuration
        let usageMinutes = Int(totalUsage / 60)
        
        // Calculate remaining time
        let remaining = max(0, limit - usageMinutes)
        
        // ✅ Use onAppear for debugging instead of direct print
        return HStack {
            VStack(alignment: .leading) {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if limit == 0 {
                    Text("No Time Bought")
                        . font(.headline)
                        . foregroundStyle(.red)
                } else if remaining == 0 {
                    Text("Time's Up!")
                        .font(. headline)
                        .foregroundStyle(.red)
                } else {
                    Text("\(remaining) mins")
                        .font(.system(size: 34, weight: .bold, design: . rounded))
                        .foregroundStyle(.blue)
                }
            }
            Spacer()
            
            // Circular Progress Indicator
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: limit > 0 ? CGFloat(remaining) / CGFloat(limit) : 0)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .foregroundColor(remaining < 5 ? .red : . blue)
                    .rotationEffect(Angle(degrees: 270.0))
            }
            .frame(width: 50, height: 50)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear {
            // ✅ Debugging moved here
            print("📊 Report Update - Limit: \(limit)m, Used: \(usageMinutes)m, Remaining: \(remaining)m")
        }
    }
}
