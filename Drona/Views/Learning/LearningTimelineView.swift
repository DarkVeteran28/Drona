import SwiftUI

struct LearningTimelineView: View {
    var events: [LearningTimelineEvent]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                timelinePanel
            }
            .padding(24)
        }
        .navigationTitle("Learning Timeline")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Learning Timeline")
                .font(.largeTitle.weight(.semibold))

            Text("A chronological record of solved problems, project sessions, and milestones.")
                .foregroundStyle(.secondary)
        }
    }

    private var timelinePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if events.isEmpty {
                EmptyAnalysisState(title: "No learning history yet", message: "Refresh integrations or log project sessions to build the timeline.")
            } else {
                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            Image(systemName: event.systemImage)
                                .foregroundStyle(color(for: event.tintName))
                                .frame(width: 28, height: 28)
                                .background(.background, in: Circle())

                            Rectangle()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(width: 1, height: 54)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(event.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Spacer()

                                Text(event.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            Text(event.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.bottom, 18)
                    }
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
}
