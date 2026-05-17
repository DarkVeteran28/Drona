import SwiftUI
import Charts

struct FocusAnalysisView: View {
    var behavior: BehaviorSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricGrid

                HStack(alignment: .top, spacing: 20) {
                    sessionDistributionPanel
                    deepWorkPanel
                        .frame(width: 360)
                }
            }
            .padding(24)
        }
        .navigationTitle("Focus Analysis")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus Analysis")
                .font(.largeTitle.weight(.semibold))

            Text("Deep work, session duration effectiveness, and high-output conditions.")
                .foregroundStyle(.secondary)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Deep Work Days", value: "\(behavior.focus.deepWorkDays)", detail: "Days with at least four productive hours", systemImage: "timer", tint: .green)
            MetricCard(title: "Avg Deep Work", value: formatHours(behavior.focus.averageDeepWorkHours), detail: "Average productive hours on deep days", systemImage: "clock", tint: .green)
            MetricCard(title: "Best Day", value: behavior.focus.bestDayOfWeek, detail: String(format: "Average score %.0f%%", behavior.focus.bestDayScore), systemImage: "calendar", tint: .blue)
            MetricCard(title: "Stable Weeks", value: "\(behavior.consistency.stableWeeks)", detail: "Weeks above 70% consistency", systemImage: "checkmark.seal", tint: .purple)
        }
    }

    private var sessionDistributionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session Duration Effectiveness")
                .font(.headline)

            Chart(behavior.focusDistribution) { bucket in
                BarMark(x: .value("Session Type", bucket.label), y: .value("Average Score", bucket.averageScore))
                    .foregroundStyle(.green.opacity(0.7))
            }
            .chartYScale(domain: 0...100)
            .frame(minHeight: 300)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var deepWorkPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Distribution")
                .font(.headline)

            ForEach(behavior.focusDistribution) { bucket in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bucket.label)
                            .font(.subheadline.weight(.medium))

                        Text("\(bucket.sessionCount) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", bucket.averageScore))
                        .font(.subheadline.monospacedDigit())
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
