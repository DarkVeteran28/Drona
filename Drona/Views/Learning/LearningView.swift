import SwiftUI
import Charts

struct LearningView: View {
    @ObservedObject var learningTracker: LearningTracker
    var snapshot: LearningSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                gitHubPanel
                metricGrid

                HStack(alignment: .top, spacing: 20) {
                    outputEfficiencyPanel
                    recentTimelinePanel
                        .frame(width: 360)
                }
            }
            .padding(24)
        }
        .navigationTitle("Learning")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Learning Performance")
                .font(.largeTitle.weight(.semibold))

            Text("Output, consistency, and learning progression beyond screen time.")
                .foregroundStyle(.secondary)
        }
    }

    private var gitHubPanel: some View {
        HStack(spacing: 14) {
            Label("DarkVeteran28", systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)

            Text("GitHub tracking is automatic")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await learningTracker.refreshGitHub()
                }
            } label: {
                if learningTracker.isRefreshingGitHub {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .disabled(learningTracker.isRefreshingGitHub)

            Spacer()

            Text("\(learningTracker.gitHubStats.repositoryCount) repos · \(learningTracker.gitHubStats.activeRepositories.count) active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Learning Score", value: String(format: "%.0f%%", snapshot.learningScore), detail: "Output, difficulty, sessions, and consistency", systemImage: "brain.head.profile", tint: .blue)
            MetricCard(title: "Solved Today", value: "\(snapshot.leetCode.solvedToday)", detail: "Accepted LeetCode problems", systemImage: "checkmark.seal", tint: .green)
            MetricCard(title: "Session Hours", value: formatHours(snapshot.projects.totalSessionHours), detail: "Tracked learning and project work", systemImage: "folder.badge.gearshape", tint: .orange)
            MetricCard(title: "GitHub Today", value: "\(learningTracker.gitHubStats.dailyCommits)", detail: "Public commits from DarkVeteran28", systemImage: "chevron.left.forwardslash.chevron.right", tint: .purple)
        }
    }

    private var outputEfficiencyPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Output vs Time")
                .font(.headline)

            if snapshot.outputEfficiency.isEmpty {
                EmptyAnalysisState(title: "No efficiency data", message: "Daily productivity and learning outputs will correlate here once both exist.")
            } else {
                Chart(snapshot.outputEfficiency) { point in
                    BarMark(x: .value("Date", point.date), y: .value("Productive Hours", point.productiveHours))
                        .foregroundStyle(.green.opacity(0.55))

                    LineMark(x: .value("Date", point.date), y: .value("Solved", Double(point.solvedCount)))
                        .foregroundStyle(.blue)

                    PointMark(x: .value("Date", point.date), y: .value("Solved", Double(point.solvedCount)))
                        .foregroundStyle(.blue)
                }
                .frame(minHeight: 300)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recentTimelinePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Learning")
                .font(.headline)

            if snapshot.timeline.isEmpty {
                EmptyAnalysisState(title: "No learning events", message: "LeetCode refreshes, project sessions, and achievements appear here.")
            } else {
                ForEach(snapshot.timeline.prefix(6)) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: event.systemImage)
                            .foregroundStyle(color(for: event.tintName))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)

                            Text(event.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            Text(event.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func color(for name: String) -> Color {
        switch name {
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        default: return .secondary
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
