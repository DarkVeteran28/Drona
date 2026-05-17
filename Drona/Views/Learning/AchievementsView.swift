import SwiftUI

struct AchievementsView: View {
    var achievements: [Achievement]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                achievementGrid
            }
            .padding(24)
        }
        .navigationTitle("Achievements")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.largeTitle.weight(.semibold))

            Text("Minimal milestones for meaningful learning and output progress.")
                .foregroundStyle(.secondary)
        }
    }

    private var achievementGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            ForEach(AchievementKind.allCases, id: \.self) { kind in
                AchievementCard(kind: kind, achievement: achievements.first { $0.kind == kind })
            }
        }
    }
}

private struct AchievementCard: View {
    var kind: AchievementKind
    var achievement: Achievement?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: achievement == nil ? "lock" : "medal")
                    .foregroundStyle(iconColor)

                Spacer()

                Text(achievement == nil ? "Locked" : "Unlocked")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }

            Text(achievement?.title ?? title)
                .font(.headline)
                .lineLimit(2)

            Text(achievement?.detail ?? detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer()

            if let achievement {
                Text(achievement.unlockedAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var iconColor: Color {
        achievement == nil ? .secondary : .orange
    }

    private var statusColor: Color {
        achievement == nil ? .secondary : .green
    }

    private var title: String {
        switch kind {
        case .firstSevenDayStreak:
            return "7-Day Learning Streak"
        case .fiftyProblemsSolved:
            return "50 Problems Solved"
        case .thirtyProductiveHoursWeek:
            return "30 Productive Hours"
        case .deepWorkMilestone:
            return "Deep Work Milestone"
        case .firstProjectSession:
            return "First Project Session"
        case .hardProblemMilestone:
            return "Hard Problem Milestone"
        }
    }

    private var detail: String {
        switch kind {
        case .firstSevenDayStreak:
            return "Maintain seven consecutive days of learning output."
        case .fiftyProblemsSolved:
            return "Reach fifty accepted LeetCode problems."
        case .thirtyProductiveHoursWeek:
            return "Accumulate thirty productive hours in a week."
        case .deepWorkMilestone:
            return "Log ten hours of project learning sessions."
        case .firstProjectSession:
            return "Save the first manually tracked project session."
        case .hardProblemMilestone:
            return "Reach ten hard LeetCode problems."
        }
    }
}
