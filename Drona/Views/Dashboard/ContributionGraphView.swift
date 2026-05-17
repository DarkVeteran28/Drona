import SwiftUI

struct ContributionGraphView: View {
    var days: [ContributionDay]

    @State private var visibleMonth = Date()
    @State private var selectedDay: ContributionDay?
    @State private var hoveredDay: ContributionDay?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = Array(repeating: GridItem(.fixed(26), spacing: 7), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                monthControls

                HStack(alignment: .top, spacing: 24) {
                    heatmap
                    detailPanel
                        .frame(width: 300)
                }

                legend
            }
            .padding(24)
        }
        .navigationTitle("Contribution Graph")
        .animation(UXRefinementManager.shared.animation(reduceMotion: reduceMotion), value: visibleMonth)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Productivity Heatmap")
                .font(.largeTitle.weight(.semibold))

            Text("Day-by-day intensity, rest days, and historical productivity details.")
                .foregroundStyle(.secondary)
        }
    }

    private var monthControls: some View {
        HStack(spacing: 12) {
            Button {
                moveMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .help("Previous month")

            Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title3.weight(.semibold))
                .frame(minWidth: 180)

            Button {
                moveMonth(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .help("Next month")

            Spacer()

            Button {
                visibleMonth = Date()
                selectedDay = dayFor(Date())
            } label: {
                Label("Today", systemImage: "calendar")
            }
            .help("Jump to current month")
        }
    }

    private var heatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            weekdayHeader

            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(monthCells) { cell in
                    if let day = cell.day {
                        Button {
                            selectedDay = day
                        } label: {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(day.heatmapColor)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(borderColor(for: day), lineWidth: selectedDay?.id == day.id ? 2 : 0.75)
                                }
                                .frame(width: 26, height: 26)
                                .scaleEffect(hoveredDay?.id == day.id ? 1.12 : 1)
                                .animation(UXRefinementManager.shared.animation(reduceMotion: reduceMotion), value: hoveredDay?.id)
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            hoveredDay = isHovering ? day : nil
                        }
                        .help(helpText(for: day))
                    } else {
                        Color.clear
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .padding(18)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 7) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 26)
            }
        }
        .padding(.horizontal, 18)
    }

    private var detailPanel: some View {
        let day = hoveredDay ?? selectedDay ?? dayFor(Date())

        return VStack(alignment: .leading, spacing: 18) {
            Text("Day Detail")
                .font(.headline)

            if let day {
                Text(day.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                detailRow("Productive", value: formatHours(day.productiveHours), color: .green)
                detailRow("Distracting", value: formatHours(day.distractingHours), color: .red)
                detailRow("Violations", value: "\(day.violations)", color: .orange)
                detailRow("Status", value: day.status, color: day.isRestDay ? .blue : .secondary)
            } else {
                EmptyAnalysisState(
                    title: "No day selected",
                    message: "Click a square to inspect its productivity record."
                )
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem("Empty", color: Color.secondary.opacity(0.12))
            legendItem("Low", color: .green.opacity(0.35))
            legendItem("Moderate", color: .green.opacity(0.62))
            legendItem("Deep Work", color: .green.opacity(0.9))
            legendItem("Rest Day", color: .blue)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var monthCells: [ContributionMonthCell] {
        guard let interval = calendar.dateInterval(of: .month, for: visibleMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: visibleMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start) - 1
        let blanks = Array(repeating: ContributionMonthCell(day: nil), count: firstWeekday)
        let realDays = dayRange.compactMap { dayNumber -> ContributionMonthCell? in
            guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: interval.start) else {
                return nil
            }

            return ContributionMonthCell(day: dayFor(date) ?? emptyDay(for: date))
        }

        return blanks + realDays
    }

    private func detailRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Label(label, systemImage: "circle.fill")
                .foregroundStyle(color)

            Spacer()

            Text(value)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .font(.subheadline)
    }

    private func legendItem(_ title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 16, height: 16)

            Text(title)
        }
    }

    private func moveMonth(_ amount: Int) {
        visibleMonth = calendar.date(byAdding: .month, value: amount, to: visibleMonth) ?? visibleMonth
        selectedDay = nil
    }

    private func dayFor(_ date: Date) -> ContributionDay? {
        let start = calendar.startOfDay(for: date)
        return days.first { calendar.isDate($0.date, inSameDayAs: start) }
    }

    private func emptyDay(for date: Date) -> ContributionDay {
        ContributionDay(
            date: date,
            productiveHours: 0,
            distractingHours: 0,
            violations: 0,
            status: "No Work",
            isRestDay: false
        )
    }

    private func borderColor(for day: ContributionDay) -> Color {
        if selectedDay?.id == day.id {
            return .primary
        }

        return day.intensity == 0 ? .secondary.opacity(0.16) : .clear
    }

    private func helpText(for day: ContributionDay) -> String {
        "\(day.date.formattedShortDay()): \(formatHours(day.productiveHours)) productive"
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}

private struct ContributionMonthCell: Identifiable {
    let id = UUID()
    var day: ContributionDay?
}
