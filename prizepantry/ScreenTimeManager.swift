import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import ActivityKit

// ✅ 1. ADD THESE EXTENSIONS BACK AT THE TOP
extension DeviceActivityName {
    static let unlockSession = DeviceActivityName("unlockSession")
}

extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

// ✅ 2. Your ScreenTimeManager Class
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var activitySelection = FamilyActivitySelection()
    @Published var sessionEndTime: Date?
    
    // Settings for the Child
    @AppStorage("enableLiveActivity", store: UserDefaults(suiteName: "group.com.prizepantry.tokentime"))
    var enableLiveActivity: Bool = true
    
    private let store = ManagedSettingsStore(named: .lockedApps)
    private let center = DeviceActivityCenter()
    
    // Activity State
    private var currentActivity: Activity<PrizePantryActivityAttributes>?
    
    // ⚠️ Ensure this ID matches your App Group exactly
    let appGroupID = "group.com.prizepantry.tokentime"
    
    init() {
        let defaults = UserDefaults(suiteName: appGroupID)
        
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
        
        if let savedTime = defaults?.object(forKey: "SessionEndTime") as? Date {
            if savedTime > Date() {
                self.sessionEndTime = savedTime
            } else {
                self.sessionEndTime = nil
            }
        }
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Authorization Failed: \(error)")
            }
        }
    }

    func saveSelectionAndLock() {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = try? JSONEncoder().encode(activitySelection) {
            defaults?.set(data, forKey: "SavedActivitySelection")
        }
        blockApps()
    }
    
    func blockApps() {
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
        
        // Stop any running activity when we block apps
        stopLiveActivity()
    }
    
    func unlockApps(forMinutes minutes: Int) {
        let defaults = UserDefaults(suiteName: appGroupID)
        let now = Date()
        
        var newEndTime: Date
        if let currentEnd = sessionEndTime, currentEnd > now {
            newEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: currentEnd)!
        } else {
            newEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        }
        
        self.sessionEndTime = newEndTime
        defaults?.set(newEndTime, forKey: "SessionEndTime")
        
        store.clearAllSettings()
        
        // Start Live Activity
        startLiveActivity(endTime: newEndTime)
        
        center.stopMonitoring([.unlockSession])
        
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: newEndTime),
            repeats: false,
            warningTime: nil
        )
        
        do {
            try center.startMonitoring(.unlockSession, during: schedule)
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
    // MARK: - Live Activity Logic
    private func startLiveActivity(endTime: Date) {
        guard enableLiveActivity, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        stopLiveActivity()
        
        let attributes = PrizePantryActivityAttributes(name: "Screen Time")
        let state = PrizePantryActivityAttributes.ContentState(endTime: endTime)
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endTime),
                pushType: nil
            )
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func stopLiveActivity() {
        Task {
            guard let activity = currentActivity else { return }
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
