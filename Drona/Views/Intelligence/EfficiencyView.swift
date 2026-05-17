import SwiftUI
import Charts

struct EfficiencyView: View {
    var behavior: BehaviorSnapshot
    var learning: LearningSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricGrid
                efficiencyChart
            }
            .padding(24)
        }
        .navigationTitle("Efficiency")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Efficiency Analysis")
                .font(.largeTitle.weight(.semibold))

            Text("Correlates productive hours with actual learning and development output.")
                .foregroundStyle(.secondary)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Output Density", value: String(format: "%.2f/hr", behavior.efficiency.outputPerHour), detail: "Problems solved per productive/session hour", systemImage: "speedometer", tint: .green)
            MetricCard(title: "Best Day", value: bestDayText, detail: "Highest measured output density", systemImage: "star", tint: .orange)
            MetricCard(title: "Short Session Edge", value: String(format: "%.2f", behavior.efficiency.shortSessionAdvantage), detail: "Positive means shorter blocks are denser", systemImage: "timer", tint: .blue)
            MetricCard(title: "Interpretation", value: "Signal", detail: behavior.efficiency.interpretation, systemImage: "chart.xyaxis.line", tint: .purple)
        }
    }

    private var efficiencyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Output vs Productive Time")
                .font(.headline)

            if learning.outputEfficiency.isEmpty {
                EmptyAnalysisState(title: "No output correlation yet", message: "LeetCode records and productivity history are needed to compute efficiency patterns.")
            } else {
                Chart(learning.outputEfficiency) { point in
                    BarMark(x: .value("Date", point.date), y: .value("Productive Hours", point.productiveHours + point.sessionHours))
                        .foregroundStyle(.green.opacity(0.45))

                    LineMark(x: .value("Date", point.date), y: .value("Output per Hour", point.outputPerHour))
                        .foregroundStyle(.blue)

                    PointMark(x: .value("Date", point.date), y: .value("Solved", Double(point.solvedCount)))
                        .foregroundStyle(.orange)
                }
                .frame(minHeight: 320)
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var bestDayText: String {
        guard let date = behavior.efficiency.bestEfficiencyDay else {
            return "Needs data"
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
