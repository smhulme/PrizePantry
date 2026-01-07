import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

extension DeviceActivityName {
    static let dailySession = DeviceActivityName("dailySession")
}

extension ManagedSettingsStore.Name {
    static let lockedApps = ManagedSettingsStore.Name("lockedApps")
}

extension DeviceActivityEvent.Name {
    static let usageLimit = DeviceActivityEvent.Name("usageLimit")
}

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var activitySelection = FamilyActivitySelection()
    // This tracks the Total Daily Allowance (Stackable)
    @Published var cumulativeAllowance: Int = 0
    
    private let store = ManagedSettingsStore(named: .lockedApps)
    private let center = DeviceActivityCenter()
    
    let appGroupID = "group.com.prizepantry.tokentime"
    
    init() {
        let defaults = UserDefaults(suiteName: appGroupID)
        
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
        
        // Load existing allowance
        self.cumulativeAllowance = defaults?.integer(forKey: "cumulativeAllowance") ?? 0
        
        // Check for new day reset
        checkDateReset()
    }
    
    func checkDateReset() {
        let defaults = UserDefaults(suiteName: appGroupID)
        let lastDate = defaults?.object(forKey: "lastActiveDate") as? Date ?? Date()
        
        if !Calendar.current.isDateInToday(lastDate) {
            // New Day: Reset Allowance
            self.cumulativeAllowance = 0
            saveAllowance()
            lockApps()
        }
        defaults?.set(Date(), forKey: "lastActiveDate")
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
        // Apply lock immediately if allowance is 0
        if cumulativeAllowance == 0 {
            lockApps()
        } else {
            // If we have time, ensure we are monitoring correctly
            startMonitoring()
        }
    }
    
    func saveAllowance() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(cumulativeAllowance, forKey: "cumulativeAllowance")
    }
    
    // Explicitly Lock Apps (e.g., Parent Command or Limit Reached)
    func lockApps() {
        // Shield everything
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
        
        // Reset allowance to 0 if this was a manual lock (Parent action)
        // If it's a "Limit Reached" lock, the monitor handles it, but here we enforce shielding.
        self.cumulativeAllowance = 0
        saveAllowance()
        
        // Stop monitoring to prevent unlocking
        center.stopMonitoring([.dailySession])
        print("🔒 Apps Locked via Manager")
    }
    
    // ✅ NEW: Add Time (Stackable)
    func addTime(minutes: Int) {
        checkDateReset() // Ensure we are on today's bucket
        
        // 1. Stack the time
        self.cumulativeAllowance += minutes
        saveAllowance()
        
        // 2. Clear Shields (Unlock)
        store.clearAllSettings()
        print("🔓 Added \(minutes) mins. New Daily Limit: \(cumulativeAllowance) mins")
        
        // 3. Start/Update Monitoring
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Create an event with the ACCUMULATED threshold
        // The system compares (Total Usage Today) vs (cumulativeAllowance)
        let event = DeviceActivityEvent(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            webDomains: activitySelection.webDomainTokens,
            threshold: DateComponents(minute: cumulativeAllowance)
        )
        
        // Schedule: Today Midnight to Tomorrow Midnight
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: endOfDay),
            repeats: true,
            warningTime: nil
        )
        
        do {
            try center.startMonitoring(.dailySession, during: schedule, events: [
                .usageLimit: event
            ])
            print("📡 Monitoring Started/Updated for Limit: \(cumulativeAllowance)m")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}
