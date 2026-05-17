import Combine
import Foundation
import ServiceManagement

@MainActor
final class StartupManager: ObservableObject {
    @Published private(set) var isLaunchAtLoginEnabled: Bool = false
    @Published private(set) var statusDescription: String = "Unknown"
    @Published var lastError: String?

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            isLaunchAtLoginEnabled = status == .enabled
            statusDescription = description(for: status)
        } else {
            isLaunchAtLoginEnabled = UserDefaults.standard.bool(forKey: "launchAtLogin")
            statusDescription = "Unsupported before macOS 13"
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")

        guard #available(macOS 13.0, *) else {
            lastError = "Launch at login requires macOS 13 or later."
            refreshStatus()
            return
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
                LoggingManager.shared.log(.info, subsystem: "Startup", message: "Registered main app for launch at login.")
            } else {
                try SMAppService.mainApp.unregister()
                LoggingManager.shared.log(.info, subsystem: "Startup", message: "Unregistered main app from launch at login.")
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            LoggingManager.shared.log(.error, subsystem: "Startup", message: error.localizedDescription)
        }

        refreshStatus()
    }

    private func description(for status: SMAppService.Status) -> String {
        switch status {
        case .notRegistered:
            return "Not registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires approval in System Settings"
        case .notFound:
            return "Not found"
        @unknown default:
            return "Unknown"
        }
    }
}
