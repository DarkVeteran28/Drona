import SwiftUI
import Charts

struct LeetCodeView: View {
    @ObservedObject var learningTracker: LearningTracker
    var analytics: LeetCodeAnalytics
    var productiveHoursThisWeek: Double

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                connectionPanel
                metricGrid

                HStack(alignment: .top, spacing: 20) {
                    weeklyProgressPanel
                    difficultyPanel
                        .frame(width: 340)
                }

                recentSubmissionsPanel
            }
            .padding(24)
        }
        .navigationTitle("LeetCode")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LeetCode Tracking")
                .font(.largeTitle.weight(.semibold))

            Text("Problems solved, difficulty progression, streak, and monthly output.")
                .foregroundStyle(.secondary)
        }
    }

    private var connectionPanel: some View {
        HStack(spacing: 14) {
            Label("Darkveteran28", systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)

            Text("LeetCode tracking is automatic")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await learningTracker.refreshLeetCode(productiveHoursThisWeek: productiveHoursThisWeek)
                }
            } label: {
                if learningTracker.isRefreshingLeetCode {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .disabled(learningTracker.isRefreshingLeetCode)

            if let error = learningTracker.lastIntegrationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            Spacer()

            Text(lastFetchedText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
            MetricCard(title: "Solved Today", value: "\(analytics.solvedToday)", detail: "Accepted problems today", systemImage: "checkmark.seal", tint: .green)
            MetricCard(title: "Current Streak", value: "\(analytics.currentStreak)d", detail: "Consecutive solve days", systemImage: "flame", tint: .orange)
            MetricCard(title: "Total Solved", value: "\(analytics.stats.totalSolved)", detail: "All accepted problems", systemImage: "sum", tint: .blue)
            MetricCard(title: "This Month", value: "+\(analytics.monthlySolved)", detail: "Accepted problems this month", systemImage: "calendar", tint: .green)
            MetricCard(title: "Medium+Hard", value: "+\(analytics.mediumSolvedThisMonth + analytics.hardSolvedThisMonth)", detail: "Difficulty progression this month", systemImage: "chart.line.uptrend.xyaxis", tint: .purple)
        }
    }

    private var weeklyProgressPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Solve Trend")
                .font(.headline)

            Chart(analytics.weeklyTrend) { point in
                BarMark(x: .value("Date", point.date), y: .value("Easy", point.easy))
                    .foregroundStyle(.green.opacity(0.45))

                BarMark(x: .value("Date", point.date), y: .value("Medium", point.medium))
                    .foregroundStyle(.blue.opacity(0.65))

                BarMark(x: .value("Date", point.date), y: .value("Hard", point.hard))
                    .foregroundStyle(.red.opacity(0.75))
            }
            .frame(minHeight: 280)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var difficultyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Difficulty Distribution")
                .font(.headline)

            Chart(analytics.difficultyDistribution) { item in
                SectorMark(angle: .value("Solved", item.count), innerRadius: .ratio(0.58))
                    .foregroundStyle(color(for: item.difficulty))
            }
            .frame(height: 220)

            ForEach(analytics.difficultyDistribution) { item in
                HStack {
                    Label(item.difficulty, systemImage: "circle.fill")
                        .foregroundStyle(color(for: item.difficulty))
                    Spacer()
                    Text("\(item.count)")
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recentSubmissionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Accepted Submissions")
                .font(.headline)

            if analytics.stats.recentSubmissions.isEmpty {
                EmptyAnalysisState(title: "No submissions loaded", message: "Refresh a LeetCode username to load recent submission activity.")
            } else {
                ForEach(analytics.stats.recentSubmissions.filter { $0.statusDisplay == "Accepted" }.prefix(8)) { submission in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(submission.title)
                                .font(.subheadline.weight(.medium))

                            Text(submission.language)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(submission.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var lastFetchedText: String {
        guard analytics.stats.fetchedAt > Date.distantPast else {
            return "Not refreshed yet"
        }

        return "Updated \(analytics.stats.fetchedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
    }

    private func color(for difficulty: String) -> Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .blue
        case "Hard": return .red
        default: return .secondary
        }
    }
}
