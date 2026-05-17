import SwiftUI
import Charts

struct DashboardView: View {
    var snapshot: AnalyticsSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                metricGrid

                HStack(alignment: .top, spacing: 20) {
                    trendPanel
                    VStack(spacing: 20) {
                        GoalProgressView(progress: snapshot.today.goalCompletion)
                        leaderboardPanel
                    }
                    .frame(width: 320)
                }

                appPanel
            }
            .padding(28)
        }
        .dronaPageBackground()
        .navigationTitle("Overview")
    }

    private var heroHeader: some View {
        DronaHeroCard(
            title: "Control Room",
            subtitle: "A focused operating layer for today's work rhythm, deep sessions, and long-term behavioral signals.",
            systemImage: "command.circle.fill",
            score: snapshot.today.productivityScore
        ) {
            HStack(spacing: 10) {
                heroPill("Status", snapshot.today.status)
                heroPill("Focused", formatHours(snapshot.today.productiveHours))
                heroPill("Streak", "\(snapshot.today.streak)d")
            }
        }
    }

    private func heroPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(
                title: "Status",
                value: snapshot.today.status,
                detail: "Current rule engine assessment",
                systemImage: "gauge.with.dots.needle.67percent",
                tint: .green
            )

            MetricCard(
                title: "Productive",
                value: formatHours(snapshot.today.productiveHours),
                detail: "Focused time today",
                systemImage: "hammer",
                tint: .green
            )

            MetricCard(
                title: "Distracting",
                value: formatHours(snapshot.today.distractingHours),
                detail: "Time outside focus rules",
                systemImage: "exclamationmark.triangle",
                tint: .red
            )

            MetricCard(
                title: "Streak",
                value: "\(snapshot.today.streak) days",
                detail: "Days at or above 70% score",
                systemImage: "flame",
                tint: .orange
            )
        }
    }

    private var trendPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Trends")
                .font(.headline)

            if snapshot.trends.isEmpty {
                EmptyAnalysisState(
                    title: "No historical trend yet",
                    message: "Save daily summaries to populate the long-term trend chart."
                )
            } else {
                Chart(snapshot.trends) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.productivityScore)
                    )
                    .foregroundStyle(.green)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.productivityScore)
                    )
                    .foregroundStyle(.green.opacity(0.12))
                }
                .chartYScale(domain: 0...100)
                .frame(minHeight: 260)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dronaPanel()
    }

    private var leaderboardPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Monthly Leaders")
                .font(.headline)

            if snapshot.monthRankings.isEmpty {
                EmptyAnalysisState(
                    title: "No months ranked",
                    message: "Monthly performance appears after daily summaries are saved."
                )
            } else {
                ForEach(Array(snapshot.monthRankings.prefix(4).enumerated()), id: \.element.id) { index, month in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(month.label)
                                .font(.subheadline.weight(.medium))

                            Text("\(formatHours(month.productiveHours)) productive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.0f%%", month.rankScore))
                                .font(.subheadline.monospacedDigit())

                            deltaLabel(month.deltaFromPrevious)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .dronaPanel()
    }

    private var appPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Activity")
                .font(.headline)

            if snapshot.appBreakdown.isEmpty {
                EmptyAnalysisState(
                    title: "No tracked apps yet",
                    message: "Activity appears here after the tracker records application usage."
                )
            } else {
                ForEach(snapshot.appBreakdown.prefix(8)) { item in
                    AppUsageRow(item: item)
                    if item.id != snapshot.appBreakdown.prefix(8).last?.id {
                        Divider()
                    }
                }
            }
        }
        .dronaPanel()
    }

    private func deltaLabel(_ delta: Double?) -> some View {
        Group {
            if let delta {
                Text(delta >= 0 ? "+\(Int(delta))" : "\(Int(delta))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(delta >= 0 ? .green : .red)
            } else {
                Text("baseline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
