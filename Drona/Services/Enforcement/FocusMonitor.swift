import Foundation
import Combine

class FocusMonitor: ObservableObject {
    @Published var blockedApps: [String] = SettingsManager.shared.entries(from: UserDefaults.standard.string(forKey: "blockedApps") ?? AppSettings.defaults.blockedAppsText)
    @Published var enforcementEnabled = UserDefaults.standard.object(forKey: "enforcementEnabled") as? Bool ?? true
    @Published var currentViolation: String?

    let logger = ViolationLogger()

    private var lastViolationByApp: [String: Date] = [:]

    func check(appName: String) {
        refreshRuntimeSettings()

        guard enforcementEnabled, blockedApps.contains(appName) else {
            return
        }

        let now = Date()
        let cooldown = strictness.violationCooldown
        if let lastViolation = lastViolationByApp[appName], now.timeIntervalSince(lastViolation) < cooldown {
            currentViolation = appName
            return
        }

        currentViolation = appName
        lastViolationByApp[appName] = now
        logger.log(appName: appName)
    }

    private func refreshRuntimeSettings() {
        let defaults = UserDefaults.standard
        let blockedText = defaults.string(forKey: "blockedApps") ?? AppSettings.defaults.blockedAppsText
        blockedApps = SettingsManager.shared.entries(from: blockedText)
        enforcementEnabled = defaults.object(forKey: "enforcementEnabled") as? Bool ?? true
    }

    private var strictness: EnforcementStrictness {
        let rawValue = UserDefaults.standard.string(forKey: "enforcementStrictness") ?? EnforcementStrictness.balanced.rawValue
        return EnforcementStrictness(rawValue: rawValue) ?? .balanced
    }
}
