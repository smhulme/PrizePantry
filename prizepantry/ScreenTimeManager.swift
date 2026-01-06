// File: prizepantry/ScreenTimeManager.swift
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
    
    private let store = ManagedSettingsStore(named: .lockedApps)
    private let center = DeviceActivityCenter()
    
    // ⚠️ IMPORTANT: This must match the App Group ID in your entitlements exactly
    let appGroupID = "group.com.prizepantry.tokentime"
    
    init() {
        // Load saved apps from the shared App Group so we remember what to block
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
    }
    
    // 1. Permission (Required to see the picker)
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Authorization Failed: \(error)")
            }
        }
    }
    
    // 2. The "Default State": Save the list and BLOCK immediately
    func saveSelectionAndLock() {
        // A. Save to App Group (so the Extension can see it later)
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = try? JSONEncoder().encode(activitySelection) {
            defaults?.set(data, forKey: "SavedActivitySelection")
        }
        
        // B. Block Immediately
        blockApps()
    }
    
    // Helper to apply the shield
    func blockApps() {
        // Use the tokens directly to shield applications
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
        print("🔒 Apps Locked")
    }
    
    // 3. The "Unlock": Clear shields and set a timer to re-lock
    func unlockApps(forMinutes minutes: Int) {
        // A. Unlock immediately
        store.clearAllSettings()
        print("🔓 Apps Unlocked for \(minutes) minutes")
        
        // B. Stop any existing timer (if they buy time twice, reset the clock)
        center.stopMonitoring([.unlockSession])
        
        // C. Schedule the "Time's Up" event
        let now = Date()
        let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        
        // Create the schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
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
