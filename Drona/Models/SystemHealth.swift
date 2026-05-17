import Foundation

struct SystemHealthSnapshot {
    var tracking: HealthItem
    var enforcement: HealthItem
    var database: HealthItem
    var permissions: HealthItem
    var widgets: HealthItem
    var persistence: HealthItem
    var performance: PerformanceSnapshot
    var lastSave: Date?
    var lastWidgetSync: Date?
    var recoveryEvents: [SystemLogEntry]
}

struct HealthItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var state: HealthState
    var detail: String
    var checkedAt: Date
}

enum HealthState: String, Hashable {
    case healthy = "Healthy"
    case warning = "Warning"
    case failed = "Failed"
    case unknown = "Unknown"
}

struct PerformanceSnapshot: Hashable {
    var memoryMegabytes: Double
    var trackingInterval: TimeInterval
    var batterySavingMode: Bool
    var lowPowerMode: Bool
}

struct SystemLogEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var timestamp: Date
    var level: LogLevel
    var subsystem: String
    var message: String
}

enum LogLevel: String, Codable, CaseIterable, Hashable {
    case debug = "Debug"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
}
