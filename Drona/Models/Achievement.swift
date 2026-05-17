import Foundation

struct Achievement: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: AchievementKind
    var title: String
    var detail: String
    var unlockedAt: Date
    var value: Double
}

enum AchievementKind: String, Codable, CaseIterable, Hashable {
    case firstSevenDayStreak
    case fiftyProblemsSolved
    case thirtyProductiveHoursWeek
    case deepWorkMilestone
    case firstProjectSession
    case hardProblemMilestone
}
