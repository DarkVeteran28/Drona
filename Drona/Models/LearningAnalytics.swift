import Foundation

struct LearningSnapshot {
    var learningScore: Double
    var leetCode: LeetCodeAnalytics
    var projects: ProjectAnalytics
    var achievements: [Achievement]
    var timeline: [LearningTimelineEvent]
    var outputEfficiency: [OutputEfficiencyPoint]
}

struct LeetCodeAnalytics {
    var stats: LeetCodeStats
    var records: [LeetCodeDailyRecord]
    var solvedToday: Int
    var currentStreak: Int
    var weeklyTrend: [LeetCodeTrendPoint]
    var monthlySolved: Int
    var mediumSolvedThisMonth: Int
    var hardSolvedThisMonth: Int
    var difficultyDistribution: [DifficultyDistribution]
}

struct LeetCodeTrendPoint: Identifiable {
    let id = UUID()
    var date: Date
    var solved: Int
    var easy: Int
    var medium: Int
    var hard: Int
}

struct DifficultyDistribution: Identifiable {
    let id = UUID()
    var difficulty: String
    var count: Int
}

struct ProjectAnalytics {
    var activeProjects: [ProjectSummary]
    var categoryHours: [LearningCategoryHours]
    var totalSessionHours: Double
    var averageProductivityScore: Double
}

struct ProjectSummary: Identifiable {
    let id = UUID()
    var name: String
    var sessionCount: Int
    var totalHours: Double
    var lastWorkedAt: Date
    var categories: [LearningCategory]
}

struct LearningCategoryHours: Identifiable {
    let id = UUID()
    var category: LearningCategory
    var hours: Double
}

struct LearningTimelineEvent: Identifiable {
    let id = UUID()
    var date: Date
    var title: String
    var detail: String
    var systemImage: String
    var tintName: String
}

struct OutputEfficiencyPoint: Identifiable {
    let id = UUID()
    var date: Date
    var productiveHours: Double
    var solvedCount: Int
    var sessionHours: Double

    var outputPerHour: Double {
        let hours = max(productiveHours + sessionHours, 0.1)
        return Double(solvedCount) / hours
    }
}
