import Combine
import Foundation

final class RecoveryManager: ObservableObject {
    @Published private(set) var interruptedSessionDetected = false
    @Published private(set) var lastRecoveryDate: Date?

    private let markerURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        markerURL = documents.appendingPathComponent("runtimeSession.json")
        detectInterruptedSession()
    }

    func markRunning() {
        let marker = RuntimeSessionMarker(startedAt: Date(), cleanShutdown: false)
        do {
            let data = try JSONEncoder().encode(marker)
            try data.write(to: markerURL, options: [.atomic])
        } catch {
            LoggingManager.shared.log(.error, subsystem: "Recovery", message: "Failed writing runtime marker: \(error.localizedDescription)")
        }
    }

    func markCleanShutdown() {
        let marker = RuntimeSessionMarker(startedAt: Date(), cleanShutdown: true)
        do {
            let data = try JSONEncoder().encode(marker)
            try data.write(to: markerURL, options: [.atomic])
            LoggingManager.shared.log(.info, subsystem: "Recovery", message: "Clean shutdown marker written.")
        } catch {
            LoggingManager.shared.log(.error, subsystem: "Recovery", message: "Failed writing clean shutdown marker: \(error.localizedDescription)")
        }
    }

    private func detectInterruptedSession() {
        do {
            let data = try Data(contentsOf: markerURL)
            let marker = try JSONDecoder().decode(RuntimeSessionMarker.self, from: data)
            interruptedSessionDetected = !marker.cleanShutdown
            if interruptedSessionDetected {
                lastRecoveryDate = Date()
                LoggingManager.shared.log(.warning, subsystem: "Recovery", message: "Interrupted session detected; state restored from persisted data.")
            }
            markRunning()
        } catch {
            interruptedSessionDetected = false
            markRunning()
        }
    }
}

private struct RuntimeSessionMarker: Codable {
    var startedAt: Date
    var cleanShutdown: Bool
}
