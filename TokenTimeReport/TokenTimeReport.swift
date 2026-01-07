// File: TokenTimeReport/TokenTimeReport.swift
import DeviceActivity
import SwiftUI
import FamilyControls

extension DeviceActivityReport.Context {
    // Create a unique name for this report
    static let timeRemaining = Self("TimeRemaining")
}

struct TokenTimeReport: DeviceActivityReportScene {
    // Define the context we created above
    let context: DeviceActivityReport.Context = .timeRemaining
    
    // Define the content (The View)
    let content: (String) -> TimeRemainingView
    
    // Configure the data we want to fetch
    func makeConfiguration(representing date: Date) async -> DeviceActivityReportConfiguration {
        let appGroupID = "group.com.prizepantry.tokentime"
        let defaults = UserDefaults(suiteName: appGroupID)
        
        // 1. Fetch the saved selection from the Main App
        var activitySelection = FamilyActivitySelection()
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activitySelection = selection
        }
        
        // 2. Define the scope (Today)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let dateInterval = DateInterval(start: startOfDay, end: endOfDay)
        
        // 3. Create Filter (Only show usage for the apps we blocked)
        let filter = DeviceActivityFilter(
            segment: .daily(during: dateInterval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            webDomains: activitySelection.webDomainTokens
        )
        
        return DeviceActivityReportConfiguration(title: "Time Remaining", filter: filter)
    }
}

// The SwiftUI View that draws the usage
struct TimeRemainingView: View {
    let appGroupID = "group.com.prizepantry.tokentime"
    var activityReport: DeviceActivityReport.ApplicationActivity
    
    var body: some View {
        let defaults = UserDefaults(suiteName: appGroupID)
        let limit = defaults?.integer(forKey: "cumulativeAllowance") ?? 0
        
        // Calculate total duration used today for the selected apps
        let totalUsage = activityReport.totalDuration
        let usageMinutes = Int(totalUsage / 60)
        
        // Calculate remaining
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
            
            // Circular Progress
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

// Helper to sum up duration from the results
extension DeviceActivityReport.ApplicationActivity {
    var totalDuration: TimeInterval {
        // Simple recursive sum of all activities in the tree
        var duration: TimeInterval = 0
        for activity in self.activities {
            duration += activity.totalActivityDuration
        }
        return duration
    }
}
