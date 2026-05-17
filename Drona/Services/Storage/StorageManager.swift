import Foundation

final class StorageManager {
    static let shared = StorageManager()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "Drona.StorageManager")

    private init() {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        fileURL = documents.appendingPathComponent("usageData.json")
    }

    func save(_ usages: [AppUsage]) {
        do {
            let data = try JSONEncoder().encode(usages)
            try data.write(to: fileURL, options: [.atomic])
            LoggingManager.shared.log(.debug, subsystem: "Storage", message: "Usage data saved atomically.")
        } catch {
            LoggingManager.shared.log(.error, subsystem: "Storage", message: "Failed saving usage data: \(error.localizedDescription)")
        }
    }

    func saveAsync(_ usages: [AppUsage], completion: ((Bool) -> Void)? = nil) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(usages)
                try data.write(to: self.fileURL, options: [.atomic])
                DispatchQueue.main.async {
                    completion?(true)
                }
            } catch {
                LoggingManager.shared.log(.error, subsystem: "Storage", message: "Failed async usage save: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    func load() -> [AppUsage] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([AppUsage].self, from: data)
        } catch {
            LoggingManager.shared.log(.info, subsystem: "Storage", message: "No previous usage data found.")
            return []
        }
    }
}
