import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

extension DeviceActivityName { static let unlockSession = DeviceActivityName("unlockSession") }
extension ManagedSettingsStore.Name { static let lockedApps = ManagedSettingsStore.Name("lockedApps") }

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    @Published var activitySelection = FamilyActivitySelection()
    private let store = ManagedSettingsStore(named: .lockedApps)
    private let center = DeviceActivityCenter()
    
    // REPLACE with your actual App Group ID
    let appGroupID = "group.com.prizepantry.tokentime"
    
    init() {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "SavedActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = selection
        }
    }
    
    func requestAuthorization() {
        Task { try? await AuthorizationCenter.shared.requestAuthorization(for: .child) }
    }
    
    func saveSelectionAndLock() {
        if let data = try? JSONEncoder().encode(activitySelection) {
            UserDefaults(suiteName: appGroupID)?.set(data, forKey: "SavedActivitySelection")
        }
        blockApps()
    }
    
    func blockApps() {
        store.shield.applications = activitySelection.applicationTokens
        store.shield.webDomains = activitySelection.webDomainTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
    }
    
    func unlockApps(forMinutes minutes: Int) {
        store.clearAllSettings()
        center.stopMonitoring([.unlockSession])
        let now = Date(), end = Calendar.current.date(byAdding: .minute, value: minutes, to: now)!
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: now),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: end),
            repeats: false
        )
        try? center.startMonitoring(.unlockSession, during: schedule)
    }
}
