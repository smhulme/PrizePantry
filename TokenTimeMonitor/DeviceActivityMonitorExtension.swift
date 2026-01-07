import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

extension DeviceActivityName {
    static let dailySession = DeviceActivityName("dailySession")
}

extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

extension DeviceActivityEvent.Name {
    static let usageLimit = DeviceActivityEvent.Name("usageLimit")
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore(named: .lockedApps)
    let appGroupID = "group.com.prizepantry.tokentime"
    
    // ✅ 1. Interval Start (New Day)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .dailySession {
            // New day has started.
            // Reset allowance in UserDefaults
            let defaults = UserDefaults(suiteName: appGroupID)
            defaults?.set(0, forKey: "cumulativeAllowance")
            
            // Lock apps immediately (allowance is 0)
            lockEverything()
        }
    }
    
    // ✅ 2. Usage Limit Reached
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        if activity == .dailySession && event == .usageLimit {
            lockEverything()
        }
    }
    
    // Safety: Lock on End
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity == .dailySession {
            lockEverything()
        }
    }
    
    private func lockEverything() {
        let defaults = UserDefaults(suiteName: appGroupID)
        
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens
            
            print("Extension: Locked all apps.")
        }
    }
}
