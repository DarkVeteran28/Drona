import AppKit
import Combine
import Foundation

struct DronaExportPackage: Codable {
    var exportedAt: Date
    var appUsages: [AppUsage]
    var dailySummaries: [DailySummary]
    var violations: [ViolationEvent]
    var settings: AppSettings
}

@MainActor
final class BackupManager: ObservableObject {
    @Published private(set) var lastStatus: String?

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func exportJSON(appUsages: [AppUsage], summaries: [DailySummary], violations: [ViolationEvent], settings: AppSettings) {
        let package = DronaExportPackage(
            exportedAt: Date(),
            appUsages: appUsages,
            dailySummaries: summaries,
            violations: violations,
            settings: settings
        )

        do {
            let data = try encoder.encode(package)
            let url = try savePanelURL(defaultName: "Drona Export.json")
            try data.write(to: url, options: [.atomic])
            lastStatus = "Exported JSON to \(url.lastPathComponent)."
        } catch CocoaError.userCancelled {
            lastStatus = nil
        } catch {
            lastStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    func exportCSV(appUsages: [AppUsage], summaries: [DailySummary]) {
        do {
            let data = makeCSV(appUsages: appUsages, summaries: summaries).data(using: .utf8) ?? Data()
            let url = try savePanelURL(defaultName: "Drona Export.csv")
            try data.write(to: url, options: [.atomic])
            lastStatus = "Exported CSV to \(url.lastPathComponent)."
        } catch CocoaError.userCancelled {
            lastStatus = nil
        } catch {
            lastStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    func createBackup() {
        do {
            let backupRoot = try backupDirectory()
            let folder = backupRoot.appendingPathComponent("Drona Backup \(Self.timestamp.string(from: Date()))", isDirectory: true)
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

            for fileName in ["usageData.json", "violations.json", "systemLogs.json", "drona.sqlite3"] {
                let source = documentsDirectory.appendingPathComponent(fileName)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.copyItem(to: source, fromReplacing: folder.appendingPathComponent(fileName))
            }

            lastStatus = "Backup created in Documents/Drona Backups."
        } catch {
            lastStatus = "Backup failed: \(error.localizedDescription)"
        }
    }

    func restoreBackup() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Drona backup folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let folder = panel.url else {
            return
        }

        do {
            for fileName in ["usageData.json", "violations.json", "systemLogs.json", "drona.sqlite3"] {
                let source = folder.appendingPathComponent(fileName)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.copyItem(to: source, fromReplacing: documentsDirectory.appendingPathComponent(fileName))
            }

            lastStatus = "Backup restored. Restart Drona to reload restored data."
        } catch {
            lastStatus = "Restore failed: \(error.localizedDescription)"
        }
    }

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func backupDirectory() throws -> URL {
        let url = documentsDirectory.appendingPathComponent("Drona Backups", isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func savePanelURL(defaultName: String) throws -> URL {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.directoryURL = documentsDirectory

        guard panel.runModal() == .OK, let url = panel.url else {
            throw CocoaError(.userCancelled)
        }

        return url
    }

    private func makeCSV(appUsages: [AppUsage], summaries: [DailySummary]) -> String {
        var rows: [String] = ["section,date,name,productiveHours,neutralHours,distractingHours,score,totalHours,violations"]

        rows += summaries.map { summary in
            [
                "daily_summary",
                Self.csvDate.string(from: summary.date),
                "",
                Self.hours(summary.productiveTime),
                Self.hours(summary.neutralTime),
                Self.hours(summary.distractingTime),
                String(format: "%.0f", summary.productivityScore),
                "",
                "\(summary.violationsCount)"
            ].map(Self.escapeCSV).joined(separator: ",")
        }

        rows += appUsages.map { usage in
            [
                "app_usage",
                Self.csvDate.string(from: usage.lastActive),
                usage.appName,
                "",
                "",
                "",
                "",
                Self.hours(usage.totalTime),
                ""
            ].map(Self.escapeCSV).joined(separator: ",")
        }

        return rows.joined(separator: "\n")
    }

    private static func hours(_ interval: TimeInterval) -> String {
        String(format: "%.2f", interval / 3600)
    }

    private static func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static let csvDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter
    }()
}

private extension FileManager {
    func copyItem(to source: URL, fromReplacing destination: URL) throws {
        if fileExists(atPath: destination.path) {
            try removeItem(at: destination)
        }
        try copyItem(at: source, to: destination)
    }
}
