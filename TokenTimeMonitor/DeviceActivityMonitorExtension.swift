//
//  DeviceActivityMonitorExtension.swift
//  PrizePantryMonitor
//
//  Created for PrizePantry
//

import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

// 1. FIXED: Redefine the name here so the Extension knows what 'unlockSession' is
extension DeviceActivityName {
    static let unlockSession = DeviceActivityName("unlockSession")
}

// Ensure we access the same Store Name
extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore(named: .lockedApps)
    
    // Called when the "Unlock Session" schedule starts (The user just bought time)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        if activity == .unlockSession {
            // Ensure shields are OFF when time is bought
            store.clearAllSettings()
        }
    }
    
    // Called when the "Unlock Session" ends (Time is up!)
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        if activity == .unlockSession {
            // RE-LOCK THE APPS
            
            // Note: In a real production app, use App Groups to share 'SavedActivitySelection'
            // securely between the main App and this Extension.
            // For now, we attempt to read standard defaults.
            if let data = UserDefaults.standard.data(forKey: "SavedActivitySelection"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                
                store.shield.applications = selection.applicationTokens
                store.shield.webDomains = selection.webDomainTokens
                
                // 2. FIXED: Use 'applicationCategories' and wrap it in .specific()
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
            }
        }
    }
}
