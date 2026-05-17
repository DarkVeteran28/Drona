import Foundation

struct AchievementEngine {
    func detectAchievements(
        leetCodeRecords: [LeetCodeDailyRecord],
        sessions: [LearningSession],
        productiveHoursThisWeek: Double,
        existing: [Achievement]
    ) -> [Achievement] {
        var achievements = existing
        let existingKinds = Set(existing.map(\.kind))
        let totalSolved = leetCodeRecords.last?.totalSolved ?? 0
        let hardSolved = leetCodeRecords.last?.hardSolved ?? 0
        let currentStreak = leetCodeStreak(from: leetCodeRecords)
        let totalSessionHours = sessions.reduce(0) { $0 + $1.durationHours }

        appendIfNeeded(
            kind: .firstSevenDayStreak,
            title: "7-Day Learning Streak",
            detail: "Solved or logged learning work for seven consecutive days.",
            value: Double(currentStreak),
            condition: currentStreak >= 7,
            existingKinds: existingKinds,
            achievements: &achievements
        )

        appendIfNeeded(
            kind: .fiftyProblemsSolved,
            title: "50 Problems Solved",
            detail: "Reached fifty accepted LeetCode problems.",
            value: Double(totalSolved),
            condition: totalSolved >= 50,
            existingKinds: existingKinds,
            achievements: &achievements
        )

        appendIfNeeded(
            kind: .thirtyProductiveHoursWeek,
            title: "30 Productive Hours",
            detail: "Logged thirty productive hours in a week.",
            value: productiveHoursThisWeek,
            condition: productiveHoursThisWeek >= 30,
            existingKinds: existingKinds,
            achievements: &achievements
        )

        appendIfNeeded(
            kind: .deepWorkMilestone,
            title: "Deep Work Milestone",
            detail: "Logged ten hours of tracked learning sessions.",
            value: totalSessionHours,
            condition: totalSessionHours >= 10,
            existingKinds: existingKinds,
            achievements: &achievements
        )

        appendIfNeeded(
            kind: .firstProjectSession,
            title: "First Project Session",
            detail: "Logged the first project-based learning session.",
            value: Double(sessions.count),
            condition: !sessions.isEmpty,
            existingKinds: existingKinds,
            achievements: &achievements
        )

        appendIfNeeded(
            kind: .hardProblemMilestone,
            title: "Hard Problem Milestone",
            detail: "Solved ten hard LeetCode problems.",
            value: Double(hardSolved),
            condition: hardSolved >= 10,
            existingKinds: existingKinds,
            achievements: &achievements
        )

        return achievements.sorted { $0.unlockedAt > $1.unlockedAt }
    }

    private func appendIfNeeded(
        kind: AchievementKind,
        title: String,
        detail: String,
        value: Double,
        condition: Bool,
        existingKinds: Set<AchievementKind>,
        achievements: inout [Achievement]
    ) {
        guard condition, !existingKinds.contains(kind) else {
            return
        }

        achievements.append(
            Achievement(
                kind: kind,
                title: title,
                detail: detail,
                unlockedAt: Date(),
                value: value
            )
        )
    }

    private func leetCodeStreak(from records: [LeetCodeDailyRecord]) -> Int {
        let calendar = Calendar.current
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
}
