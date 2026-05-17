import Combine
import Foundation

final class HistoryManager: ObservableObject {
    @Published var summaries: [DailySummary] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "Drona.HistoryManager")

    init() {
        fileURL = DatabaseManager.shared.storageDirectory.appendingPathComponent("dailySummaries.json")
        loadSummaries()
    }

    func saveSummary(_ summary: DailySummary) {
        if let index = summaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: summary.date) }) {
            summaries[index] = summary
        } else {
            summaries.append(summary)
        }

        summaries.sort { $0.date < $1.date }
        persist(summaries)
    }

    func loadSummaries() {
        do {
            let data = try Data(contentsOf: fileURL)
            summaries = try JSONDecoder().decode([DailySummary].self, from: data).sorted { $0.date < $1.date }
        } catch {
            summaries = []
            LoggingManager.shared.log(.info, subsystem: "Storage", message: "No previous daily summaries found.")
        }
    }

    private func persist(_ summaries: [DailySummary]) {
        queue.async { [fileURL] in
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(summaries)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                LoggingManager.shared.log(.error, subsystem: "Storage", message: "Failed saving daily summaries: \(error.localizedDescription)")
            }
        }
    }
}
