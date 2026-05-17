import SwiftUI
import Charts

struct AnalyticsView: View {
    var snapshot: AnalyticsSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summaryGrid

                HStack(alignment: .top, spacing: 20) {
                    timeBreakdownChart
                    categoryDonutPanel
                        .frame(width: 340)
                }

                HStack(alignment: .top, spacing: 20) {
                    weeklyAveragesPanel
                    appTables
                        .frame(width: 360)
                }
            }
            .padding(24)
        }
        .navigationTitle("Analytics")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Productivity Analytics")
                .font(.largeTitle.weight(.semibold))

            Text("Breakdowns, averages, and app-level performance signals.")
                .foregroundStyle(.secondary)
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Weekly Avg", value: formatHours(weeklyAverage), detail: "Productive hours per active day", systemImage: "calendar.badge.clock", tint: .green)
            MetricCard(title: "Monthly Avg", value: formatHours(monthlyAverage), detail: "Productive hours per saved month", systemImage: "calendar", tint: .blue)
            MetricCard(title: "Avg Score", value: String(format: "%.0f%%", averageScore), detail: "Across saved daily summaries", systemImage: "chart.line.uptrend.xyaxis", tint: .green)
            MetricCard(title: "Session Signal", value: formatHours(totalSessionHours), detail: "Current-day classified activity", systemImage: "timeline.selection", tint: .orange)
        }
    }

    private var timeBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Productive vs Distracting")
                .font(.headline)

            if snapshot.trends.isEmpty {
                EmptyAnalysisState(title: "No trend data", message: "Daily summaries will populate productive and distracting time bars.")
            } else {
                Chart(snapshot.trends) { point in
                    BarMark(x: .value("Date", point.date), y: .value("Productive", point.productiveHours))
                        .foregroundStyle(.green)

                    BarMark(x: .value("Date", point.date), y: .value("Distracting", point.distractingHours))
                        .foregroundStyle(.red.opacity(0.75))
                }
                .frame(minHeight: 280)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var categoryDonutPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("App Category Mix")
                .font(.headline)

            if snapshot.appBreakdown.isEmpty {
                EmptyAnalysisState(title: "No app mix yet", message: "Tracked applications will appear by productivity category.")
            } else {
                CategoryDonutView(items: snapshot.appBreakdown)
                    .frame(height: 220)

                ForEach(categoryTotals, id: \.category) { total in
                    HStack {
                        Label(total.category.label, systemImage: "circle.fill")
                            .foregroundStyle(total.category.analysisColor)

                        Spacer()

                        Text(formatHours(total.hours))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var weeklyAveragesPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Score and Goal Trend")
                .font(.headline)

            if snapshot.trends.isEmpty {
                EmptyAnalysisState(title: "No averages yet", message: "Goal and score lines appear after historical summaries exist.")
            } else {
                Chart(snapshot.trends) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Score", point.productivityScore))
                        .foregroundStyle(.green)

                    LineMark(x: .value("Date", point.date), y: .value("Goal", point.goalCompletion * 100))
                        .foregroundStyle(.blue)
                }
                .chartYScale(domain: 0...100)
                .frame(minHeight: 260)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var appTables: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Apps")
                .font(.headline)

            if snapshot.appBreakdown.isEmpty {
                EmptyAnalysisState(title: "No app records", message: "App usage rows appear as tracking data accumulates.")
            } else {
                Text("Productive")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(snapshot.appBreakdown.filter { $0.category == .productive }.prefix(4)) { item in
                    AppUsageRow(item: item)
                }

                Divider()

                Text("Distracting")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(snapshot.appBreakdown.filter { $0.category == .distracting }.prefix(4)) { item in
                    AppUsageRow(item: item)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var weeklyAverage: Double {
        average(Array(snapshot.trends.suffix(7)).map(\.productiveHours))
    }

    private var monthlyAverage: Double {
        average(snapshot.monthRankings.map(\.productiveHours))
    }

    private var averageScore: Double {
        average(snapshot.trends.map(\.productivityScore))
    }

    private var totalSessionHours: Double {
        snapshot.sessionTimeline.reduce(0) { $0 + $1.durationHours }
    }

    private var categoryTotals: [(category: ProductivityCategory, hours: Double)] {
        ProductivityCategory.allCasesForAnalysis.map { category in
            (category, snapshot.appBreakdown.filter { $0.category == category }.reduce(0) { $0 + $1.hours })
        }
    }

    private func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}

private extension ProductivityCategory {
    static var allCasesForAnalysis: [ProductivityCategory] {
        [.productive, .neutral, .distracting]
    }
}

private struct CategoryDonutView: View {
    var items: [AppBreakdownItem]

    var body: some View {
        ZStack {
            ForEach(slices) { slice in
                DonutSlice(startAngle: slice.start, endAngle: slice.end)
                    .fill(slice.category.analysisColor)
            }

            Circle()
                .fill(.background)
                .frame(width: 92, height: 92)

            VStack(spacing: 2) {
                Text("Mix")
                    .font(.headline)

                Text("Apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
    }

    private var slices: [CategorySlice] {
        let totals = ProductivityCategory.allCasesForAnalysis.map { category in
            (category, items.filter { $0.category == category }.reduce(0) { $0 + $1.hours })
        }
        let totalHours = max(totals.reduce(0) { $0 + $1.1 }, 0.01)
        var cursor = -90.0

        return totals.map { category, hours in
            let span = (hours / totalHours) * 360
            let slice = CategorySlice(category: category, start: .degrees(cursor), end: .degrees(cursor + span))
            cursor += span
            return slice
        }
    }
}

private struct CategorySlice: Identifiable {
    let id = UUID()
    var category: ProductivityCategory
    var start: Angle
    var end: Angle
}

private struct DonutSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.58
        var path = Path()

        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}
