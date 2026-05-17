import SwiftUI
import Charts

struct ViolationsView: View {
    var analytics: ViolationAnalytics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                MetricCard(
                    title: "Distraction Attempts",
                    value: "\(analytics.totalAttempts)",
                    detail: "Total blocked or logged attempts",
                    systemImage: "hand.raised",
                    tint: .red
                )

                HStack(alignment: .top, spacing: 20) {
                    frequencyPanel
                    mostAttemptedPanel
                        .frame(width: 360)
                }
            }
            .padding(24)
        }
        .navigationTitle("Violations")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Violation Analysis")
                .font(.largeTitle.weight(.semibold))

            Text("Behavioral weak points and repeated distraction attempts.")
                .foregroundStyle(.secondary)
        }
    }

    private var frequencyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Frequency Trend")
                .font(.headline)

            if analytics.frequency.isEmpty {
                EmptyAnalysisState(title: "No violations logged", message: "Attempt frequency appears once blocked apps or sites are logged.")
            } else {
                Chart(analytics.frequency) { point in
                    BarMark(x: .value("Date", point.date), y: .value("Attempts", point.violations))
                        .foregroundStyle(.red.opacity(0.75))
                }
                .frame(minHeight: 280)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var mostAttemptedPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Most Attempted")
                .font(.headline)

            if analytics.mostAttempted.isEmpty {
                EmptyAnalysisState(title: "No targets yet", message: "Blocked targets will be ranked here by attempt count.")
            } else {
                ForEach(analytics.mostAttempted) { target in
                    HStack {
                        Text(target.name)
                            .lineLimit(1)

                        Spacer()

                        Text("\(target.attempts)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
