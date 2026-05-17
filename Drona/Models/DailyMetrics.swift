import Foundation

struct DailyMetrics: Codable {

    var productiveTime: TimeInterval = 0

    var neutralTime: TimeInterval = 0

    var distractingTime: TimeInterval = 0

    var productivityScore: Double = 0

    var status: DailyStatus = .onTrack
}
