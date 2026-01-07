// File: TokenTimeReport/TokenTimeReport.swift
import DeviceActivity
import SwiftUI
import FamilyControls

// 1. Define the custom model structure
extension DeviceActivityReport {
    struct ApplicationActivity: Identifiable {
        let id: String
        let displayName: String
        let appID: String?
        let totalActivityDuration: TimeInterval
        let activities: [ApplicationActivity]
    }
}

// 2. The @main entry point for the extension
@main
struct TokenTimeReport: DeviceActivityReportScene {
    // Define the context (Must match the one in DeviceActivityConstants.swift)
    let context: DeviceActivityReport.Context = .timeRemaining
    
    // Define the content closure
    let content: (DeviceActivityReport.ApplicationActivity) -> TimeRemainingView
    
    // 3. Configure the data to display
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> DeviceActivityReport.ApplicationActivity {
        var totalDuration: TimeInterval = 0
        
        // Outer loop is async (iterating over devices/users)
        for await activity in data {
            // FIX: Inner loop is ALSO async. You must use 'for await' here too.
            for await segment in activity.activitySegments {
                totalDuration += segment.totalActivityDuration
            }
        }
        
        // Return our custom model to the view
        return DeviceActivityReport.ApplicationActivity(
            id: "root",
            displayName: "Total",
            appID: nil,
            totalActivityDuration: totalDuration,
            activities: []
        )
    }
}

// 4. The SwiftUI View that draws the usage
struct TimeRemainingView: View {
    let appGroupID = "group.com.prizepantry.tokentime"
    
    // This view receives the data model created in makeConfiguration above
    var activityReport: DeviceActivityReport.ApplicationActivity
    
    var body: some View {
        let defaults = UserDefaults(suiteName: appGroupID)
        let limit = defaults?.integer(forKey: "cumulativeAllowance") ?? 0
        
        // Get total usage from the passed report
        let totalUsage = activityReport.totalActivityDuration
        let usageMinutes = Int(totalUsage / 60)
        
        // Calculate remaining time
        let remaining = max(0, limit - usageMinutes)
        
        HStack {
            VStack(alignment: .leading) {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if limit == 0 {
                    Text("No Time Bought")
                        .font(.headline)
                        .foregroundStyle(.red)
                } else if remaining == 0 {
                    Text("Time's Up!")
                        .font(.headline)
                        .foregroundStyle(.red)
                } else {
                    Text("\(remaining) mins")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
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
                    .foregroundColor(remaining < 5 ? .red : .blue)
                    .rotationEffect(Angle(degrees: 270.0))
            }
            .frame(width: 50, height: 50)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
