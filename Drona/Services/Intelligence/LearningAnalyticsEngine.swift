import Foundation

final class LearningAnalyticsEngine {
    private let calendar = Calendar.current

    func makeSnapshot(
        leetCodeStats: LeetCodeStats,
        leetCodeRecords: [LeetCodeDailyRecord],
        sessions: [LearningSession],
        achievements: [Achievement],
        productivityTrends: [DailyTrendPoint]
    ) -> LearningSnapshot {
        let leetCode = makeLeetCodeAnalytics(stats: leetCodeStats, records: leetCodeRecords)
        let projects = makeProjectAnalytics(sessions: sessions)
        let timeline = makeTimeline(records: leetCodeRecords, sessions: sessions, achievements: achievements)
        let efficiency = makeEfficiency(records: leetCodeRecords, sessions: sessions, productivityTrends: productivityTrends)
        let learningScore = makeLearningScore(leetCode: leetCode, projects: projects, achievements: achievements)

        return LearningSnapshot(
            learningScore: learningScore,
            leetCode: leetCode,
            projects: projects,
            achievements: achievements.sorted { $0.unlockedAt > $1.unlockedAt },
            timeline: timeline,
            outputEfficiency: efficiency
        )
    }

    private func makeLeetCodeAnalytics(stats: LeetCodeStats, records: [LeetCodeDailyRecord]) -> LeetCodeAnalytics {
        let sortedRecords = records.sorted { $0.date < $1.date }
        let today = calendar.startOfDay(for: Date())
        let todayRecord = sortedRecords.last { calendar.isDate($0.date, inSameDayAs: today) }
        let monthRecords = sortedRecords.filter { calendar.isDate($0.date, equalTo: today, toGranularity: .month) }

        return LeetCodeAnalytics(
            stats: stats,
            records: sortedRecords,
            solvedToday: todayRecord?.solvedCount ?? 0,
            currentStreak: currentStreak(records: sortedRecords),
            weeklyTrend: makeWeeklyTrend(records: sortedRecords),
            monthlySolved: monthRecords.reduce(0) { $0 + $1.solvedCount },
            mediumSolvedThisMonth: monthRecords.reduce(0) { $0 + $1.mediumSolved },
            hardSolvedThisMonth: monthRecords.reduce(0) { $0 + $1.hardSolved },
            difficultyDistribution: [
                DifficultyDistribution(difficulty: "Easy", count: stats.easySolved),
                DifficultyDistribution(difficulty: "Medium", count: stats.mediumSolved),
                DifficultyDistribution(difficulty: "Hard", count: stats.hardSolved)
            ]
        )
    }

    private func makeProjectAnalytics(sessions: [LearningSession]) -> ProjectAnalytics {
        let activeProjects = Dictionary(grouping: sessions, by: \.projectName)
            .map { projectName, projectSessions in
                ProjectSummary(
                    name: projectName,
                    sessionCount: projectSessions.count,
                    totalHours: projectSessions.reduce(0) { $0 + $1.durationHours },
                    lastWorkedAt: projectSessions.map(\.startDate).max() ?? Date.distantPast,
                    categories: Array(Set(projectSessions.map(\.category))).sorted { $0.rawValue < $1.rawValue }
                )
            }
            .sorted { $0.lastWorkedAt > $1.lastWorkedAt }

        let categoryHours = LearningCategory.allCases.map { category in
            LearningCategoryHours(
                category: category,
                hours: sessions.filter { $0.category == category }.reduce(0) { $0 + $1.durationHours }
            )
        }
        .filter { $0.hours > 0 }
        .sorted { $0.hours > $1.hours }

        let totalHours = sessions.reduce(0) { $0 + $1.durationHours }
        let averageScore = sessions.isEmpty ? 0 : sessions.reduce(0) { $0 + $1.productivityScore } / Double(sessions.count)

        return ProjectAnalytics(
            activeProjects: activeProjects,
            categoryHours: categoryHours,
            totalSessionHours: totalHours,
            averageProductivityScore: averageScore
        )
    }

    private func makeTimeline(
        records: [LeetCodeDailyRecord],
        sessions: [LearningSession],
        achievements: [Achievement]
    ) -> [LearningTimelineEvent] {
        let solvedEvents = records.filter { $0.solvedCount > 0 }.map { record in
            LearningTimelineEvent(
                date: record.date,
                title: "Solved \(record.solvedCount) LeetCode problems",
                detail: "Easy \(record.easySolved), Medium \(record.mediumSolved), Hard \(record.hardSolved)",
                systemImage: "checkmark.seal",
                tintName: "green"
            )
        }

        let sessionEvents = sessions.map { session in
            LearningTimelineEvent(
                date: session.startDate,
                title: session.projectName,
                detail: "\(session.category.rawValue) · \(formatHours(session.durationHours))",
                systemImage: "folder.badge.gearshape",
                tintName: "blue"
            )
        }

        let achievementEvents = achievements.map { achievement in
            LearningTimelineEvent(
                date: achievement.unlockedAt,
                title: achievement.title,
                detail: achievement.detail,
                systemImage: "medal",
                tintName: "orange"
            )
        }

        return (solvedEvents + sessionEvents + achievementEvents).sorted { $0.date > $1.date }
    }

    private func makeEfficiency(
        records: [LeetCodeDailyRecord],
        sessions: [LearningSession],
        productivityTrends: [DailyTrendPoint]
    ) -> [OutputEfficiencyPoint] {
        productivityTrends.suffix(30).map { trend in
            let day = calendar.startOfDay(for: trend.date)
            let solved = records.first { calendar.isDate($0.date, inSameDayAs: day) }?.solvedCount ?? 0
            let sessionHours = sessions
                .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationHours }

            return OutputEfficiencyPoint(
                date: day,
                productiveHours: trend.productiveHours,
                solvedCount: solved,
                sessionHours: sessionHours
            )
        }
    }

    private func makeWeeklyTrend(records: [LeetCodeDailyRecord]) -> [LeetCodeTrendPoint] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        return (0...6).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }

            let record = records.first { calendar.isDate($0.date, inSameDayAs: date) }
            return LeetCodeTrendPoint(
                date: date,
                solved: record?.solvedCount ?? 0,
                easy: record?.easySolved ?? 0,
                medium: record?.mediumSolved ?? 0,
                hard: record?.hardSolved ?? 0
            )
        }
    }

    private func makeLearningScore(
        leetCode: LeetCodeAnalytics,
        projects: ProjectAnalytics,
        achievements: [Achievement]
    ) -> Double {
        let solveScore = min(Double(leetCode.monthlySolved) / 30, 1) * 35
        let difficultyScore = min(Double(leetCode.mediumSolvedThisMonth + leetCode.hardSolvedThisMonth * 2) / 24, 1) * 25
        let projectScore = min(projects.totalSessionHours / 30, 1) * 25
        let consistencyScore = min(Double(leetCode.currentStreak) / 14, 1) * 10
        let achievementScore = min(Double(achievements.count) / 6, 1) * 5

        return min(solveScore + difficultyScore + projectScore + consistencyScore + achievementScore, 100)
    }

    private func currentStreak(records: [LeetCodeDailyRecord]) -> Int {
        let solvedDays = Set(records.filter { $0.solvedCount > 0 }.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: Date())
        var streak = 0

        while solvedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return streak
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
