import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

// Ensure names match
extension DeviceActivityName {
    static let unlockSession = DeviceActivityName("unlockSession")
}

extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore(named: .lockedApps)
    // REPLACE with your actual App Group ID
    let appGroupID = "group.com.prizepantry.tokentime"
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .unlockSession {
            // Unlock everything when the timer starts
            store.clearAllSettings()
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        if activity == .unlockSession {
            // RE-LOCK THE APPS
            // Read from Shared App Group Defaults
            let defaults = UserDefaults(suiteName: appGroupID)
            
            if let data = defaults?.data(forKey: "SavedActivitySelection"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                
                store.shield.applications = selection.applicationTokens
                store.shield.webDomains = selection.webDomainTokens
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            }
        }
    }
}
