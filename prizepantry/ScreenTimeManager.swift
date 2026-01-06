//
//  ScreenTimeManager.swift
//  prizepantry
//
//  Created by Shawn Hulme on 1/6/26.
//


//
//  ScreenTimeManager.swift
//  prizepantry
//
//  Created for PrizePantry Screen Time Logic
//

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
    
    init() {
        // Load saved selection from UserDefaults if it exists
        if let data = UserDefaults.standard.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
    }
    
    // 1. Request Permission (Call this when Child View loads)
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
    
    // 2. Save the list of apps to block and Apply the Shield immediately
    func saveSelectionAndLock() {
        // Save to disk
        if let data = try? JSONEncoder().encode(activitySelection) {
            UserDefaults.standard.set(data, forKey: "SavedActivitySelection")
        }
        
        // Apply restrictions (Block the apps)
        // We set the "application" property of the shield to the tokens of selected apps.
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
        
        // 2. Schedule a DeviceActivity that starts NOW and ends in X minutes.
        // When this activity ENDS, the Monitor Extension will kick in to re-lock the apps.
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
