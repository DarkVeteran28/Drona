import Foundation

struct DailySummary: Codable, Identifiable {

    var id = UUID()

    var date: Date

    var productiveTime: TimeInterval

    var neutralTime: TimeInterval

    var distractingTime: TimeInterval

    var productivityScore: Double

    var goalCompletion: Double

    var status: String

    var restModeEnabled: Bool

    var boostModeEnabled: Bool

    var violationsCount: Int
}
