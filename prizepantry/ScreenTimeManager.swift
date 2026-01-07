import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

// Definitions must match exactly in the Extension
extension DeviceActivityName {
    static let unlockSession = DeviceActivityName("unlockSession")
}

extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var activitySelection = FamilyActivitySelection()
    // Published property so Views can react to changes in the end time
    @Published var sessionEndTime: Date?
    
    private let store = ManagedSettingsStore(named: .lockedApps)
    private let center = DeviceActivityCenter()
    
    // ⚠️ IMPORTANT: This must match the App Group ID in your entitlements exactly
    let appGroupID = "group.com.prizepantry.tokentime"
    
    init() {
        let defaults = UserDefaults(suiteName: appGroupID)
        
        // Load saved apps from the shared App Group
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
        
        // Load saved session end time (restore timer on app restart)
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
        print("🔒 Apps Locked")
    }
    
    // 3. The "Unlock" with Stacking Logic
    func unlockApps(forMinutes minutes: Int) {
        let defaults = UserDefaults(suiteName: appGroupID)
        let now = Date()
        
        // A. Calculate new end time (Stacking Logic)
        var newEndTime: Date
        
        if let currentEnd = sessionEndTime, currentEnd > now {
            // If time remains, add to the EXISTING end time
            newEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: currentEnd)!
        } else {
            // Otherwise, start from NOW
            newEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        }
        
        // Update State and Storage
        self.sessionEndTime = newEndTime
        defaults?.set(newEndTime, forKey: "SessionEndTime")
        
        // B. Unlock immediately
        store.clearAllSettings()
        print("🔓 Apps Unlocked until \(newEndTime)")
        
        // C. Stop any existing timer so we can reschedule
        center.stopMonitoring([.unlockSession])
        
        // D. Create the schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: newEndTime),
            repeats: false,
            warningTime: nil
        )
        
        // Start monitoring. When this schedule ends, the Extension wakes up.
        do {
            try center.startMonitoring(.unlockSession, during: schedule)
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}
