import AppKit
import Combine
import Foundation

final class ActivityTracker: ObservableObject {
    @Published var currentApp: String = "Unknown"
    @Published var trackedApps: [AppUsage] = []
    @Published private(set) var isTracking = false
    @Published private(set) var lastTrackingHeartbeat: Date?
    @Published private(set) var lastSaveDate: Date?

    private var timer: Timer?
    private var autosaveTimer: Timer?
    private var lastCheckDate = Date()
    private var pendingSave = false

    let focusMonitor = FocusMonitor()
    let ruleEngine = RuleEngine()

    init() {
        trackedApps = StorageManager.shared.load()
        startTracking()
    }

    deinit {
        stopTracking()
    }

    var isTrackingStale: Bool {
        guard isTracking, let lastTrackingHeartbeat else {
            return isTracking
        }

        let expectedInterval = max(effectiveTrackingInterval(), 2)
        return Date().timeIntervalSince(lastTrackingHeartbeat) > expectedInterval * 4
    }

    func startTracking() {
        guard !isTracking else {
            return
        }

        lastCheckDate = Date()
        isTracking = true
        detectActiveApp()
        scheduleTrackingTimer()
        scheduleAutosaveTimer()
        LoggingManager.shared.log(.info, subsystem: "Tracking", message: "Tracking started.")
    }

    func stopTracking() {
        timer?.invalidate()
        autosaveTimer?.invalidate()
        timer = nil
        autosaveTimer = nil
        isTracking = false
        flushData(reason: "Tracking stopped")
        LoggingManager.shared.log(.info, subsystem: "Tracking", message: "Tracking stopped.")
    }

    func restartTracking(reason: String) {
        timer?.invalidate()
        autosaveTimer?.invalidate()
        timer = nil
        autosaveTimer = nil
        isTracking = false
        LoggingManager.shared.log(.warning, subsystem: "Tracking", message: reason)
        startTracking()
    }

    func applyRuntimeSettings() {
        guard isTracking else {
            return
        }

        scheduleTrackingTimer()
        scheduleAutosaveTimer()
    }

    func flushData(reason: String) {
        let snapshot = trackedApps
        StorageManager.shared.saveAsync(snapshot) { [weak self] success in
            guard success else { return }
            self?.lastSaveDate = Date()
            self?.pendingSave = false
            LoggingManager.shared.log(.debug, subsystem: "Tracking", message: "Autosave completed: \(reason).")
        }
    }

    private func scheduleTrackingTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: effectiveTrackingInterval(), repeats: true) { [weak self] _ in
            self?.detectActiveApp()
        }
        timer?.tolerance = min(effectiveTrackingInterval() * 0.25, 2)
    }

    private func scheduleAutosaveTimer() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: autosaveInterval(), repeats: true) { [weak self] _ in
            self?.autosaveIfNeeded()
        }
        autosaveTimer?.tolerance = min(autosaveInterval() * 0.25, 10)
    }

    private func autosaveIfNeeded() {
        guard pendingSave else {
            return
        }

        flushData(reason: "Periodic autosave")
    }

    private func detectActiveApp() {
        lastTrackingHeartbeat = Date()

        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            return
        }

        let appName = activeApp.localizedName ?? "Unknown"
        let bundleID = activeApp.bundleIdentifier
        currentApp = appName

        let now = Date()
        let elapsed = min(max(now.timeIntervalSince(lastCheckDate), 0), 60)

        ruleEngine.processActivity(appName: appName, duration: elapsed)
        lastCheckDate = now
        updateUsage(appName: appName, bundleID: bundleID, elapsed: elapsed)
        focusMonitor.check(appName: appName)
    }

    private func updateUsage(appName: String, bundleID: String?, elapsed: TimeInterval) {
        if let index = trackedApps.firstIndex(where: { $0.appName == appName }) {
            trackedApps[index].totalTime += elapsed
            trackedApps[index].lastActive = Date()
        } else {
            let newUsage = AppUsage(
                appName: appName,
                bundleIdentifier: bundleID,
                totalTime: elapsed,
                lastActive: Date()
            )
            trackedApps.append(newUsage)
        }

        pendingSave = true
    }

    private func effectiveTrackingInterval() -> TimeInterval {
        let configured = UserDefaults.standard.double(forKey: "trackingFrequencySeconds")
        let base = configured > 0 ? configured : 2
        let batterySaving = UserDefaults.standard.bool(forKey: "batterySavingMode")
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        let rawSensitivity = UserDefaults.standard.string(forKey: "trackingSensitivity") ?? TrackingSensitivity.balanced.rawValue
        let sensitivity = TrackingSensitivity(rawValue: rawSensitivity) ?? .balanced
        return max(base, batterySaving || lowPower ? 5 : sensitivity.minimumInterval)
    }

    private func autosaveInterval() -> TimeInterval {
        let configured = UserDefaults.standard.double(forKey: "autosaveFrequencySeconds")
        return configured > 0 ? configured : 60
    }
}
