import Foundation

final class DatabaseManager {
    static let shared = DatabaseManager()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var storageDirectory: URL {
        documentsDirectory
    }

    func healthCheck() -> Bool {
        fileManager.isWritableFile(atPath: documentsDirectory.path)
    }
}
