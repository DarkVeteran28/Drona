import Foundation

struct AppUsageRecord: Identifiable {

    var id = UUID()

    var appName: String

    var duration: TimeInterval

    var category: String

    var date: Date
}
