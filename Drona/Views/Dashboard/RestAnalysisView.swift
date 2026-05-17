import SwiftUI
import Charts

struct RestAnalysisView: View {
    var analytics: RestAnalytics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                MetricCard(
                    title: "Rest Days",
                    value: "\(analytics.totalRestDays)",
                    detail: "Rest-mode days in the visible history window",
                    systemImage: "moon.zzz",
                    tint: .blue
                )

                HStack(alignment: .top, spacing: 20) {
                    classificationPanel
                    recentRestPanel
                        .frame(width: 360)
                }
            }
            .padding(24)
        }
        .navigationTitle("Rest Analysis")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rest Mode Analysis")
                .font(.largeTitle.weight(.semibold))

            Text("Rest-day classifications and recovery patterns.")
                .foregroundStyle(.secondary)
        }
    }

    private var classificationPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Classifications")
                .font(.headline)

            if analytics.classifications.isEmpty {
                EmptyAnalysisState(title: "No rest days recorded", message: "True Rest, Active Rest, and Fake Rest counts appear after rest days are saved.")
            } else {
                Chart(analytics.classifications) { item in
                    BarMark(x: .value("Type", item.classification), y: .value("Days", item.count))
                        .foregroundStyle(.blue)
                }
                .frame(minHeight: 280)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recentRestPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Rest Days")
                .font(.headline)

            if analytics.restDays.isEmpty {
                EmptyAnalysisState(title: "No rest detail", message: "Rest-day rows will show productive and distracting time balance.")
            } else {
                ForEach(analytics.restDays.suffix(8)) { day in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.date.formattedShortDay())
                                .font(.subheadline.weight(.medium))

                            Text(day.status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(String(format: "P %.1fh / D %.1fh", day.productiveHours, day.distractingHours))
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
}
