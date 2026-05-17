import AppKit
import Combine
import Foundation

final class SystemHealthManager: ObservableObject {
    @Published private(set) var snapshot: SystemHealthSnapshot

    private let performanceManager: PerformanceManager
    private let recoveryManager: RecoveryManager
    private var timer: Timer?
    private var lastTrackingHeartbeat: Date?
    private var lastSave: Date?
    private var lastWidgetSync: Date?
    private var restartAttempts = 0

    init(performanceManager: PerformanceManager, recoveryManager: RecoveryManager) {
        self.performanceManager = performanceManager
        self.recoveryManager = recoveryManager
        snapshot = SystemHealthSnapshot.placeholder
    }

    func startMonitoring(tracker: ActivityTracker) {
        refresh(tracker: tracker)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self, weak tracker] _ in
            guard let self, let tracker else { return }
            self.refresh(tracker: tracker)
            self.recoverIfNeeded(tracker: tracker)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refresh(tracker: ActivityTracker) {
        performanceManager.refresh()
        lastTrackingHeartbeat = tracker.lastTrackingHeartbeat
        lastSave = tracker.lastSaveDate
        lastWidgetSync = WidgetRefreshManager.lastRefreshDate

        let tracking = trackingHealth(tracker: tracker)
        let enforcement = HealthItem(
            title: "Enforcement",
            state: tracker.focusMonitor.enforcementEnabled ? .healthy : .warning,
            detail: tracker.focusMonitor.enforcementEnabled ? "Focus enforcement is active." : "Focus enforcement is disabled.",
            checkedAt: Date()
        )
        let database = databaseHealth()
        let permissions = permissionHealth()
        let widgets = widgetHealth()
        let persistence = persistenceHealth()
        let recentRecoveryLogs = LoggingManager.shared.entries
            .filter { $0.subsystem == "Recovery" }
            .prefix(6)
            .map { $0 }

        snapshot = SystemHealthSnapshot(
            tracking: tracking,
            enforcement: enforcement,
            database: database,
            permissions: permissions,
            widgets: widgets,
            persistence: persistence,
            performance: performanceManager.snapshot,
            lastSave: lastSave,
            lastWidgetSync: lastWidgetSync,
            recoveryEvents: recentRecoveryLogs
        )
    }

    private func recoverIfNeeded(tracker: ActivityTracker) {
        guard tracker.isTrackingStale else {
            restartAttempts = 0
            return
        }

        guard restartAttempts < 3 else {
            LoggingManager.shared.log(.error, subsystem: "Health", message: "Tracking loop is stale and restart limit has been reached.")
            return
        }

        restartAttempts += 1
        tracker.restartTracking(reason: "Health monitor detected stale tracking heartbeat.")
        LoggingManager.shared.log(.warning, subsystem: "Health", message: "Restarted stale tracking loop. Attempt \(restartAttempts).")
    }

    private func trackingHealth(tracker: ActivityTracker) -> HealthItem {
        let state: HealthState = tracker.isTrackingStale ? .failed : (tracker.isTracking ? .healthy : .warning)
        let detail: String

        if tracker.isTrackingStale {
            detail = "Tracking heartbeat is stale. Recovery will attempt a safe restart."
        } else if tracker.isTracking {
            detail = "Tracking loop is active."
        } else {
            detail = "Tracking loop is stopped."
        }

        return HealthItem(
            title: "Tracking Engine",
            state: state,
            detail: detail,
            checkedAt: Date()
        )
    }

    private func databaseHealth() -> HealthItem {
        let isHealthy = DatabaseManager.shared.healthCheck()
        return HealthItem(
            title: "Local Storage",
            state: isHealthy ? .healthy : .failed,
            detail: isHealthy ? "Local storage is writable." : "Local storage could not be written.",
            checkedAt: Date()
        )
    }

    private func permissionHealth() -> HealthItem {
        let accessibilityTrusted = AXIsProcessTrusted()
        return HealthItem(
            title: "Permissions",
            state: accessibilityTrusted ? .healthy : .warning,
            detail: accessibilityTrusted ? "Accessibility permission is available." : "Accessibility permission is not granted. Some enforcement checks may be limited.",
            checkedAt: Date()
        )
    }

    private func widgetHealth() -> HealthItem {
        guard let lastWidgetSync else {
            return HealthItem(
                title: "Widgets",
                state: .unknown,
                detail: "Widgets have not synced in this app session.",
                checkedAt: Date()
            )
        }

        let age = Date().timeIntervalSince(lastWidgetSync)
        return HealthItem(
            title: "Widgets",
            state: age < 900 ? .healthy : .warning,
            detail: "Last widget sync was \(Int(age / 60)) minutes ago.",
            checkedAt: Date()
        )
    }

    private func persistenceHealth() -> HealthItem {
        guard let lastSave else {
            return HealthItem(
                title: "Persistence",
                state: .unknown,
                detail: "No autosave has completed in this app session.",
                checkedAt: Date()
            )
        }

        let age = Date().timeIntervalSince(lastSave)
        return HealthItem(
            title: "Persistence",
            state: age < 180 ? .healthy : .warning,
            detail: "Last save was \(Int(age)) seconds ago.",
            checkedAt: Date()
        )
    }
}

private extension SystemHealthSnapshot {
    static var placeholder: SystemHealthSnapshot {
        let unknown = HealthItem(title: "Unknown", state: .unknown, detail: "Health checks have not run yet.", checkedAt: Date())
        return SystemHealthSnapshot(
            tracking: unknown,
            enforcement: unknown,
            database: unknown,
            permissions: unknown,
            widgets: unknown,
            persistence: unknown,
            performance: PerformanceSnapshot(memoryMegabytes: 0, trackingInterval: 2, batterySavingMode: false, lowPowerMode: false),
            lastSave: nil,
            lastWidgetSync: nil,
            recoveryEvents: []
        )
    }
}
