import SwiftUI
import Charts

struct ProjectsView: View {
    @ObservedObject var learningTracker: LearningTracker
    var analytics: ProjectAnalytics
    var currentProductivityScore: Double

    @State private var projectName = ""
    @State private var category: LearningCategory = .macOSDevelopment
    @State private var tagsText = ""
    @State private var durationHours = 1.0
    @State private var notes = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                HStack(alignment: .top, spacing: 20) {
                    sessionForm
                        .frame(width: 360)
                    activeProjectsPanel
                }

                categoryTrendPanel
            }
            .padding(24)
        }
        .navigationTitle("Projects")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project Tracking")
                .font(.largeTitle.weight(.semibold))

            Text("Manual development sessions tied to projects, categories, and productivity score.")
                .foregroundStyle(.secondary)
        }
    }

    private var sessionForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log Session")
                .font(.headline)

            TextField("Project name", text: $projectName)
                .textFieldStyle(.roundedBorder)

            Picker("Category", selection: $category) {
                ForEach(LearningCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(String(format: "%.1fh", durationHours))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $durationHours, in: 0.25...8, step: 0.25)
                    .tint(.blue)
            }

            TextField("Tags, comma separated", text: $tagsText)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Button {
                learningTracker.addSession(
                    projectName: projectName,
                    category: category,
                    tags: parsedTags,
                    durationHours: durationHours,
                    productivityScore: currentProductivityScore,
                    notes: notes
                )
                clearForm()
            } label: {
                Label("Save Session", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var activeProjectsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active Projects")
                    .font(.headline)
                Spacer()
                Text(formatHours(analytics.totalSessionHours))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if analytics.activeProjects.isEmpty {
                EmptyAnalysisState(title: "No project sessions", message: "Log a learning or development session to start tracking output work.")
            } else {
                ForEach(analytics.activeProjects) { project in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(project.name)
                                .font(.headline)
                            Spacer()
                            Text(formatHours(project.totalHours))
                                .font(.subheadline.monospacedDigit())
                        }

                        HStack {
                            Text("\(project.sessionCount) sessions")
                            Text("·")
                            Text(project.lastWorkedAt.formatted(.dateTime.month(.abbreviated).day()))
                            Spacer()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(project.categories.map(\.rawValue).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 8)

                    if project.id != analytics.activeProjects.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var categoryTrendPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Category Hours")
                .font(.headline)

            if analytics.categoryHours.isEmpty {
                EmptyAnalysisState(title: "No category data", message: "Session categories will show where learning time is going.")
            } else {
                Chart(analytics.categoryHours) { item in
                    BarMark(x: .value("Hours", item.hours), y: .value("Category", item.category.rawValue))
                        .foregroundStyle(.blue)
                }
                .frame(minHeight: 280)
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var parsedTags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func clearForm() {
        projectName = ""
        tagsText = ""
        notes = ""
        durationHours = 1
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
