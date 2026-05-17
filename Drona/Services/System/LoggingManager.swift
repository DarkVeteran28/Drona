import Combine
import Foundation

final class LoggingManager: ObservableObject {
    static let shared = LoggingManager()

    @Published private(set) var entries: [SystemLogEntry] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "Drona.LoggingManager")
    private let maxEntries = 300

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("systemLogs.json")
        entries = loadEntries()
    }

    func log(_ level: LogLevel, subsystem: String, message: String) {
        guard shouldRecord(level) else {
            return
        }

        let entry = SystemLogEntry(
            timestamp: Date(),
            level: level,
            subsystem: subsystem,
            message: message
        )

        DispatchQueue.main.async {
            self.entries.insert(entry, at: 0)
            if self.entries.count > self.maxEntries {
                self.entries = Array(self.entries.prefix(self.maxEntries))
            }
            self.persist(self.entries)
        }
    }

    private func shouldRecord(_ level: LogLevel) -> Bool {
        let configured = UserDefaults.standard.string(forKey: "loggingVerbosity") ?? LogLevel.info.rawValue
        let minimum = LogLevel(rawValue: configured) ?? .info
        return rank(level) >= rank(minimum)
    }

    private func rank(_ level: LogLevel) -> Int {
        switch level {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }

    private func persist(_ entries: [SystemLogEntry]) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(entries)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch {
                print("Failed saving system logs: \(error)")
            }
        }
    }

    private func loadEntries() -> [SystemLogEntry] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([SystemLogEntry].self, from: data)
        } catch {
            return []
        }
    }
}
