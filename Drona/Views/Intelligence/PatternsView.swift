import SwiftUI
import Charts

struct PatternsView: View {
    var behavior: BehaviorSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                patternGrid
                dayPatternPanel
            }
            .padding(24)
        }
        .navigationTitle("Patterns")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Behavior Patterns")
                .font(.largeTitle.weight(.semibold))

            Text("Recurring productivity, distraction, recovery, and output signals.")
                .foregroundStyle(.secondary)
        }
    }

    private var patternGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            ForEach(behavior.patterns) { pattern in
                VStack(alignment: .leading, spacing: 12) {
                    Label(pattern.category.rawValue, systemImage: icon(for: pattern.category))
                        .font(.caption)
                        .foregroundStyle(color(for: pattern.category))

                    Text(pattern.value)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(pattern.title)
                        .font(.headline)

                    Text(pattern.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var dayPatternPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Focus Session Distribution")
                .font(.headline)

            Chart(behavior.focusDistribution) { bucket in
                BarMark(x: .value("Bucket", bucket.label), y: .value("Days", bucket.sessionCount))
                    .foregroundStyle(.blue.opacity(0.7))

                PointMark(x: .value("Bucket", bucket.label), y: .value("Score", bucket.averageScore / 10))
                    .foregroundStyle(.green)
            }
            .frame(minHeight: 280)
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func icon(for category: InsightCategory) -> String {
        switch category {
        case .productivity: return "target"
        case .distraction: return "exclamationmark.triangle"
        case .recovery: return "moon"
        case .boost: return "bolt"
        case .consistency: return "chart.line.flattrend.xyaxis"
        case .efficiency: return "speedometer"
        case .trend: return "arrow.up.right"
        }
    }

    private func color(for category: InsightCategory) -> Color {
        switch category {
        case .productivity, .efficiency: return .green
        case .distraction: return .red
        case .recovery, .trend: return .blue
        case .boost: return .orange
        case .consistency: return .purple
        }
    }
}
