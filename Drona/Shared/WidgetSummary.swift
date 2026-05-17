import Foundation

struct WidgetSummary: Codable {
    var productiveHours: Double
    var distractingHours: Double
    var productivityScore: Double
    var status: String
    var streak: Int
    var goalProgress: Double
    var leetCodeStreak: Int
    var leetCodeSolved: Int
    var leetCodeSolvedToday: Int
    var gitHubCommitsToday: Int
    var gitHubWeeklyCommits: Int
    var gitHubStreak: Int
    var codingActivity: [CodingActivityDay]
    var portfolioRepositoryCount: Int
    var portfolioFeaturedProject: String
    var portfolioActiveProject: String
    var portfolioLatestCommit: String

    init(
        productiveHours: Double,
        distractingHours: Double,
        productivityScore: Double,
        status: String,
        streak: Int,
        goalProgress: Double,
        leetCodeStreak: Int = 0,
        leetCodeSolved: Int = 0,
        leetCodeSolvedToday: Int = 0,
        gitHubCommitsToday: Int = 0,
        gitHubWeeklyCommits: Int = 0,
        gitHubStreak: Int = 0,
        codingActivity: [CodingActivityDay] = [],
        portfolioRepositoryCount: Int = 0,
        portfolioFeaturedProject: String = "None",
        portfolioActiveProject: String = "None",
        portfolioLatestCommit: String = "No commits loaded"
    ) {
        self.productiveHours = productiveHours
        self.distractingHours = distractingHours
        self.productivityScore = productivityScore
        self.status = status
        self.streak = streak
        self.goalProgress = goalProgress
        self.leetCodeStreak = leetCodeStreak
        self.leetCodeSolved = leetCodeSolved
        self.leetCodeSolvedToday = leetCodeSolvedToday
        self.gitHubCommitsToday = gitHubCommitsToday
        self.gitHubWeeklyCommits = gitHubWeeklyCommits
        self.gitHubStreak = gitHubStreak
        self.codingActivity = codingActivity
        self.portfolioRepositoryCount = portfolioRepositoryCount
        self.portfolioFeaturedProject = portfolioFeaturedProject
        self.portfolioActiveProject = portfolioActiveProject
        self.portfolioLatestCommit = portfolioLatestCommit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productiveHours = try container.decodeIfPresent(Double.self, forKey: .productiveHours) ?? 0
        distractingHours = try container.decodeIfPresent(Double.self, forKey: .distractingHours) ?? 0
        productivityScore = try container.decodeIfPresent(Double.self, forKey: .productivityScore) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        goalProgress = try container.decodeIfPresent(Double.self, forKey: .goalProgress) ?? 0
        leetCodeStreak = try container.decodeIfPresent(Int.self, forKey: .leetCodeStreak) ?? 0
        leetCodeSolved = try container.decodeIfPresent(Int.self, forKey: .leetCodeSolved) ?? 0
        leetCodeSolvedToday = try container.decodeIfPresent(Int.self, forKey: .leetCodeSolvedToday) ?? 0
        gitHubCommitsToday = try container.decodeIfPresent(Int.self, forKey: .gitHubCommitsToday) ?? 0
        gitHubWeeklyCommits = try container.decodeIfPresent(Int.self, forKey: .gitHubWeeklyCommits) ?? 0
        gitHubStreak = try container.decodeIfPresent(Int.self, forKey: .gitHubStreak) ?? 0
        codingActivity = try container.decodeIfPresent([CodingActivityDay].self, forKey: .codingActivity) ?? []
        portfolioRepositoryCount = try container.decodeIfPresent(Int.self, forKey: .portfolioRepositoryCount) ?? 0
        portfolioFeaturedProject = try container.decodeIfPresent(String.self, forKey: .portfolioFeaturedProject) ?? "None"
        portfolioActiveProject = try container.decodeIfPresent(String.self, forKey: .portfolioActiveProject) ?? "None"
        portfolioLatestCommit = try container.decodeIfPresent(String.self, forKey: .portfolioLatestCommit) ?? "No commits loaded"
    }
}
