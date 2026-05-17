import SwiftUI
import Charts

struct BehaviorTrendsView: View {
    var behavior: BehaviorSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricGrid
                consistencyGraph
            }
            .padding(24)
        }
        .navigationTitle("Behavior Trends")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Behavior Trends")
                .font(.largeTitle.weight(.semibold))

            Text("Weekly consistency, momentum, volatility, and plateau detection.")
                .foregroundStyle(.secondary)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Direction", value: behavior.trend.direction.rawValue, detail: String(format: "%.0f%% recent change", behavior.trend.changePercent), systemImage: "arrow.up.right", tint: trendColor)
            MetricCard(title: "Improving Weeks", value: "\(behavior.trend.consecutiveImprovingWeeks)", detail: "Consecutive week-over-week gains", systemImage: "chart.line.uptrend.xyaxis", tint: .green)
            MetricCard(title: "Plateau", value: behavior.trend.plateauDetected ? "Detected" : "No", detail: "Low movement across recent weeks", systemImage: "equal", tint: .blue)
            MetricCard(title: "Volatility", value: String(format: "%.0f", behavior.consistency.volatility), detail: "Average score spread by week", systemImage: "waveform.path.ecg", tint: .orange)
        }
    }

    private var consistencyGraph: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Consistency Graph")
                .font(.headline)

            if behavior.weeklyConsistency.isEmpty {
                EmptyAnalysisState(title: "No weekly trend yet", message: "Weekly consistency appears after historical daily summaries accumulate.")
            } else {
                Chart(behavior.weeklyConsistency) { point in
                    LineMark(x: .value("Week", point.weekStart), y: .value("Consistency", point.consistencyScore))
                        .foregroundStyle(.blue)

                    AreaMark(x: .value("Week", point.weekStart), y: .value("Consistency", point.consistencyScore))
                        .foregroundStyle(.blue.opacity(0.12))

                    LineMark(x: .value("Week", point.weekStart), y: .value("Goal", point.goalCompletion * 100))
                        .foregroundStyle(.green)
                }
                .chartYScale(domain: 0...100)
                .frame(minHeight: 320)
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
}
