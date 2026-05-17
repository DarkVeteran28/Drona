import SwiftUI
import Charts

struct InsightsView: View {
    var behavior: BehaviorSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricGrid
                insightsPanel

                HStack(alignment: .top, spacing: 20) {
                    productivityTimeline
                    distractionHeatmap
                        .frame(width: 360)
                }
            }
            .padding(24)
        }
        .navigationTitle("Insights")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Behavioral Intelligence")
                .font(.largeTitle.weight(.semibold))

            Text("Concise, data-backed observations about productivity patterns and weak points.")
                .foregroundStyle(.secondary)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Consistency", value: String(format: "%.0f%%", behavior.consistency.score), detail: "Goal completion adjusted for volatility", systemImage: "chart.line.flattrend.xyaxis", tint: .blue)
            MetricCard(title: "Trend", value: behavior.trend.direction.rawValue, detail: String(format: "%.0f%% recent change", behavior.trend.changePercent), systemImage: "arrow.up.right", tint: trendColor)
            MetricCard(title: "Burnout Risk", value: String(format: "%.0f%%", behavior.rest.burnoutRisk), detail: "Recent low-score and distraction signal", systemImage: "thermometer.medium", tint: .orange)
            MetricCard(title: "Efficiency", value: String(format: "%.2f/hr", behavior.efficiency.outputPerHour), detail: "Learning outputs per productive hour", systemImage: "speedometer", tint: .green)
        }
    }

    private var insightsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Prioritized Insights")
                .font(.headline)

            if behavior.insights.isEmpty {
                EmptyAnalysisState(title: "No insights yet", message: "Insights appear after productivity, violation, or learning history accumulates.")
            } else {
                ForEach(behavior.insights) { insight in
                    InsightRow(insight: insight)
                    if insight.id != behavior.insights.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var productivityTimeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hourly Productivity Signal")
                .font(.headline)

            Chart(behavior.hourlyProductivity) { point in
                BarMark(x: .value("Hour", formatHour(point.hour)), y: .value("Score", point.score))
                    .foregroundStyle(.green.opacity(0.7))
            }
            .chartYScale(domain: 0...100)
            .frame(minHeight: 280)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var distractionHeatmap: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Distraction Heatmap")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(behavior.distractionHeatmap) { point in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(heatColor(point.distractionAttempts))
                            .frame(height: 28)

                        Text(formatHour(point.hour))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .help("\(point.distractionAttempts) attempts")
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var trendColor: Color {
        switch behavior.trend.direction {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        }
    }

    private func heatColor(_ attempts: Int) -> Color {
        if attempts == 0 { return Color.secondary.opacity(0.12) }
        if attempts < 3 { return .orange.opacity(0.4) }
        if attempts < 8 { return .orange.opacity(0.7) }
        return .red.opacity(0.85)
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}

private struct InsightRow: View {
    var insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(insight.title)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    Text(insight.priority.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(color)
                }

                Text(insight.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                Text(insight.evidence)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var iconName: String {
        switch insight.category {
        case .productivity: return "target"
        case .distraction: return "exclamationmark.triangle"
        case .recovery: return "moon"
        case .boost: return "bolt"
        case .consistency: return "chart.line.flattrend.xyaxis"
        case .efficiency: return "speedometer"
        case .trend: return "arrow.up.right"
        }
    }

    private var color: Color {
        switch insight.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .secondary
        }
    }
}
