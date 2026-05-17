import Foundation

class SharedDataProvider {
    static let shared = SharedDataProvider()

    private let defaults = UserDefaults(suiteName: "group.com.likhiththejas.drona")
    private let summaryKey = "widget_summary"

    func saveSummary(_ summary: WidgetSummary) {
        do {
            let data = try JSONEncoder().encode(summary)
            defaults?.set(data, forKey: summaryKey)
        } catch {
            print("Failed saving widget summary: \(error.localizedDescription)")
        }
    }

    func saveCodingSummary(
        leetCodeStats: LeetCodeStats,
        leetCodeRecords: [LeetCodeDailyRecord],
        gitHubStats: GitHubStats
    ) {
        let existing = loadSummary() ?? WidgetSummary(
            productiveHours: 0,
            distractingHours: 0,
            productivityScore: 0,
            status: "unknown",
            streak: 0,
            goalProgress: 0
        )

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let solvedToday = leetCodeRecords.first { calendar.isDate($0.date, inSameDayAs: today) }?.solvedCount ?? 0
        let combinedActivity = mergeActivity(leetCodeStats.activityHistory, gitHubStats.activityHistory)

        saveSummary(
            WidgetSummary(
                productiveHours: existing.productiveHours,
                distractingHours: existing.distractingHours,
                productivityScore: existing.productivityScore,
                status: existing.status,
                streak: max(existing.streak, leetCodeStats.dailyStreak, gitHubStats.contributionStreak),
                goalProgress: existing.goalProgress,
                leetCodeStreak: leetCodeStats.dailyStreak,
                leetCodeSolved: leetCodeStats.totalSolved,
                leetCodeSolvedToday: solvedToday,
                gitHubCommitsToday: gitHubStats.dailyCommits,
                gitHubWeeklyCommits: gitHubStats.weeklyCommits,
                gitHubStreak: gitHubStats.contributionStreak,
                codingActivity: combinedActivity,
                portfolioRepositoryCount: existing.portfolioRepositoryCount,
                portfolioFeaturedProject: existing.portfolioFeaturedProject,
                portfolioActiveProject: existing.portfolioActiveProject,
                portfolioLatestCommit: existing.portfolioLatestCommit
            )
        )
    }

    func savePortfolioSummary(_ snapshot: GitHubPortfolioSnapshot) {
        let existing = loadSummary() ?? WidgetSummary(
            productiveHours: 0,
            distractingHours: 0,
            productivityScore: 0,
            status: "unknown",
            streak: 0,
            goalProgress: 0
        )
        let featured = snapshot.projects.first { $0.isPinned } ?? snapshot.projects.first
        let active = snapshot.projects.max { $0.commitActivityScore < $1.commitActivityScore }
        let latestCommit = snapshot.projects
            .flatMap(\.latestCommits)
            .max { $0.committedAt < $1.committedAt }

        saveSummary(
            WidgetSummary(
                productiveHours: existing.productiveHours,
                distractingHours: existing.distractingHours,
                productivityScore: existing.productivityScore,
                status: existing.status,
                streak: existing.streak,
                goalProgress: existing.goalProgress,
                leetCodeStreak: existing.leetCodeStreak,
                leetCodeSolved: existing.leetCodeSolved,
                leetCodeSolvedToday: existing.leetCodeSolvedToday,
                gitHubCommitsToday: existing.gitHubCommitsToday,
                gitHubWeeklyCommits: existing.gitHubWeeklyCommits,
                gitHubStreak: existing.gitHubStreak,
                codingActivity: existing.codingActivity,
                portfolioRepositoryCount: snapshot.analytics.totalRepositories,
                portfolioFeaturedProject: featured?.name ?? "None",
                portfolioActiveProject: active?.name ?? "None",
                portfolioLatestCommit: latestCommit?.message ?? "No commits loaded"
            )
        )
    }

    func loadSummary() -> WidgetSummary? {
        guard let data = defaults?.data(forKey: summaryKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WidgetSummary.self, from: data)
        } catch {
            print("Failed loading widget summary: \(error.localizedDescription)")
            return nil
        }
    }

    private func mergeActivity(_ first: [CodingActivityDay], _ second: [CodingActivityDay]) -> [CodingActivityDay] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]

        for item in first + second {
            let day = calendar.startOfDay(for: item.date)
            counts[day, default: 0] += item.count
        }

        return counts.map { date, count in
            CodingActivityDay(date: date, count: count)
        }
        .sorted { $0.date < $1.date }
        .suffix(98)
        .map { $0 }
    }
}
