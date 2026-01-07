import Foundation
import _DeviceActivity_SwiftUI
import DeviceActivity // ⚠️ ADD THIS LINE

extension DeviceActivityReport.Context {
    // This string "TimeRemaining" must match exactly in both targets
    static let timeRemaining = Self("TimeRemaining")
}
