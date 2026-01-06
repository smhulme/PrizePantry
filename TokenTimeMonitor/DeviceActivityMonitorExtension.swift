// File: TokenTimeMonitor/DeviceActivityMonitorExtension.swift
import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

// Ensure these names match ScreenTimeManager.swift exactly
extension DeviceActivityName {
    static let unlockSession = DeviceActivityName("unlockSession")
}

extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore(named: .lockedApps)
    
    // ⚠️ MUST MATCH the ID in ScreenTimeManager.swift
    let appGroupID = "group.com.prizepantry.tokentime"
    
    // Called when the "Unlock Session" starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .unlockSession {
            // Ensure apps are clear when the timer starts
            store.clearAllSettings()
        }
    }
    
    // Called when the "Unlock Session" ENDS (Time is up!)
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        if activity == .unlockSession {
            // 1. Read the saved apps from the App Group
            let defaults = UserDefaults(suiteName: appGroupID)
            
            if let data = defaults?.data(forKey: "SavedActivitySelection"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                
                // 2. RE-LOCK EVERYTHING
                store.shield.applications = selection.applicationTokens
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
                store.shield.webDomains = selection.webDomainTokens
                
                print("extension: Time is up. Apps re-locked.")
            } else {
                print("extension: Failed to load SavedActivitySelection")
            }
        }
    }
}
