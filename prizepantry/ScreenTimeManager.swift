import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

// Name for our device activity schedule
extension DeviceActivityName {
    static let unlockSession = DeviceActivityName("unlockSession")
}

// Name for our managed settings store
extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    // The pool of apps the parent/child selected to be restricted
    @Published var activitySelection = FamilyActivitySelection()
    
    // Store used to apply the shields
    private let store = ManagedSettingsStore(named: .lockedApps)
    private let center = DeviceActivityCenter()
    
    // REPLACE with your actual App Group ID from Step 1
    let appGroupID = "group.com.prizepantry.tokentime"
    
    init() {
        // Load saved selection from App Group defaults
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
    }
    
    // 1. Request Permission
    // Updated to handle .individual (if testing on parent device) or .child
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .child)
                print("Screen Time Authorization Granted")
            } catch {
                print("Screen Time Authorization Failed: \(error)")
            }
        }
    }
    
    // 2. Save the list of apps and Lock them immediately
    func saveSelectionAndLock() {
        // Save to Shared App Group
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = try? JSONEncoder().encode(activitySelection) {
            defaults?.set(data, forKey: "SavedActivitySelection")
        }
        
        // Apply restrictions immediately (Block the apps)
        blockApps()
    }
    
    // Helper to apply shields
    func blockApps() {
        store.shield.applications = activitySelection.applicationTokens
        store.shield.webDomains = activitySelection.webDomainTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        print("Apps locked.")
    }
    
    // 3. Buy Time (Unlock for X minutes)
    func unlockApps(forMinutes minutes: Int) {
        // 1. Clear the shields immediately
        store.clearAllSettings()
        print("Apps unlocked for \(minutes) minutes.")
        
        // 2. Stop any existing schedules so we don't have overlapping timers
        center.stopMonitoring([.unlockSession])
        
        // 3. Schedule the "Relock" event
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: Calendar.current.component(.hour, from: now),
                                          minute: Calendar.current.component(.minute, from: now),
                                          second: Calendar.current.component(.second, from: now)),
            intervalEnd: DateComponents(hour: Calendar.current.component(.hour, from: end),
                                        minute: Calendar.current.component(.minute, from: end),
                                        second: Calendar.current.component(.second, from: end)),
            repeats: false
        )
        
        do {
            try center.startMonitoring(.unlockSession, during: schedule)
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}
