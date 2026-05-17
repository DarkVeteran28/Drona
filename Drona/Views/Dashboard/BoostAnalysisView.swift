import SwiftUI
import Charts

struct BoostAnalysisView: View {
    var analytics: BoostAnalytics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricGrid
                spikePanel
            }
            .padding(24)
        }
        .navigationTitle("Boost Analysis")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Boost Mode Analysis")
                .font(.largeTitle.weight(.semibold))

            Text("High-performance states, score spikes, and goal completion during boost periods.")
                .foregroundStyle(.secondary)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            MetricCard(title: "Boost Days", value: "\(analytics.boostDays)", detail: "Days explicitly saved with boost enabled", systemImage: "bolt.fill", tint: .yellow)
            MetricCard(title: "Avg Boost Score", value: String(format: "%.0f%%", analytics.averageBoostScore), detail: "Average score during spikes", systemImage: "speedometer", tint: .green)
            MetricCard(title: "Goal During Boost", value: analytics.averageGoalCompletion.formatted(.percent.precision(.fractionLength(0))), detail: "Average goal completion in spike windows", systemImage: "target", tint: .blue)
        }
    }

    private var spikePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Productivity Spikes")
                .font(.headline)

            if analytics.productivitySpikes.isEmpty {
                EmptyAnalysisState(title: "No boost spikes yet", message: "Boost sessions or days above 85% score will appear here.")
            } else {
                Chart(analytics.productivitySpikes) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Score", point.productivityScore))
                        .foregroundStyle(.yellow)

                    PointMark(x: .value("Date", point.date), y: .value("Score", point.productivityScore))
                        .foregroundStyle(.yellow)
                }
                .chartYScale(domain: 0...100)
                .frame(minHeight: 300)
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
